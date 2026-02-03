import 'dart:convert';
import 'package:ovorideuser/data/model/global/formdata/global_kyc_form_data.dart';
import 'package:ovorideuser/data/model/kyc/kyc_pending_data_model.dart';

RiderKycResponseModel riderKycResponseModelFromJson(String str) => RiderKycResponseModel.fromJson(json.decode(str));

class RiderKycResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  Data? data;

  RiderKycResponseModel({this.remark, this.status, this.message, this.data});

  factory RiderKycResponseModel.fromJson(Map<String, dynamic> json) => RiderKycResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null ? [] : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );
}

class Data {
  String? trx;
  GlobalKYCForm? form;
  List<KycPendingData>? riderData;
  String? path;

  Data({this.trx, this.form, this.riderData, this.path});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        trx: json["trx"],
        form: json["form"] == null ? null : GlobalKYCForm.fromJson(json["form"]),
        // API returns 'rider_data' for pending/verified states, 'verification_data' might also be used
        riderData: (json["rider_data"] ?? json["verification_data"]) == null
            ? []
            : List<KycPendingData>.from(
                (json["rider_data"] ?? json["verification_data"])!.map((x) => KycPendingData.fromJson(x)),
              ),
        path: (json["path"] ?? json["file_path"])?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {};
}
