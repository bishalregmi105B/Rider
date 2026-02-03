import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  GlobalPusherController({required this.apiClient});

  @override
  void onInit() {
    super.onInit();

    PusherManager().addListener(onEvent);
  }

  List<String> activeEventList = ["new_ride_created", "ride_end", "pick_up", "cash_payment_received", "new_bid", "driver_searching"];

  void onEvent(PusherEvent event) {
    try {
      printE("Global pusher event: ${event.eventName}");
      printE("Global pusher event: ${event.data}");
      
      // Ignore pusher internal events
      if (event.eventName.startsWith('pusher:')) {
        return;
      }
      
      if (event.data == null || event.eventName == "") return;

      final eventName = event.eventName.toLowerCase();

      // Handle both string and map data types
      final dynamic rawData = event.data;
      final Map<String, dynamic> data;
      
      if (rawData is String) {
        data = jsonDecode(rawData);
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        printE("Unexpected data type: ${rawData.runtimeType}");
        return;
      }
      
      final model = PusherResponseModel.fromJson(data);

      if (activeEventList.contains(eventName) && !isRideDetailsPage()) {
        final rideId = eventName == "new_bid" ? model.data?.bid?.rideId : model.data?.ride?.id;
        
        // Check if this is a scheduled ride (should not navigate immediately)
        final isScheduled = (model.data?.ride?.isScheduled == true || model.data?.ride?.isScheduled == 1);
        
        if (rideId != null && isScheduled == false) {
          printX('📱 Navigating to ride details screen for ride: $rideId');
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        } else if (isScheduled == true) {
          printX('📅 Scheduled ride event received - skipping navigation');
        }
      }
    } catch (e) {
      printE("Error handling event ${event.eventName}: $e");
    }
  }

  bool isRideDetailsPage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
  }

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      await PusherManager().checkAndInitIfNeeded(channelName ?? "private-rider-user-$userId");
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}
