import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/formdata/global_kyc_form_data.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/kyc/rider_kyc_response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class RiderVerificationKycRepo {
  ApiClient apiClient;
  RiderVerificationKycRepo({required this.apiClient});

  Future<RiderKycResponseModel> getRiderVerificationKycData() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.riderVerificationFormUrl}';
    debugPrint('DEBUG KYC REPO: Fetching from $url');
    ResponseModel responseModel = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );

    debugPrint('DEBUG KYC REPO: Response status code: ${responseModel.statusCode}');
    debugPrint('DEBUG KYC REPO: Response body: ${responseModel.responseJson}');

    if (responseModel.statusCode == 200) {
      RiderKycResponseModel model = RiderKycResponseModel.fromJson(
        (responseModel.responseJson),
      );

      debugPrint('DEBUG KYC REPO: Model status: ${model.status}, remark: ${model.remark}');
      debugPrint('DEBUG KYC REPO: Form list length: ${model.data?.form?.list?.length}');

      if (model.status == 'success') {
        return model;
      } else {
        if (model.remark?.toLowerCase() != 'already_verified' && model.remark?.toLowerCase() != 'under_review') {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }

        return model;
      }
    } else {
      debugPrint('DEBUG KYC REPO: Non-200 response, returning empty model');
      return RiderKycResponseModel();
    }
  }

  List<Map<String, String>> fieldList = [];
  List<ModelDynamicValue> filesList = [];

  Future<AuthorizationResponseModel> submitRiderVerificationKycData(
    List<GlobalFormModel> list,
  ) async {
    // Clear previous data to prevent stale values
    fieldList.clear();
    filesList.clear();

    apiClient.initToken();
    await modelToMap(list);
    String url = '${UrlContainer.baseUrl}${UrlContainer.riderVerificationFormUrl}';

    Map<String, String> finalMap = {};

    for (var element in fieldList) {
      finalMap.addAll(element);
    }

    Map<String, File> attachmentFiles = filesList.isEmpty == true
        ? {}
        : filesList.asMap().map(
              (index, value) => MapEntry(value.key ?? "", value.value),
            );
    ResponseModel responseModel = await apiClient.multipartRequest(
      url,
      Method.postMethod,
      finalMap,
      files: attachmentFiles,
      passHeader: true,
    );
    AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
      (responseModel.responseJson),
    );

    return model;
  }

  Future<dynamic> modelToMap(List<GlobalFormModel> list) async {
    debugPrint('DEBUG modelToMap: Processing ${list.length} form fields');
    for (var e in list) {
      debugPrint('DEBUG modelToMap: Field label="${e.label}" type="${e.type}" selectedValue="${e.selectedValue}"');

      if (e.type == 'checkbox') {
        if (e.cbSelected != null && e.cbSelected!.isNotEmpty) {
          for (int i = 0; i < e.cbSelected!.length; i++) {
            fieldList.add({'${e.label}[$i]': e.cbSelected![i]});
            debugPrint('DEBUG modelToMap:   -> Added checkbox: ${e.label}[$i]=${e.cbSelected![i]}');
          }
        }
      } else if (e.type == 'file') {
        if (e.imageFile != null) {
          filesList.add(ModelDynamicValue(e.label, e.imageFile!));
          debugPrint('DEBUG modelToMap:   -> Added file: ${e.label}');
        }
      } else {
        // For ALL other types (text, number, email, url, textarea, date, time, datetime, select, radio)
        // the UI updates selectedValue via onChanged callback
        if (e.selectedValue != null && e.selectedValue.toString().isNotEmpty) {
          fieldList.add({e.label ?? '': e.selectedValue.toString()});
          debugPrint('DEBUG modelToMap:   -> Added: ${e.label}=${e.selectedValue}');
        } else {
          debugPrint('DEBUG modelToMap:   -> SKIPPED (empty selectedValue)');
        }
      }
    }
    debugPrint('DEBUG modelToMap: Final fieldList has ${fieldList.length} entries');
  }
}

class ModelDynamicValue {
  String? key;
  dynamic value;
  ModelDynamicValue(this.key, this.value);
}
