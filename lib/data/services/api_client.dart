// ignore_for_file: library_prefixes

import 'dart:io';

import 'package:dio/dio.dart' as dioX;
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/unverified_response_model.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient extends LocalStorageService {
  final dioX.Dio _dio = dioX.Dio();

  ApiClient({required super.sharedPreferences}) {
    _dio.options.headers = {
      "Accept": "application/json",
      "dev-token": Environment.devToken,
    };
    _dio.options.followRedirects = false;
    _dio.options.validateStatus = (status) {
      return status! < 500;
    };
  }

  static Future<void> init() async {
    // Initialize SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();

    // Initialize and register API client (which extends LocalStorageService)
    final apiClient = ApiClient(sharedPreferences: sharedPreferences);
    Get.put<ApiClient>(apiClient, permanent: true);

    // Also register it as LocalStorageService for any code that expects that type
    Get.put<LocalStorageService>(apiClient, permanent: true);
  }

  /// Request
  Future<ResponseModel> request(
    String uri,
    String method,
    Map<String, dynamic>? params, {
    bool passHeader = false,
    bool isOnlyAcceptType = false,
  }) async {
    try {
      if (passHeader && !isOnlyAcceptType) {
        initToken();
      }

      dioX.Response response;

      switch (method) {
        case Method.postMethod:
          if (passHeader) {
            if (!isOnlyAcceptType) {
              _dio.options.headers["Authorization"] = "$tokenType $token";
            }
          }
          response = await _dio.post(uri, data: params);
          break;
        case Method.deleteMethod:
          response = await _dio.delete(uri);
          break;
        case Method.updateMethod:
          response = await _dio.patch(uri);
          break;
        default: // GET
          if (passHeader && !isOnlyAcceptType) {
            _dio.options.headers["Authorization"] = "$tokenType $token";
          }
          response = await _dio.get(uri);
          break;
      }

      printX('url--------------$uri');
      // printX('params-----------${params.toString()}');
      // // printX('status-----------${response.statusCode}');
      printX('body-------------${response.data.toString()}');
      // printX('token------------$token');

      // Process response
      if (response.statusCode == 200) {
        if (response.data == null || (response.data is String && response.data.isEmpty)) {
          Get.offAllNamed(RouteHelper.loginScreen);
          return ResponseModel(false, MyStrings.somethingWentWrong.tr, 499, '');
        }

        try {
          // Handle different response types
          AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(response.data);

          if (model.remark == 'profile_incomplete') {
            Get.toNamed(RouteHelper.profileCompleteScreen);
          } else if (model.remark == 'unverified') {
            UnVerifiedUserResponseModel model = UnVerifiedUserResponseModel.fromJson(response.data);
            printD("unverified ${model.data?.user?.toJson()}");
            checkAndGotoVerificationScreen(model);
          } else if (model.remark == 'unauthenticated') {
            setRememberMe(false);
            removeToken();
            Get.offAllNamed(RouteHelper.loginScreen);
          } else if (model.remark == 'rider_unverified' || model.remark == 'rider_verification_pending' || model.remark == 'rider_verification_rejected') {
            // Only redirect if not already on the verification screen
            if (Get.currentRoute != RouteHelper.riderProfileVerificationScreen) {
              Get.toNamed(RouteHelper.riderProfileVerificationScreen);
            }
          }
        } catch (e) {
          printX("Response parsing error: ${e.toString()}");
        }

        return ResponseModel(true, 'success', 200, response.data);
      } else if (response.statusCode == 401) {
        setRememberMe(false);
        Get.offAllNamed(RouteHelper.loginScreen);
        return ResponseModel(false, MyStrings.unAuthorized.tr, 401, response.data);
      } else if (response.statusCode == 500) {
        return ResponseModel(false, MyStrings.serverError.tr, 500, response.data);
      } else {
        return ResponseModel(false, MyStrings.somethingWentWrong.tr, response.statusCode ?? 499, response.data);
      }
    } on dioX.DioException catch (e) {
      if (e.type == dioX.DioExceptionType.connectionTimeout || e.type == dioX.DioExceptionType.receiveTimeout || e.type == dioX.DioExceptionType.connectionError) {
        return ResponseModel(false, MyStrings.noInternet.tr, 503, '');
      } else {
        return ResponseModel(false, e.message ?? MyStrings.somethingWentWrong.tr, 499, '');
      }
    } catch (e) {
      return ResponseModel(false, MyStrings.somethingWentWrong.tr, 499, '');
    }
  }

  /// Multipart Request
  Future<ResponseModel> multipartRequest(
    String uri,
    String method,
    Map<String, dynamic>? fields, {
    required Map<String, File> files,
    bool passHeader = false,
  }) async {
    try {
      if (passHeader) {
        initToken();
        printE(token);
        _dio.options.headers["Authorization"] = "$tokenType $token";
      }

      final formData = dioX.FormData();

      // Add text fields
      fields?.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // Add files with dynamic keys - use for...in to properly await
      for (var entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key, // Dynamic key for each file
            await dioX.MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
            ),
          ),
        );
      }

      dioX.Response response;
      printX('🚀 Sending multipart request to: $uri');
      printX('📦 Fields: ${formData.fields.map((e) => "${e.key}=${e.value}").join(", ")}');
      printX('📎 Files: ${formData.files.map((e) => "${e.key}=${e.value.filename}").join(", ")}');
      switch (method) {
        case Method.postMethod:
          response = await _dio.post(uri, data: formData);
          break;
        case Method.updateMethod:
          response = await _dio.patch(uri, data: formData);
          break;
        default:
          return ResponseModel(false, 'Unsupported method', 405, '');
      }

      printX('url--------------$uri');
      printX('status-----------${response.statusCode}');
      printX('body-------------${response.data.toString()}');

      if (response.statusCode == 200) {
        return ResponseModel(true, 'success', 200, response.data);
      } else {
        return ResponseModel(false, MyStrings.somethingWentWrong.tr, response.statusCode ?? 499, response.data);
      }
    } on dioX.DioException catch (e) {
      if (e.type == dioX.DioExceptionType.connectionTimeout || e.type == dioX.DioExceptionType.receiveTimeout || e.type == dioX.DioExceptionType.connectionError) {
        return ResponseModel(false, MyStrings.noInternet.tr, 503, '');
      } else {
        return ResponseModel(false, e.message ?? MyStrings.somethingWentWrong.tr, 499, '');
      }
    } catch (e) {
      return ResponseModel(false, MyStrings.somethingWentWrong.tr, 499, '');
    }
  }

  String token = '';
  String tokenType = '';

  void initToken() {
    token = getToken();
    tokenType = getTokenType();
  }

  // Method to handle unverified user
  void checkAndGotoVerificationScreen(UnVerifiedUserResponseModel model) {
    var data = model.data;
    bool needProfileComplete = data?.user?.profileComplete == "0" ? true : false;
    bool needEmailVerification = data?.user?.ev == "0" ? true : false;
    bool needSmsVerification = data?.user?.sv == "0" ? true : false;

    // Only check donation if feature is enabled
    bool isDonationFeatureEnabled = isDonationEnabled();
    bool needDonationVerification = isDonationEnabled() && (data?.user?.donationVerified == "0" || data?.user?.donationVerified == null || data?.user?.donationVerified == "null");

    // Check rider verification (similar to mobile verification)
    // If rv_status is null, allow access (backward compatibility)
    // If rv_status is set but not "1" (VERIFIED), require verification
    bool needRiderVerification = false;
    if (data?.user?.rvStatus != null && data?.user?.rvStatus != "1") {
      needRiderVerification = true;
    }

    printD("Verification checks - Profile: $needProfileComplete, Email: $needEmailVerification, SMS: $needSmsVerification, Donation: $needDonationVerification (enabled: $isDonationFeatureEnabled, donation_verified: ${data?.user?.donationVerified}), Rider: $needRiderVerification (rv_status: ${data?.user?.rvStatus})");

    if (needProfileComplete) {
      Get.toNamed(RouteHelper.profileCompleteScreen);
    } else if (needEmailVerification) {
      setRememberMe(false);
      Get.offAndToNamed(
        RouteHelper.emailVerificationScreen,
        arguments: [false, false, false],
      );
    } else if (needSmsVerification) {
      setRememberMe(false);
      Get.offAllNamed(RouteHelper.smsVerificationScreen);
    } else if (needDonationVerification) {
      printD("Redirecting to donation verification screen");
      setRememberMe(false);
      Get.offAllNamed(RouteHelper.donationVerificationScreen);
    } else if (needRiderVerification) {
      printD("Redirecting to rider verification screen");
      setRememberMe(false);
      // Only redirect if not already on the verification screen
      if (Get.currentRoute != RouteHelper.riderProfileVerificationScreen) {
        Get.offAllNamed(RouteHelper.riderProfileVerificationScreen);
      }
    } else {
      // Check agreement signed status from API response
      bool needAgreement = data?.user?.agreementSigned != "1";
      if (needAgreement) {
        printD("Redirecting to rider agreement screen");
        setRememberMe(false);
        Get.offAllNamed(RouteHelper.riderAgreementScreen);
      } else {
        setRememberMe(false);
        removeToken();
        Get.offAllNamed(RouteHelper.loginScreen);
      }
    }
  }
}
