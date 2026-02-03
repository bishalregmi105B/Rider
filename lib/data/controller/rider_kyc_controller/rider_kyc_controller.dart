import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/formdata/global_kyc_form_data.dart';
import 'package:ovorideuser/data/model/kyc/kyc_pending_data_model.dart';
import 'package:ovorideuser/data/model/kyc/rider_kyc_response_model.dart';
import 'package:ovorideuser/data/repo/rider_profile_verification/rider_kyc_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/route/route.dart';

import '../../../core/helper/date_converter.dart';

class RiderKycController extends GetxController {
  RiderVerificationKycRepo repo;
  RiderKycController({required this.repo});
  File? imageFile;

  bool isLoading = true;
  List<GlobalFormModel> formList = [];

  String selectOne = MyStrings.selectOne;

  RiderKycResponseModel model = RiderKycResponseModel();
  bool isNoDataFound = false;
  bool isAlreadyVerified = false;
  bool isAlreadyPending = false;
  List<KycPendingData> pendingData = [];
  String path = '';

  // Guard to prevent navigation loop
  bool _isRedirectingToAgreement = false;

  Future<void> beforeInitLoadKycData() async {
    // Prevent infinite redirect loop
    if (_isRedirectingToAgreement) {
      _isRedirectingToAgreement = false;
      return;
    }

    setStatusTrue();
    printX('DEBUG KYC: Starting beforeInitLoadKycData');

    try {
      model = await repo.getRiderVerificationKycData();
      printX('DEBUG KYC: Got response - status: ${model.status}, remark: ${model.remark}');
      printX('DEBUG KYC: data is null? ${model.data == null}');
      printX('DEBUG KYC: form is null? ${model.data?.form == null}');
      printX('DEBUG KYC: form list length: ${model.data?.form?.list?.length}');

      // Check if API says agreement is required
      if (model.remark?.toLowerCase() == 'agreement_required') {
        _isRedirectingToAgreement = true;
        CustomSnackBar.error(errorList: model.message ?? ['Please sign the agreement first.']);
        Get.offNamed(RouteHelper.riderAgreementScreen);
        return;
      }

      if (model.data != null && model.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
        path = model.data?.path ?? '';
        // Clear existing pending data before adding new
        pendingData.clear();
        List<KycPendingData>? pList = model.data?.riderData;
        if (pList != null && pList.isNotEmpty) {
          pendingData.addAll(pList);
        }
        List<GlobalFormModel>? tList = model.data?.form?.list;

        if (tList != null && tList.isNotEmpty) {
          formList.clear();
          for (var element in tList) {
            // Skip agreement fields - they are handled on the agreement screen
            if (element.name == 'kyc_signature' || element.name == 'agreement_signed') {
              continue;
            }
            if (element.type == 'select') {
              bool? isEmpty = element.options?.isEmpty;
              bool empty = isEmpty ?? true;
              if (element.options != null && empty != true) {
                element.options?.insert(0, selectOne);
                element.selectedValue = element.options?.first;
                formList.add(element);
              }
            } else {
              formList.add(element);
            }
          }
        }
        // Handle different verification states
        if (model.remark?.toLowerCase() == 'already_verified') {
          isAlreadyVerified = true;
          isAlreadyPending = false;
        } else if (model.remark?.toLowerCase() == 'under_review') {
          isAlreadyPending = true;
          isAlreadyVerified = false;
        } else if (model.remark?.toLowerCase() == 'rider_verification_form') {
          // Form is available, user can submit
          isAlreadyVerified = false;
          isAlreadyPending = false;
        }
        isNoDataFound = false;
        update();
      } else {
        isNoDataFound = true;
      }
    } finally {
      setStatusFalse();
    }
    setStatusFalse();
  }

  void setStatusTrue() {
    isLoading = true;
    update();
  }

  void setStatusFalse() {
    isLoading = false;
    update();
  }

  bool submitLoading = false;
  Future<void> submitKycData() async {
    List<String> list = hasError();

    if (list.isNotEmpty) {
      CustomSnackBar.error(errorList: list);
      return;
    }

    submitLoading = true;
    update();

    // Agreement is now submitted separately via /api/rider-agreement
    // Just submit the KYC form data

    AuthorizationResponseModel response = await repo.submitRiderVerificationKycData(formList);

    if (response.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
      // Check if response indicates under_review status
      if (response.remark?.toLowerCase() == 'under_review') {
        // Set pending state immediately
        isAlreadyPending = true;
        isAlreadyVerified = false;
        isNoDataFound = false;

        // Clear form list since we're now in pending state
        formList.clear();
        pendingData.clear();

        CustomSnackBar.success(
          successList: response.message ?? [MyStrings.success.tr],
        );

        // Reload data to get the submitted verification data
        await beforeInitLoadKycData();
      } else {
        // For other success responses, just reload
        CustomSnackBar.success(
          successList: response.message ?? [MyStrings.success.tr],
        );
        await beforeInitLoadKycData();
      }
    } else {
      List<String> messages = response.message ?? [MyStrings.requestFail.tr];
      bool isAgreementError = messages.any((msg) => msg.toLowerCase().contains('agreement signed field is required') || msg.toLowerCase().contains('kyc signature field is required'));

      if (isAgreementError) {
        CustomSnackBar.error(errorList: ["Please sign the agreement to continue."]);
        await Get.find<ApiClient>().sharedPreferences.setBool(SharedPreferenceHelper.riderAgreementAcceptedKey, false);
        Get.offNamed(RouteHelper.riderAgreementScreen);
      } else {
        CustomSnackBar.error(errorList: messages);
      }
    }

    submitLoading = false;
    update();
  }

  List<String> hasError() {
    List<String> errorList = [];
    errorList.clear();

    for (var element in formList) {
      if (element.isRequired == 'required') {
        if (element.type == 'checkbox') {
          if (element.cbSelected == null) {
            errorList.add('${element.name} ${MyStrings.isRequired}');
          }
        } else if (element.type == 'file') {
          if (element.imageFile == null) {
            errorList.add('${element.name} ${MyStrings.isRequired}');
          }
        } else {
          if (element.selectedValue == '' || element.selectedValue == selectOne) {
            errorList.add('${element.name} ${MyStrings.isRequired}');
          }
        }
      }
    }

    return errorList;
  }

  void changeSelectedValue(dynamic value, int index) {
    formList[index].selectedValue = value;
    update();
  }

  void changeSelectedRadioBtnValue(int listIndex, int selectedIndex) {
    formList[listIndex].selectedValue = formList[listIndex].options?[selectedIndex];
    update();
  }

  void changeSelectedCheckBoxValue(int listIndex, String value) {
    List<String> list = value.split('_');
    int index = int.parse(list[0]);
    bool status = list[1] == 'true' ? true : false;

    List<String>? selectedValue = formList[listIndex].cbSelected;

    if (selectedValue != null) {
      String? value = formList[listIndex].options?[index];
      if (status) {
        if (!selectedValue.contains(value)) {
          selectedValue.add(value!);
          formList[listIndex].cbSelected = selectedValue;
          update();
        }
      } else {
        if (selectedValue.contains(value)) {
          selectedValue.removeWhere((element) => element == value);
          formList[listIndex].cbSelected = selectedValue;
          update();
        }
      }
    } else {
      selectedValue = [];
      String? value = formList[listIndex].options?[index];
      if (status) {
        if (!selectedValue.contains(value)) {
          selectedValue.add(value!);
          formList[listIndex].cbSelected = selectedValue;
          update();
        }
      } else {
        if (selectedValue.contains(value)) {
          selectedValue.removeWhere((element) => element == value);
          formList[listIndex].cbSelected = selectedValue;
          update();
        }
      }
    }
  }

  void changeSelectedDateTimeValue(int index, BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        formList[index].selectedValue = DateConverter.estimatedDateTime(
          selectedDateTime,
        );

        formList[index].textEditingController?.text = DateConverter.estimatedDateTime(selectedDateTime);

        update();
      }
    }

    update();
  }

  void changeSelectedDateOnlyValue(int index, BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final DateTime selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      formList[index].selectedValue = DateConverter.estimatedDate(
        selectedDateTime,
      );
      formList[index].textEditingController?.text = DateConverter.estimatedDate(
        selectedDateTime,
      );
      printX(formList[index].textEditingController?.text);
      printX(formList[index].selectedValue);
      update();
    }

    update();
  }

  void changeSelectedTimeOnlyValue(int index, BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final DateTime selectedDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        pickedTime.hour,
        pickedTime.minute,
      );

      formList[index].selectedValue = DateConverter.estimatedTime(
        selectedDateTime,
      );
      formList[index].textEditingController?.text = DateConverter.estimatedTime(
        selectedDateTime,
      );
      update();
    }

    update();
  }

  void pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'doc', 'docx'],
    );

    if (result == null) return;

    formList[index].imageFile = File(result.files.single.path!);
    String fileName = result.files.single.name;
    formList[index].selectedValue = fileName;
    update();
    return;
  }
}
