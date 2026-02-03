import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class CreateRideRequestModel {
  String serviceId;
  String pickUpLocation;
  String pickUpLatitude;
  String pickUpLongitude;
  String destinationLocation;
  String destinationLatitude;
  String destinationLongitude;
  String isIntercity;
  String pickUpDateTime;
  String numberOfPassenger;
  String note;
  String offerAmount;
  String paymentType;
  String gatewayCurrencyId;
  String? userPackageId; // For package rides
  String? isScheduled; // For scheduled rides
  String? scheduledTime; // DateTime for scheduled pickup
  
  CreateRideRequestModel({
    required this.serviceId,
    required this.pickUpLocation,
    required this.pickUpLatitude,
    required this.pickUpLongitude,
    required this.destinationLocation,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.isIntercity,
    required this.pickUpDateTime,
    required this.numberOfPassenger,
    required this.note,
    required this.offerAmount,
    required this.paymentType,
    required this.gatewayCurrencyId,
    this.userPackageId, // Optional for package rides
    this.isScheduled, // Optional for scheduled rides
    this.scheduledTime, // Optional for scheduled rides
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'service_id': serviceId,
      'pickup_location': pickUpLocation,
      'pickup_latitude': pickUpLatitude,
      'pickup_longitude': pickUpLongitude,
      'destination_location': destinationLocation,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'is_intercity': isIntercity,
      'pickup_date_time': pickUpDateTime,
      'number_of_passenger': numberOfPassenger,
      'note': note,
      'offer_amount': offerAmount,
      'payment_type': paymentType,
      'gateway_currency_id': gatewayCurrencyId,
    };
    
    // Add user_package_id only if it's provided (for package rides)
    if (userPackageId != null) {
      map['user_package_id'] = userPackageId;
    }
    
    // Add scheduled ride fields if provided
    if (isScheduled != null) {
      map['is_scheduled'] = isScheduled;
    }
    if (scheduledTime != null) {
      map['scheduled_time'] = scheduledTime;
    }
    
    return map;
  }

  factory CreateRideRequestModel.fromMap(Map<String, dynamic> map) {
    return CreateRideRequestModel(
      serviceId: map['serviceId'] as String,
      pickUpLocation: map['pickUpLocation'] as String,
      pickUpLatitude: map['pickUpLatitude'] as String,
      pickUpLongitude: map['pickUpLongitude'] as String,
      destinationLocation: map['destination'] as String,
      destinationLatitude: map['destinationLatitude'] as String,
      destinationLongitude: map['destinationLongitude'] as String,
      isIntercity: map['isIntercity'] as String,
      pickUpDateTime: map['pickUpDateTime'] as String,
      numberOfPassenger: map['numberOfPassenger'] as String,
      note: map['note'] as String,
      offerAmount: map['offerAmount'] as String,
      paymentType: map['paymentType'] as String,
      gatewayCurrencyId: map['gatewayCurrencyId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CreateRideRequestModel.fromJson(String source) => CreateRideRequestModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
