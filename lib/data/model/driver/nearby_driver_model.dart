class VehicleDetails {
  final String? model;
  final String? color;
  final String? number;
  final String? year;
  final int capacity;
  final bool hasAc;
  final String luggage;

  VehicleDetails({
    this.model,
    this.color,
    this.number,
    this.year,
    required this.capacity,
    required this.hasAc,
    required this.luggage,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      model: json['model']?.toString(),
      color: json['color']?.toString(),
      number: json['number']?.toString(),
      year: json['year']?.toString(),
      capacity: int.tryParse(json['capacity'].toString()) ?? 4,
      hasAc: json['features']?['ac'] == true || json['features']?['ac'] == 1,
      luggage: json['features']?['luggage']?.toString() ?? 'Standard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'color': color,
      'number': number,
      'year': year,
      'capacity': capacity,
      'features': {
        'ac': hasAc,
        'luggage': luggage,
      },
    };
  }
}

class NearbyDriverModel {
  final int id;
  final double latitude;
  final double longitude;
  final int serviceId;
  final String serviceName;
  final double distanceKm;
  final double rating;
  final int totalRides;
  final String? image;
  final int? etaMinutes;
  final String? etaFormatted;
  final VehicleDetails? vehicle;

  NearbyDriverModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.serviceId,
    required this.serviceName,
    required this.distanceKm,
    required this.rating,
    required this.totalRides,
    this.image,
    this.etaMinutes,
    this.etaFormatted,
    this.vehicle,
  });

  factory NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    return NearbyDriverModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      serviceId: int.tryParse(json['service_id'].toString()) ?? 0,
      serviceName: json['service_name']?.toString() ?? 'Unknown Service',
      distanceKm: double.tryParse(json['distance_km'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      totalRides: int.tryParse(json['total_rides'].toString()) ?? 0,
      image: json['avatar']?.toString() ?? json['image']?.toString(),
      etaMinutes: json['eta_minutes'] != null ? int.tryParse(json['eta_minutes'].toString()) : null,
      etaFormatted: json['eta_formatted']?.toString(),
      vehicle: json['vehicle'] != null ? VehicleDetails.fromJson(json['vehicle']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'service_id': serviceId,
      'service_name': serviceName,
      'distance_km': distanceKm,
      'rating': rating,
      'total_rides': totalRides,
      'image': image,
      'eta_minutes': etaMinutes,
      'eta_formatted': etaFormatted,
      'vehicle': vehicle?.toJson(),
    };
  }
}
