import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class DriverRepo {
  ApiClient apiClient;

  DriverRepo({required this.apiClient});

  Future<dynamic> getNearbyDrivers({
    required double latitude,
    required double longitude,
    int? serviceId,
    int? zoneId,
    double? radius,
  }) async {
    Map<String, dynamic> params = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    if (serviceId != null) {
      params['service_id'] = serviceId.toString();
    }

    if (zoneId != null) {
      params['zone_id'] = zoneId.toString();
    }

    if (radius != null) {
      params['radius'] = radius.toString();
    }

    String url = '${UrlContainer.baseUrl}${UrlContainer.nearbyDriversEndpoint}';
    final response = await apiClient.request(
      url,
      Method.postMethod,
      params,
      passHeader: true,
    );
    return response;
  }

  Future<dynamic> getNearbyDriversEnhanced({
    required double latitude,
    required double longitude,
    int? serviceId,
    int? zoneId,
    double? radius,
    double? minRating,
    bool includeVehicleDetails = true,
  }) async {
    Map<String, dynamic> params = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'include_vehicle_details': includeVehicleDetails ? '1' : '0',
    };

    if (serviceId != null) {
      params['service_id'] = serviceId.toString();
    }

    if (zoneId != null) {
      params['zone_id'] = zoneId.toString();
    }

    if (radius != null) {
      params['radius'] = radius.toString();
    }

    if (minRating != null) {
      params['min_rating'] = minRating.toString();
    }

    String url = '${UrlContainer.baseUrl}nearby-drivers-enhanced';
    final response = await apiClient.request(
      url,
      Method.postMethod,
      params,
      passHeader: true,
    );
    return response;
  }

  Future<dynamic> getDriverDetails(int driverId) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.driverDetailsEndpoint}/$driverId';
    final response = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );
    return response;
  }
}
