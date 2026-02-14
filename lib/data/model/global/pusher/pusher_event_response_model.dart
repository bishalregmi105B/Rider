// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final pusherResponseModel = pusherResponseModelFromJson(jsonString);

import 'dart:convert';

import 'package:ovorideuser/data/model/global/app/app_service_model.dart';
import 'package:ovorideuser/data/model/global/app/ride_message_model.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/data/model/global/bid/bid_model.dart';

PusherResponseModel pusherResponseModelFromJson(String str) => PusherResponseModel.fromJson(json.decode(str));

class PusherResponseModel {
  String? channelName;
  String? eventName;
  EventData? data;

  PusherResponseModel({this.channelName, this.eventName, this.data});

  PusherResponseModel copyWith({
    String? channelName,
    String? eventName,
    EventData? data,
  }) =>
      PusherResponseModel(
        channelName: channelName.toString(),
        eventName: eventName.toString(),
        data: data,
      );

  factory PusherResponseModel.fromJson(Map<String, dynamic> json) {
    return PusherResponseModel(
      channelName: json["channelName"].toString(),
      eventName: json["eventName"].toString(),
      data: EventData.fromJson(json["data"]),
    );
  }
}

class EventData {
  String? remark;
  String? userId;
  String? driverId;
  String? rideId;
  String? driverTotalRide;
  RideMessage? message;
  String? driverLatitude;
  String? driverLongitude;
  String? canceledBy;
  String? cancelReason;
  RideModel? ride;
  AppService? service;
  BidModel? bid;

  // Broadcast notification fields (driver count-based)
  int? notifiedCount;
  int? rejectedCount;
  String? searchStatus;
  String? searchMessage;

  // Driver avatar info for searching UI
  List<SearchingDriverInfo>? searchingDrivers;
  String? driverImagePath;

  EventData({
    this.remark,
    this.userId,
    this.driverId,
    this.rideId,
    this.driverTotalRide,
    this.message,
    this.driverLatitude,
    this.driverLongitude,
    this.canceledBy,
    this.cancelReason,
    this.ride,
    this.service,
    this.bid,
    this.notifiedCount,
    this.rejectedCount,
    this.searchStatus,
    this.searchMessage,
    this.searchingDrivers,
    this.driverImagePath,
  });

  EventData copyWith({
    String? channelName,
    String? eventName,
    String? remark,
    String? userId,
    String? driverId,
    String? rideId,
    String? driverTotalRide,
    RideMessage? message,
    String? driverLatitude,
    String? driverLongitude,
    String? canceledBy,
    String? cancelReason,
    RideModel? ride,
    AppService? service,
    BidModel? bid,
  }) =>
      EventData(
        remark: remark.toString(),
        userId: userId.toString(),
        driverId: driverId.toString(),
        rideId: rideId.toString(),
        driverTotalRide: driverTotalRide.toString(),
        message: message,
        driverLatitude: driverLatitude ?? '',
        driverLongitude: driverLongitude ?? '',
        canceledBy: canceledBy ?? '',
        cancelReason: cancelReason ?? '',
        ride: ride,
        service: service,
        bid: bid,
      );

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      remark: json["remark"]?.toString() ?? '',
      userId: json["userId"]?.toString() ?? json["user_id"]?.toString() ?? '',
      driverId: json["driverId"]?.toString() ?? json["driver_id"]?.toString() ?? '',
      rideId: json["rideId"]?.toString() ?? json["ride_id"]?.toString() ?? '',
      driverTotalRide: json["driver_total_ride"]?.toString() ?? '',
      message: json["message"] != null && json["message"] is Map ? RideMessage.fromJson(json["message"]) : null,
      driverLatitude: json["driver_latitude"]?.toString() ?? json["latitude"]?.toString() ?? '',
      driverLongitude: json["driver_longitude"]?.toString() ?? json["longitude"]?.toString() ?? '',
      canceledBy: json["canceled_by"]?.toString() ?? '',
      cancelReason: json["cancel_reason"]?.toString() ?? '',
      ride: json["ride"] != null ? (json["ride"] is String ? RideModel.fromJson(jsonDecode(json["ride"])) : RideModel.fromJson(json["ride"])) : null,
      service: json["service"] != null ? AppService.fromJson(json["service"]) : null,
      bid: json["bid"] != null ? BidModel.fromJson(json["bid"]) : null,
      notifiedCount: json["notified_count"] != null ? (json["notified_count"] is int ? json["notified_count"] : int.tryParse(json["notified_count"].toString())) : null,
      rejectedCount: json["rejected_count"] != null ? (json["rejected_count"] is int ? json["rejected_count"] : int.tryParse(json["rejected_count"].toString())) : null,
      searchStatus: json["status"]?.toString() ?? '',
      searchMessage: json["message"] is String ? json["message"].toString() : '',
      searchingDrivers: json["drivers"] != null && json["drivers"] is List ? (json["drivers"] as List).map((d) => SearchingDriverInfo.fromJson(d)).toList() : null,
      driverImagePath: json["driver_image_path"]?.toString(),
    );
  }
}

/// Lightweight driver info sent with DRIVER_SEARCHING events
class SearchingDriverInfo {
  final int? id;
  final String firstname;
  final String lastname;
  final String image;

  SearchingDriverInfo({
    this.id,
    this.firstname = '',
    this.lastname = '',
    this.image = '',
  });

  factory SearchingDriverInfo.fromJson(Map<String, dynamic> json) {
    return SearchingDriverInfo(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }

  String get initials {
    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    return '$f$l';
  }
}
