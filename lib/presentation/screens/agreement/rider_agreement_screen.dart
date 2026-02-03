import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RiderAgreementScreen extends StatefulWidget {
  const RiderAgreementScreen({super.key});

  @override
  State<RiderAgreementScreen> createState() => _RiderAgreementScreenState();
}

class _RiderAgreementScreenState extends State<RiderAgreementScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isSigned = false;
  bool _isLoading = true;
  String _agreementContent = '';

  // Fallback content if API fails
  static const String _fallbackContent = '''
<h3>Passenger Responsibility & Liability Waiver Agreement</h3>
<p><strong>(Volunteer Ride Program)</strong></p>
<p>By requesting or accepting a ride through Mero Rides powered by Sparsha Yatayat, I acknowledge and agree to the following:</p>

<h4>1. Volunteer Nature of the Service</h4>
<p>I understand that all rides are provided as part of a community ride service operated by volunteer drivers using their personal vehicles.</p>

<h4>2. Assumption of Risk</h4>
<p>I voluntarily accept and assume all risks associated with receiving a ride.</p>

<h4>3. Release of Liability</h4>
<p>I agree to release, waive, and hold harmless Mero Rides powered by Sparsha Yatayat and Lama Sparsha Foundation from all claims.</p>

<h4>4. Acknowledgment & Acceptance</h4>
<p>By using this service, I confirm that I have read and understood this agreement and voluntarily accept its terms.</p>
''';

  @override
  void initState() {
    super.initState();
    _loadAgreementContent();
    _controller.addListener(() {
      if (_controller.isNotEmpty != _isSigned) {
        setState(() {
          _isSigned = _controller.isNotEmpty;
        });
      }
    });
  }

  Future<void> _loadAgreementContent() async {
    try {
      final ApiClient apiClient = Get.find();
      apiClient.initToken();
      String url = '${UrlContainer.baseUrl}${UrlContainer.agreementsEndPoint}';
      final response = await apiClient.request(url, Method.getMethod, null);

      if (response.statusCode == 200 && response.responseJson['status'] == 'success') {
        final data = response.responseJson['data'];
        if (data != null && data['rider_agreement'] != null) {
          var riderAgreement = data['rider_agreement'];

          // Handle case where rider_agreement is a JSON string
          if (riderAgreement is String) {
            try {
              riderAgreement = jsonDecode(riderAgreement);
            } catch (e) {
              debugPrint('Error decoding rider_agreement JSON: $e');
            }
          }

          if (riderAgreement is Map && riderAgreement['details'] != null) {
            setState(() {
              _agreementContent = riderAgreement['details'];
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading agreement content: $e');
    }

    // Fallback to hardcoded content
    setState(() {
      _agreementContent = _fallbackContent;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.getScreenBgColor(),
      appBar: AppBar(
        title: Text(
          "Passenger Agreement",
          style: boldLarge.copyWith(color: MyColor.getTextColor()),
        ),
        backgroundColor: MyColor.getScreenBgColor(),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Before verification, please read and sign the agreement.",
                style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
              ),
              const SizedBox(height: Dimensions.space20),
              Container(
                height: 400,
                padding: const EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.colorWhite,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: MyColor.borderColor, width: 1),
                ),
                child: _isLoading
                    ? const Center(child: CustomLoader())
                    : SingleChildScrollView(
                        child: HtmlWidget(
                          _agreementContent,
                          textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                      ),
              ),
              const SizedBox(height: Dimensions.space20),
              Text("Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}", style: boldDefault),
              const SizedBox(height: Dimensions.space10),
              Text("Signature (Required)", style: boldDefault),
              const SizedBox(height: Dimensions.space10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: MyColor.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  color: Colors.white,
                ),
                child: Signature(
                  controller: _controller,
                  height: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Clear"),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space20),
              RoundedButton(
                text: "Accept and Continue",
                press: _isSigned ? () => _submitAgreement() : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAgreement() async {
    if (_controller.isEmpty) return;

    try {
      // Get signature as PNG bytes
      final signatureBytes = await _controller.toPngBytes();
      if (signatureBytes == null) return;

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final signaturePath = '${appDir.path}/rider_signature.png';

      // Save signature to file
      final file = File(signaturePath);
      await file.writeAsBytes(signatureBytes);

      // Store agreement accepted flag and signature path in SharedPreferences
      final apiClient = Get.find<ApiClient>();
      await apiClient.sharedPreferences.setBool(
        SharedPreferenceHelper.riderAgreementAcceptedKey,
        true,
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.kycSignatureFile,
        signaturePath,
      );

      // Submit agreement to API using multipart request (backend expects file upload)
      String url = '${UrlContainer.baseUrl}${UrlContainer.riderAgreementUrl}';
      final response = await apiClient.multipartRequest(
        url,
        Method.postMethod,
        {
          'agreement_signed': '1',
        },
        files: {
          'kyc_signature': file, // Backend expects 'kyc_signature' as the file field name
        },
        passHeader: true,
      );

      debugPrint('Agreement submission response: ${response.statusCode} - ${response.responseJson}');

      if (response.statusCode == 200 && response.responseJson['status'] == 'success') {
        CustomSnackBar.success(successList: ['Agreement signed successfully!']);
        // Navigate to splash screen to re-run verification flow with fresh user data
        Get.offAllNamed(RouteHelper.splashScreen);
      } else {
        // Show error but still allow proceeding if local save succeeded
        final errorMessage = response.responseJson['message'] ?? ['Could not save agreement to server'];
        CustomSnackBar.error(errorList: errorMessage is List ? errorMessage.cast<String>() : [errorMessage.toString()]);
        // Navigate to splash screen to re-run verification flow
        Get.offAllNamed(RouteHelper.splashScreen);
      }
    } catch (e) {
      debugPrint('Error submitting agreement: $e');
      Get.offAllNamed(RouteHelper.splashScreen);
    }
  }
}
