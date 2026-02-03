// To parse this JSON data, do
//
//     final paymentHistoryResponseModel = paymentHistoryResponseModelFromJson(jsonString);

import 'dart:convert';

import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/data/model/global/user/global_driver_model.dart';
import 'package:ovorideuser/data/model/global/user/global_user_model.dart';

PaymentHistoryResponseModel paymentHistoryResponseModelFromJson(String str) => PaymentHistoryResponseModel.fromJson(json.decode(str));

String paymentHistoryResponseModelToJson(PaymentHistoryResponseModel data) => json.encode(data.toJson());

class PaymentHistoryResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  Data? data;

  PaymentHistoryResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory PaymentHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle message field - can be List or Map
    List<String> parseMessage(dynamic messageData) {
      if (messageData == null) return [];
      
      if (messageData is List) {
        return List<String>.from(messageData.map((x) => x.toString()));
      } else if (messageData is Map) {
        // If it's a map like {success: [Payment Data]}, extract all values
        List<String> messages = [];
        messageData.forEach((key, value) {
          if (value is List) {
            messages.addAll(List<String>.from(value.map((x) => x.toString())));
          } else {
            messages.add(value.toString());
          }
        });
        return messages;
      }
      
      return [messageData.toString()];
    }

    return PaymentHistoryResponseModel(
      remark: json["remark"],
      status: json["status"],
      message: parseMessage(json["message"]),
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "remark": remark,
        "status": status,
        "message": message == null ? [] : List<dynamic>.from(message!.map((x) => x)),
        "data": data?.toJson(),
      };
}

class Data {
  PaymentHistory? payments;

  Data({this.payments});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        payments: json["payments"] == null ? null : PaymentHistory.fromJson(json["payments"]),
      );

  Map<String, dynamic> toJson() => {"payments": payments?.toJson()};
}

class PaymentHistory {
  List<PaymentHistoryData>? data;

  dynamic nextPageUrl;

  PaymentHistory({this.data, this.nextPageUrl});

  factory PaymentHistory.fromJson(Map<String, dynamic> json) => PaymentHistory(
        data: json["data"] == null
            ? []
            : List<PaymentHistoryData>.from(
                json["data"]!.map((x) => PaymentHistoryData.fromJson(x)),
              ),
        nextPageUrl: json["next_page_url"],
      );

  Map<String, dynamic> toJson() => {
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
        "next_page_url": nextPageUrl,
      };
}

class PaymentHistoryData {
  String? id;
  String? rideId;
  String? riderId;
  String? driverId;
  String? amount;
  String? paymentType;
  String? createdAt;
  String? updatedAt;
  GlobalUser? rider;
  RideModel? ride;
  GlobalDriverInfo? driver;
  
  // Transaction metadata
  String? transactionType; // "ride" or "web"
  String? source; // "app" or "website"
  String? trxNumber; // Transaction number
  String? description; // Transaction description
  String? remark; // For web transactions
  String? trxType; // "+" or "-" for web transactions

  PaymentHistoryData({
    this.id,
    this.rideId,
    this.riderId,
    this.driverId,
    this.amount,
    this.paymentType,
    this.createdAt,
    this.updatedAt,
    this.rider,
    this.ride,
    this.driver,
    this.transactionType,
    this.source,
    this.trxNumber,
    this.description,
    this.remark,
    this.trxType,
  });

  factory PaymentHistoryData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any value to string
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    return PaymentHistoryData(
      id: _toStringOrNull(json["id"]),
      rideId: _toStringOrNull(json["ride_id"]),
      riderId: _toStringOrNull(json["rider_id"]),
      driverId: _toStringOrNull(json["driver_id"]),
      amount: _toStringOrNull(json["amount"]),
      paymentType: _toStringOrNull(json["payment_type"]),
      createdAt: _toStringOrNull(json["created_at"]),
      updatedAt: _toStringOrNull(json["updated_at"]),
      rider: json["rider"] == null ? null : GlobalUser.fromJson(json["rider"]),
      ride: json["ride"] == null ? null : RideModel.fromJson(json["ride"]),
      driver: json["driver"] == null ? null : GlobalDriverInfo.fromJson(json["driver"]),
      transactionType: _toStringOrNull(json["transaction_type"]),
      source: _toStringOrNull(json["source"]),
      trxNumber: _toStringOrNull(json["trx_number"]),
      description: _toStringOrNull(json["description"]),
      remark: _toStringOrNull(json["remark"]),
      trxType: _toStringOrNull(json["trx_type"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "ride_id": rideId,
        "rider_id": riderId,
        "driver_id": driverId,
        "amount": amount,
        "payment_type": paymentType,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "rider": rider?.toJson(),
        "ride": ride,
        "driver": driver?.toJson(),
        "transaction_type": transactionType,
        "source": source,
        "trx_number": trxNumber,
        "description": description,
        "remark": remark,
        "trx_type": trxType,
      };
  
  // Helper methods
  bool get isRidePayment => transactionType == "ride";
  bool get isWebTransaction => transactionType == "web";
  bool get isPackagePurchase => remark == "package_purchase";
  bool get isDonation => remark == "donation";
  bool get isFromApp => source == "app";
  bool get isFromWebsite => source == "website";
}
