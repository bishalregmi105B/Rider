import 'dart:io';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherManager {
  static final PusherManager _instance = PusherManager._internal();
  factory PusherManager() => _instance;
  PusherManager._internal();

  final ApiClient apiClient = ApiClient(sharedPreferences: Get.find());
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final List<void Function(PusherEvent)> _listeners = [];

  bool _isConnecting = false;
  String _channelName = "";

  Future<void> init(String channelName) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _channelName = channelName;

    final apiKey = apiClient.getPushConfig().appKey ?? "";
    final cluster = apiClient.getPushConfig().cluster ?? "";

    // iOS-specific debug logging
    final platform = Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Unknown");
    printX("📱 Platform: $platform");
    printX("🔑 Pusher Init: apiKey=${apiKey.isNotEmpty ? '${apiKey.substring(0, 4)}...' : 'EMPTY'}, cluster=$cluster, channel=$channelName");

    if (apiKey.isEmpty || cluster.isEmpty) {
      printE("❌ PUSHER CONFIG MISSING! apiKey: ${apiKey.isEmpty ? 'EMPTY' : 'OK'}, cluster: ${cluster.isEmpty ? 'EMPTY' : 'OK'}");
      _isConnecting = false;
      return;
    }

    await _disconnect();

    await pusher.init(
      apiKey: apiKey,
      cluster: cluster,
      onConnectionStateChange: _onConnectionStateChange,
      onEvent: _dispatchEvent,
      onError: (msg, code, e) {
        printE("❌ Pusher Error [$platform]: $msg (code: $code)");
        if (Platform.isIOS) {
          printE("🍎 iOS Error Details: $e");
        }
      },
      onSubscriptionError: (msg, e) {
        printE("⚠️ Sub Error [$platform]: $msg");
        if (Platform.isIOS) {
          printE("🍎 iOS Subscription Error: $e");
        }
      },
      onSubscriptionSucceeded: (channel, data) => printX("✅ Subscribed [$platform]: $channel"),
      onAuthorizer: onAuthorizer,
      onDecryptionFailure: (_, __) {},
      onMemberAdded: (_, __) {},
      onMemberRemoved: (_, __) {},
    );

    await _connect(channelName);
    _isConnecting = false;
  }

  Future<void> _connect(String channelName) async {
    if (isConnected()) {
      await _subscribe(channelName);
      return;
    }

    for (int i = 0; i < 3; i++) {
      try {
        printX("🔌 Connecting... (${i + 1}/3)");
        await pusher.connect();
        await Future.delayed(const Duration(seconds: 2));

        if (isConnected()) {
          printX("✅ Connected");
          await _subscribe(channelName);
          return;
        }
      } catch (e) {
        printE("⚠️ Connect failed: $e");
        if (i < 2) await Future.delayed(const Duration(seconds: 3));
      }
    }
    printE("❌ Connection failed");
  }

  Future<void> _subscribe(String channelName) async {
    if (pusher.getChannel(channelName) != null) {
      printX("✅ Already subscribed");
      return;
    }
    try {
      await pusher.subscribe(channelName: channelName);
    } catch (e) {
      printE("⚠️ Subscribe error: $e");
    }
  }

  Future<void> _disconnect() async {
    try {
      if (pusher.connectionState.toLowerCase() != 'disconnected') {
        await pusher.disconnect();
      }
    } catch (_) {}
  }

  void _onConnectionStateChange(String current, String previous) {
    final platform = Platform.isIOS ? "iOS" : "Android";
    printX("🔁 [$platform] State: $previous → $current");

    // iOS-specific: Log additional connection states for debugging
    if (Platform.isIOS && current.toLowerCase() == 'disconnected') {
      printE("🍎 iOS Disconnected - Common causes: App backgrounded, Network change, Server timeout");
    }

    if (current.toLowerCase() == 'disconnected' && previous.toLowerCase() == 'connected' && !_isConnecting) {
      printX("⏳ [$platform] Will attempt reconnect in 3 seconds...");
      Future.delayed(const Duration(seconds: 3), () {
        if (!isConnected() && !_isConnecting) {
          printX("🔄 [$platform] Attempting auto-reconnect...");
          _connect(_channelName);
        }
      });
    }
  }

  void _dispatchEvent(PusherEvent event) {
    for (var listener in _listeners) {
      listener(event);
    }
  }

  void addListener(void Function(PusherEvent) listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(void Function(PusherEvent) listener) {
    _listeners.remove(listener);
  }

  bool isConnected() => pusher.connectionState.toLowerCase() == 'connected';

  Future<void> checkAndInitIfNeeded(String channelName) async {
    if (_isConnecting) return;

    if (!isConnected()) {
      await init(channelName);
    } else if (pusher.getChannel(channelName) == null) {
      await _subscribe(channelName);
    }
  }

  Future<Map<String, dynamic>?> onAuthorizer(String channelName, String socketId, options) async {
    final platform = Platform.isIOS ? "iOS" : "Android";
    printX("🔐 [$platform] Authorizing: channel=$channelName, socketId=$socketId");

    try {
      String authUrl = "${UrlContainer.baseUrl}${UrlContainer.pusherAuthenticate}$socketId/$channelName";
      printX("🔗 [$platform] Auth URL: $authUrl");

      ResponseModel response = await apiClient.request(authUrl, Method.postMethod, null, passHeader: true);

      printX("📨 [$platform] Auth Response: statusCode=${response.statusCode}");

      if (response.statusCode == 200) {
        printX("✅ [$platform] Auth Success!");
        return response.responseJson;
      } else {
        printE("❌ [$platform] Auth Failed: ${response.statusCode} - ${response.responseJson}");
      }
    } catch (e) {
      printE("❌ [$platform] Auth Exception: $e");
      if (Platform.isIOS) {
        printE("🍎 iOS Auth Error - Check: 1) SSL/TLS settings, 2) ATS config in Info.plist, 3) Network permissions");
      }
    }
    return null;
  }
}
