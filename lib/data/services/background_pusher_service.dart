import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';

/// Service to handle Pusher events in background with notifications
class BackgroundPusherService {
  static final BackgroundPusherService _instance = BackgroundPusherService._internal();
  factory BackgroundPusherService() => _instance;
  BackgroundPusherService._internal();

  static const String _portName = 'pusher_background_port';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  ReceivePort? _receivePort;
  bool _isInitialized = false;

  // Notification channel IDs
  static const String _driverAssignedChannelId = 'driver_assigned_channel';
  static const String _rideStatusChannelId = 'ride_status_channel';
  static const String _bidChannelId = 'bid_channel';
  static const String _paymentChannelId = 'payment_channel';
  static const String _criticalChannelId = 'critical_channel';
  static const String _generalChannelId = 'general_channel';

  /// Initialize background service
  Future<void> initialize() async {
    if (_isInitialized) return;

    printX('🚀 Initializing BackgroundPusherService for Rider');

    // Initialize notifications
    await _initializeNotifications();

    // Initialize background isolate for Pusher
    await _initializeBackgroundIsolate();

    // Listen to Pusher events
    PusherManager().addListener(_handlePusherEvent);

    _isInitialized = true;
    printX('✅ BackgroundPusherService initialized for Rider');
  }

  /// Initialize notification channels and settings
  Future<void> _initializeNotifications() async {
    // Android notification channels
    const androidChannels = [
      AndroidNotificationChannel(
        _driverAssignedChannelId,
        'Driver Assigned',
        description: 'Notifications when a driver is assigned to your ride',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
      AndroidNotificationChannel(
        _rideStatusChannelId,
        'Ride Status Updates',
        description: 'Updates about your ride status',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        _bidChannelId,
        'Driver Bids',
        description: 'Notifications when drivers bid on your ride',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        _paymentChannelId,
        'Payment Notifications',
        description: 'Payment related notifications',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        _criticalChannelId,
        'Critical Alerts',
        description: 'Important ride alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
      AndroidNotificationChannel(
        _generalChannelId,
        'General Notifications',
        description: 'General ride notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    // Create channels
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in androidChannels) {
        await androidPlugin.createNotificationChannel(channel);
      }

      // Request notification permissions for Android 13+
      await androidPlugin.requestNotificationsPermission();
    }

    // Initialize settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize background isolate for persistent Pusher connection
  Future<void> _initializeBackgroundIsolate() async {
    _receivePort = ReceivePort();

    // Register port for inter-isolate communication
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _portName,
    );

    // Listen to messages from background isolate
    _receivePort!.listen((dynamic data) {
      if (data is Map<String, dynamic>) {
        _processBackgroundEvent(data);
      }
    });
  }

  /// Handle Pusher events (called from main isolate)
  void _handlePusherEvent(PusherEvent event) {
    try {
      final eventName = event.eventName.toLowerCase();
      printX('📩 BackgroundPusher Rider: $eventName');

      // Ignore pusher internal events
      if (eventName.startsWith('pusher:')) {
        return;
      }

      // Parse event data
      Map<String, dynamic> data = {};
      if (event.data != null) {
        if (event.data is String) {
          data = jsonDecode(event.data);
        } else if (event.data is Map) {
          data = Map<String, dynamic>.from(event.data);
        }
      }

      final model = PusherResponseModel.fromJson(data);

      // Determine app lifecycle state
      final appState = WidgetsBinding.instance.lifecycleState;
      final isBackground = appState == null || appState != AppLifecycleState.resumed;

      // Always show system notification for all events
      // This ensures the rider sees notifications whether app is foreground or background
      printX('📱 App state: $appState (isBackground: $isBackground) — showing notification');
      _showNotificationForEvent(eventName, model);

      // Handle critical events that need immediate attention (bring app to foreground)
      if (isBackground && _isCriticalEvent(eventName)) {
        _handleCriticalEvent(eventName, model);
      }
    } catch (e) {
      printE('Error handling Pusher event: $e');
    }
  }

  /// Process events from background isolate
  void _processBackgroundEvent(Map<String, dynamic> data) {
    final eventName = data['event'] as String?;
    final eventData = data['data'] as Map<String, dynamic>?;

    if (eventName != null && eventData != null) {
      final model = PusherResponseModel.fromJson(eventData);
      _showNotificationForEvent(eventName, model);
    }
  }

  /// Show notification based on event type
  Future<void> _showNotificationForEvent(
    String eventName,
    PusherResponseModel model,
  ) async {
    String title = '';
    String body = '';
    String channelId = _generalChannelId;
    NotificationDetails? details;
    String? payload;

    switch (eventName) {
      case 'new_ride_created':
        final ride = model.data?.ride;
        title = '🚗 Ride Created!';
        if (ride != null) {
          body = 'Your ride request has been created\n'
              'From: ${ride.pickupLocation ?? "Pickup"}\n'
              'To: ${ride.destination ?? "Destination"}';
          channelId = _rideStatusChannelId;
          payload = jsonEncode({
            'event': 'new_ride_created',
            'ride_id': ride.id,
          });
        } else {
          body = 'Your ride request has been created.';
          channelId = _rideStatusChannelId;
        }
        break;

      case 'driver_searching':
        final notifiedCount = model.data?.notifiedCount ?? 0;
        final rejectedCount = model.data?.rejectedCount ?? 0;
        title = '🔍 Driver Search Update';
        if (notifiedCount > 0) {
          body = '$notifiedCount driver${notifiedCount > 1 ? 's are' : ' is'} being contacted for your ride';
          if (rejectedCount > 0) {
            body += '\n$rejectedCount driver${rejectedCount > 1 ? 's' : ''} unavailable';
          }
        } else {
          body = 'Searching for available drivers in your area...';
        }
        channelId = _driverAssignedChannelId;
        payload = jsonEncode({
          'event': 'driver_searching',
          'ride_id': model.data?.ride?.id,
        });

        // High priority notification
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Driver Assigned',
            channelDescription: 'Driver assignment notifications',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
            autoCancel: false,
            ongoing: true,
            actions: [
              AndroidNotificationAction(
                'view',
                'View Details',
                titleColor: Colors.blue,
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'contact',
                'Contact Driver',
                titleColor: Colors.green,
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        );
        break;

      case 'new_bid':
        final bid = model.data?.bid;
        title = '💰 New Bid Received!';
        if (bid != null) {
          body = 'Driver bid: ${StringConverter.formatNumber(bid.bidAmount ?? '0')}\n'
              'Tap to view and accept';
          payload = jsonEncode({
            'event': 'new_bid',
            'ride_id': bid.rideId,
          });
        } else {
          body = 'A driver has placed a bid on your ride. Tap to view.';
        }
        channelId = _bidChannelId;
        break;

      case 'bid_accept':
        final ride = model.data?.ride;
        title = '✅ Ride Confirmed!';
        if (ride != null) {
          body = 'Driver has accepted your ride\n'
              'They are on their way';
          payload = jsonEncode({
            'event': 'bid_accept',
            'ride_id': ride.id,
          });
        } else {
          body = 'A driver has accepted your ride!';
        }
        channelId = _driverAssignedChannelId;
        break;

      case 'pick_up':
        final ride = model.data?.ride;
        title = '🎯 Driver Arrived!';
        if (ride != null) {
          body = 'Your driver has arrived at the pickup location\n'
              'Please board the vehicle';
          payload = jsonEncode({
            'event': 'pick_up',
            'ride_id': ride.id,
          });
        } else {
          body = 'Your driver has arrived. Please board the vehicle.';
        }
        channelId = _criticalChannelId;
        break;

      case 'ride_end':
        final ride = model.data?.ride;
        title = '🏁 Ride Completed!';
        if (ride != null) {
          body = 'Your ride has been completed\n'
              'Please rate your experience';
          payload = jsonEncode({
            'event': 'ride_end',
            'ride_id': ride.id,
          });
        } else {
          body = 'Your ride has been completed. Please rate your experience.';
        }
        channelId = _rideStatusChannelId;
        break;

      case 'ride_canceled':
        final canceledBy = model.data?.canceledBy ?? 'unknown';
        final reason = model.data?.cancelReason ?? 'No reason provided';
        title = '🚫 Ride Canceled';
        body = 'Ride canceled by $canceledBy\nReason: $reason';
        channelId = _criticalChannelId;
        break;

      case 'cash_payment_received':
        title = '✅ Payment Received';
        body = 'Driver has confirmed cash payment';
        channelId = _paymentChannelId;
        break;

      case 'message_received':
        final message = model.data?.message;
        title = '💬 New Message';
        if (message != null) {
          body = message.message ?? 'You have a new message';
        } else {
          body = 'You have a new message from your driver.';
        }
        channelId = _generalChannelId;
        break;

      default:
        return; // Don't show notification for unknown events
    }

    // Show the notification
    if (title.isNotEmpty && body.isNotEmpty) {
      await _showNotification(
        title: title,
        body: body,
        channelId: channelId,
        details: details,
        payload: payload,
      );
    }
  }

  /// Show a notification
  Future<void> _showNotification({
    required String title,
    required String body,
    required String channelId,
    NotificationDetails? details,
    String? payload,
  }) async {
    details ??= NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Ride Notifications',
        channelDescription: 'Notifications for ride events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Check if event is critical and needs immediate attention
  bool _isCriticalEvent(String eventName) {
    return [
      'driver_searching',
      'bid_accept',
      'pick_up',
    ].contains(eventName);
  }

  /// Handle critical events with call-like UI
  Future<void> _handleCriticalEvent(
    String eventName,
    PusherResponseModel model,
  ) async {
    final appState = WidgetsBinding.instance.lifecycleState;

    // Only show call screen if app is in background/inactive
    if (appState != AppLifecycleState.resumed) {
      if (eventName == 'driver_searching' || eventName == 'bid_accept') {
        await _showDriverAssignedScreen(model.data?.ride);
      } else if (eventName == 'pick_up') {
        await _showDriverArrivedScreen(model.data?.ride);
      }
    }
  }

  /// Show driver assigned screen (like WhatsApp call)
  Future<void> _showDriverAssignedScreen(dynamic ride) async {
    if (ride == null) return;

    Get.toNamed(
      RouteHelper.driverAssignedScreen,
      arguments: ride,
    );
  }

  /// Show driver arrived screen
  Future<void> _showDriverArrivedScreen(dynamic ride) async {
    if (ride == null) return;

    Get.toNamed(
      RouteHelper.driverArrivedScreen,
      arguments: ride,
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // final event = data['event'] as String?;  // Currently unused
        final rideId = data['ride_id'] as String?;

        if (rideId != null) {
          // Navigate based on event type
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
      } catch (e) {
        printE('Error handling notification tap: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    PusherManager().removeListener(_handlePusherEvent);
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    _isInitialized = false;
  }
}

/// Background isolate entry point for persistent Pusher connection
@pragma('vm:entry-point')
void backgroundPusherIsolate() async {
  printX('🎯 Background Pusher Isolate started for Rider');

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Get shared preferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString(SharedPreferenceHelper.userIdKey) ?? '';

  if (userId.isEmpty) {
    printX('⚠️ No user ID, exiting background isolate');
    return;
  }

  // Initialize Pusher in background
  final pusher = PusherChannelsFlutter.getInstance();

  try {
    // Get Pusher config from storage
    final pusherConfigJson = prefs.getString(
      SharedPreferenceHelper.pusherConfigSettingKey,
    );

    if (pusherConfigJson != null) {
      final config = jsonDecode(pusherConfigJson);
      final apiKey = config['app_key'];
      final cluster = config['cluster'];

      if (apiKey != null && cluster != null) {
        // Initialize Pusher
        await pusher.init(
          apiKey: apiKey,
          cluster: cluster,
          onEvent: (event) {
            // Send event to main isolate
            final sendPort = IsolateNameServer.lookupPortByName(
              BackgroundPusherService._portName,
            );

            if (sendPort != null) {
              sendPort.send({
                'event': event.eventName,
                'data': event.data is String ? jsonDecode(event.data) : event.data,
              });
            }
          },
        );

        // Connect and subscribe
        await pusher.connect();
        await pusher.subscribe(
          channelName: 'private-rider-user-$userId',
        );

        printX('✅ Background Pusher connected for rider');

        // Keep isolate alive
        while (true) {
          await Future.delayed(const Duration(seconds: 30));

          // Check if still connected
          if (pusher.connectionState.toLowerCase() != 'connected') {
            printX('⚠️ Pusher disconnected, reconnecting...');
            await pusher.connect();
          }
        }
      }
    }
  } catch (e) {
    printE('Error in background Pusher isolate: $e');
  }
}
