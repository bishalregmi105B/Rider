import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/audio_utils.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/data/services/pusher_service.dart';
import 'package:ovorideuser/presentation/components/dialog/show_custom_bid_dialog.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class PusherRideController extends GetxController {
  ApiClient apiClient;
  RideMessageController rideMessageController;
  RideDetailsController rideDetailsController;
  String rideID;
  PusherRideController({required this.apiClient, required this.rideMessageController, required this.rideDetailsController, required this.rideID});

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
    ensureConnection();
  }

  PusherConfig pusherConfig = PusherConfig();

  /// Handle incoming Pusher events
  void onEvent(PusherEvent event) {
    try {
      printX('📡 PUSHER EVENT RECEIVED:');
      printX('  Channel: ${event.channelName}');
      printX('  Event: ${event.eventName}');
      printX('  Has Data: ${event.data != null}');

      if (event.data == null) {
        printX('  ❌ No data in event');
        return;
      }

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(event.data);
        printX('  ✅ JSON parsed successfully');
      } catch (e) {
        printX('  ❌ Invalid JSON: $e');
        printX('  Raw data: ${event.data}');
        return;
      }

      final model = PusherResponseModel.fromJson(data);
      final modifiedEvent = PusherResponseModel(eventName: event.eventName, channelName: event.channelName, data: model.data);

      updateEvent(modifiedEvent);
    } catch (e) {
      printX('❌ onEvent error: $e');
    }
  }

  /// Update UI or state based on event name
  void updateEvent(PusherResponseModel event) {
    final eventName = event.eventName?.toLowerCase();
    printX('Handling event: $eventName');

    switch (eventName) {
      case 'online_payment_received':
        _handleOnlinePayment(event);
        break;

      case 'message_received':
        _handleMessageReceived(event);
        break;

      case 'live_location':
        _handleLiveLocation(event);
        break;

      case 'new_bid':
        _handleNewBid(event);
        break;

      case 'bid_reject':
        rideDetailsController.updateBidCount(true);
        break;

      case 'cash_payment_received':
        _handleCashPayment(event);
        break;

      case 'pick_up':
      case 'ride_end':
        _updateRideIfAvailable(event);
        break;

      case 'bid_accept':
        _handleBidAccept(event);
        break;

      case 'package_ride_accepted':
        _handlePackageRideAccepted(event);
        break;

      case 'driver_searching':
        _handleDriverSearching(event);
        break;

      case 'ride_canceled':
        _handleRideCanceled(event);
        break;

      default:
        _updateRideIfAvailable(event);
        break;
    }
  }

  /// Handlers for each event type

  void _handleOnlinePayment(PusherResponseModel event) {
    printX('Online payment received for ride: ${event.data?.rideId}');
    Get.offAndToNamed(RouteHelper.rideReviewScreen, arguments: event.data?.rideId ?? '');
  }

  void _handleMessageReceived(PusherResponseModel enventResponse) {
    if (enventResponse.data?.message != null) {
      if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
        printX('Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
        return;
      }
      if (isRideDetailsPage()) {
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
      }

      rideMessageController.addEventMessage(enventResponse.data!.message!);
    }
  }

  void _handleLiveLocation(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    if (rideDetailsController.ride.status == AppStatus.RIDE_ACTIVE.toString() || rideDetailsController.ride.status == AppStatus.RIDE_RUNNING.toString()) {
      final lat = StringConverter.formatDouble(enventResponse.data?.driverLatitude ?? '0', precision: 10);
      final lng = StringConverter.formatDouble(enventResponse.data?.driverLongitude ?? '0', precision: 10);
      printX('📍 Live location update: ($lat, $lng)');
      rideDetailsController.mapController.updateDriverLocation(latLng: LatLng(lat, lng), isRunning: rideDetailsController.ride.status == AppStatus.RIDE_RUNNING.toString());
    }
  }

  void _handleBidAccept(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Bid accept for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // Clear searching driver marker as a driver has been assigned
    rideDetailsController.mapController.clearSearchingDriverMarker();

    // Update the ride data first
    final ride = enventResponse.data?.ride;
    if (ride != null) {
      rideDetailsController.updateRide(ride);

      // Update driver info for marker
      if (ride.driver != null) {
        rideDetailsController.mapController.updateDriverInfo(firstName: ride.driver?.firstname, lastName: ride.driver?.lastname, vehicleModel: ride.driver?.vehicleData?.model?.name, vehicleColor: ride.driver?.vehicleData?.color?.name, vehicleNumber: ride.driver?.vehicleData?.vehicleNumber);
      }

      // Enable driver route tracking when driver is assigned
      rideDetailsController.mapController.enableDriverRouteTracking();

      // Initialize driver marker with initial location
      final lat = StringConverter.formatDouble(enventResponse.data?.driverLatitude ?? '0', precision: 10);
      final lng = StringConverter.formatDouble(enventResponse.data?.driverLongitude ?? '0', precision: 10);

      if (lat != 0.0 && lng != 0.0) {
        printX('🚗 Bid accepted! Initializing driver marker at ($lat, $lng)');

        final driverLatLng = LatLng(lat, lng);
        rideDetailsController.mapController.updateDriverLocation(latLng: driverLatLng, isRunning: false);

        // Calculate initial ETA manually as fallback
        // This will be replaced by API-based ETA when route is calculated
        final pickupLatLng = rideDetailsController.pickupLatLng;
        if (pickupLatLng.latitude != 0 && pickupLatLng.longitude != 0) {
          rideDetailsController.mapController.calculateETAManually(driverLocation: driverLatLng, pickupLocation: pickupLatLng);

          // Show ETA notification to rider
          final eta = rideDetailsController.mapController.driverETA;
          final distance = rideDetailsController.mapController.driverDistance;
          if (eta.isNotEmpty) {
            Get.snackbar('✅ Driver Assigned!', 'Your driver is on the way\nETA: $eta${distance.isNotEmpty ? " • Distance: $distance" : ""}', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 5), backgroundColor: Get.theme.colorScheme.primaryContainer, colorText: Get.theme.colorScheme.onPrimaryContainer);
          }
        }
      } else {
        printX('⚠️ Bid accepted but driver location not available');
      }
    }
  }

  void _handlePackageRideAccepted(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Package ride accept for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // Clear searching driver marker as driver has been assigned
    rideDetailsController.mapController.clearSearchingDriverMarker();

    // Update the ride data first
    final ride = enventResponse.data?.ride;
    if (ride != null) {
      printX('📦 Package ride accepted by driver!');
      rideDetailsController.updateRide(ride);

      // Update driver info for marker
      if (ride.driver != null) {
        rideDetailsController.mapController.updateDriverInfo(firstName: ride.driver?.firstname, lastName: ride.driver?.lastname, vehicleModel: ride.driver?.vehicleData?.model?.name, vehicleColor: ride.driver?.vehicleData?.color?.name, vehicleNumber: ride.driver?.vehicleData?.vehicleNumber);
      }

      // Enable driver route tracking when driver is assigned
      rideDetailsController.mapController.enableDriverRouteTracking();

      // Initialize driver marker with initial location
      final lat = StringConverter.formatDouble(enventResponse.data?.driverLatitude ?? '0', precision: 10);
      final lng = StringConverter.formatDouble(enventResponse.data?.driverLongitude ?? '0', precision: 10);

      if (lat != 0.0 && lng != 0.0) {
        printX('🚗 Package ride accepted! Initializing driver marker at ($lat, $lng)');

        final driverLatLng = LatLng(lat, lng);
        rideDetailsController.mapController.updateDriverLocation(latLng: driverLatLng, isRunning: false);

        // Calculate initial ETA manually as fallback
        final pickupLatLng = rideDetailsController.pickupLatLng;
        if (pickupLatLng.latitude != 0 && pickupLatLng.longitude != 0) {
          rideDetailsController.mapController.calculateETAManually(driverLocation: driverLatLng, pickupLocation: pickupLatLng);

          // Show ETA notification to rider
          final eta = rideDetailsController.mapController.driverETA;
          final distance = rideDetailsController.mapController.driverDistance;
          if (eta.isNotEmpty) {
            Get.snackbar('📦 Package Driver Assigned!', 'Your driver is on the way\nETA: $eta${distance.isNotEmpty ? " • Distance: $distance" : ""}', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 5), backgroundColor: Get.theme.colorScheme.primaryContainer, colorText: Get.theme.colorScheme.onPrimaryContainer);
          }
        }
      } else {
        printX('⚠️ Package ride accepted but driver location not available');
      }

      // Show success notification
      AudioUtils.playAudio(apiClient.getNotificationAudio());
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }
    }
  }

  void _handleDriverSearching(PusherResponseModel enventResponse) {
    printX('🔍 Driver searching event received');

    try {
      final notifiedCount = enventResponse.data?.notifiedCount ?? 0;
      final rejectedCount = enventResponse.data?.rejectedCount ?? 0;
      final status = enventResponse.data?.searchStatus ?? '';
      final message = enventResponse.data?.searchMessage ?? '';

      // Update driver counts on map controller
      rideDetailsController.mapController.updateDriverCounts(
        notifiedCount: notifiedCount,
        rejectedCount: rejectedCount,
        drivers: enventResponse.data?.searchingDrivers,
        driverImagePath: enventResponse.data?.driverImagePath,
      );

      printX('📊 Drivers: $notifiedCount notified, $rejectedCount rejected');

      // Show appropriate notification
      if (status == 'all_rejected') {
        Get.snackbar(
          '🔄 Searching for More Drivers',
          message.isNotEmpty ? message : 'Looking for more drivers in your area...',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      } else if (notifiedCount > 0) {
        Get.snackbar(
          '🔍 Contacting Drivers',
          'Contacting $notifiedCount driver${notifiedCount > 1 ? 's' : ''} nearby...',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      }
    } catch (e) {
      printX('❌ Error handling driver searching event: $e');

      Get.snackbar(
        '🔍 Searching for Drivers',
        'Contacting nearby drivers...',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );
    }
  }

  void _handleNewBid(PusherResponseModel enventResponse) {
    printX('🎯 NEW_BID event received!');
    printX('Current ride ID: $rideID');
    printX('Event data exists: ${enventResponse.data != null}');
    printX('Bid data exists: ${enventResponse.data?.bid != null}');

    if (enventResponse.data!.bid != null && enventResponse.data!.bid!.rideId != rideID) {
      printX('❌ Bid for different ride: ${enventResponse.data!.bid!.rideId}, current ride: $rideID');
      return;
    }

    final bid = enventResponse.data?.bid;
    if (bid != null) {
      printX('✅ Valid bid received for current ride!');
      printX('Bid ID: ${bid.id}');
      printX('Driver ID: ${bid.driverId}');
      printX('Bid Amount: ${bid.bidAmount}');

      AudioUtils.playAudio(apiClient.getNotificationAudio());
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }

      CustomBidDialog.newBid(bid: bid, currency: rideDetailsController.currencySym, driverImagePath: '${rideDetailsController.driverImagePath}/${bid.driver?.avatar}', serviceImagePath: '${rideDetailsController.serviceImagePath}/${enventResponse.data?.service?.image}', totalRideCompleted: enventResponse.data?.driverTotalRide ?? '0');

      printX('✅ Bid dialog shown to rider');
    } else {
      printX('❌ Bid data is null!');
    }
    rideDetailsController.updateBidCount(false);
  }

  void _handleCashPayment(PusherResponseModel event) {
    rideDetailsController.updatePaymentRequested(isRequested: false);
    _updateRideIfAvailable(event);
  }

  void _handleRideCanceled(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Ride canceled event for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    final ride = enventResponse.data?.ride;
    final canceledBy = enventResponse.data?.canceledBy ?? 'unknown';
    final cancelReason = enventResponse.data?.cancelReason ?? 'No reason provided';

    if (ride != null) {
      printX('🚫 Ride canceled by $canceledBy: $cancelReason');

      // Update ride status
      rideDetailsController.updateRide(ride);

      // Show notification to user
      if (canceledBy == 'driver') {
        AudioUtils.playAudio(apiClient.getNotificationAudio());
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
        Get.snackbar('🚫 Ride Canceled', 'Driver canceled the ride: $cancelReason', snackPosition: SnackPosition.TOP, backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError, duration: const Duration(seconds: 5));
      }

      // Navigate back to previous screen after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.isRegistered<RideDetailsController>()) {
          Get.back();
        }
      });
    }
  }

  void _updateRideIfAvailable(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    final ride = enventResponse.data?.ride;
    if (ride != null) {
      rideDetailsController.updateRide(ride);
    }
  }

  /// Utility
  bool isRideDetailsPage() => Get.currentRoute == RouteHelper.rideDetailsScreen;

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      final channel = channelName ?? "private-rider-user-$userId";
      printX("🔌 Ensuring Pusher connection to channel: $channel");
      printX("🔌 User ID: $userId");
      await PusherManager().checkAndInitIfNeeded(channel);
      printX("✅ Pusher connection ensured for channel: $channel");
    } catch (e) {
      printX("❌ Error ensuring connection: $e");
    }
  }
}
