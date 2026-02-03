import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';

class ReservationRepo {
  ApiClient apiClient;
  ReservationRepo({required this.apiClient});

  // Get all user reservations
  Future<ResponseModel> getMyReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get active reservations
  Future<ResponseModel> getActiveReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationsActiveEndpoint}";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get upcoming reservations
  Future<ResponseModel> getUpcomingReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationsUpcomingEndpoint}";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get reservation details
  Future<ResponseModel> getReservationDetail(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/show/$id";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Create new reservation
  Future<ResponseModel> createReservation(Map<String, dynamic> data) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/store";
    final response = await apiClient.request(url, Method.postMethod, data, passHeader: true);
    return response;
  }

  // Update reservation
  Future<ResponseModel> updateReservation(int id, Map<String, dynamic> data) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/update/$id";
    final response = await apiClient.request(url, Method.postMethod, data, passHeader: true);
    return response;
  }

  // Cancel reservation
  Future<ResponseModel> cancelReservation(int id, String reason) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/cancel/$id";
    Map<String, dynamic> data = {'cancellation_reason': reason};
    final response = await apiClient.request(url, Method.postMethod, data, passHeader: true);
    return response;
  }

  // Get reservation schedules
  Future<ResponseModel> getReservationSchedules(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/schedules/$id";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get available services for reservation
  Future<ResponseModel> getAvailableServices() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationAvailableServicesEndpoint}";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get reservation fare estimate
  Future<ResponseModel> getFareEstimate(Map<String, dynamic> data) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reservationEndpoint}/estimate-fare";
    final response = await apiClient.request(url, Method.postMethod, data, passHeader: true);
    return response;
  }
}
