import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';

class PackageRepo {
  ApiClient apiClient;
  PackageRepo({required this.apiClient});

  // Get all available packages (for purchase)
  Future<ResponseModel> getAvailablePackages() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesAvailableEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get user's active packages
  Future<ResponseModel> getActivePackages() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesActiveEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get user's package history
  Future<ResponseModel> getPackageHistory() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesHistoryEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get package usage details
  Future<ResponseModel> getPackageUsage(int userPackageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesUsageEndpoint}/$userPackageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get package details (for purchase)
  Future<ResponseModel> getPackageDetails(int packageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageEndpoint}/show/$packageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Purchase package
  Future<ResponseModel> purchasePackage(int packageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageEndpoint}/purchase";
    Map<String, dynamic> params = {'package_id': packageId};
    return await apiClient.request(url, Method.postMethod, params, passHeader: true);
  }

  // Get user's purchased packages (legacy - use getPackageHistory instead)
  Future<ResponseModel> getMyPackages() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageEndpoint}/my-packages";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get user package details (legacy - use getPackageUsage instead)
  Future<ResponseModel> getUserPackageDetails(int userPackageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageEndpoint}/details/$userPackageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Package Schedule APIs
  
  // Get package with schedule details
  Future<ResponseModel> getPackageWithSchedule(int packageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageScheduleDetailsEndpoint}/$packageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Purchase package with schedule
  Future<ResponseModel> purchasePackageWithSchedule(Map<String, dynamic> data) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageSchedulePurchaseEndpoint}";
    return await apiClient.request(url, Method.postMethod, data, passHeader: true);
  }

  // Get user's package schedules
  Future<ResponseModel> getUserPackageSchedules(int userPackageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageScheduleMySchedulesEndpoint}/$userPackageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
