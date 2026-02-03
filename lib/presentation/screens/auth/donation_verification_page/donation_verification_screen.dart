import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/text/default_text.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/will_pop_widget.dart';

class DonationVerificationScreen extends StatefulWidget {
  const DonationVerificationScreen({super.key});

  @override
  State<DonationVerificationScreen> createState() => _DonationVerificationScreenState();
}

class _DonationVerificationScreenState extends State<DonationVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: RouteHelper.loginScreen,
      child: AnnotatedRegionWidget(
        statusBarColor: MyColor.screenBgColor,
        systemNavigationBarColor: MyColor.screenBgColor,
        child: Scaffold(
          backgroundColor: MyColor.screenBgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space15,
                vertical: Dimensions.space20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  spaceDown(Dimensions.space50),
                  Image.asset(
                    MyImages.appLogoIcon,
                    height: 80,
                    width: 80,
                  ),
                  spaceDown(Dimensions.space30),
                  HeaderText(
                    text: 'Donation Required',
                  ),
                  spaceDown(Dimensions.space15),
                  DefaultText(
                    text: 'Support our platform to continue',
                    textAlign: TextAlign.center,
                    textStyle: regularDefault.copyWith(
                      color: MyColor.bodyMutedTextColor,
                    ),
                  ),
                  spaceDown(Dimensions.space30),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space20),
                    decoration: BoxDecoration(
                      color: MyColor.getCardBgColor(),
                      borderRadius: BorderRadius.circular(Dimensions.space12),
                      boxShadow: MyUtils.getShadow(),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 60,
                          color: MyColor.getPrimaryColor(),
                        ),
                        spaceDown(Dimensions.space20),
                        DefaultText(
                          text: 'To continue using the app, please complete a one-time donation.',
                          textAlign: TextAlign.center,
                          textStyle: regularDefault.copyWith(
                            fontSize: Dimensions.fontLarge,
                          ),
                        ),
                        spaceDown(Dimensions.space15),
                        DefaultText(
                          text: 'You will be redirected to a secure donation page where you can make your contribution.',
                          textAlign: TextAlign.center,
                          textStyle: regularDefault.copyWith(
                            color: MyColor.bodyMutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceDown(Dimensions.space40),
                  RoundedButton(
                    text: 'Proceed to Donation',
                    press: () {
                      final url = '${UrlContainer.domainUrl}/donation';
                      MyUtils.launchUrlToBrowser(url);
                    },
                  ),
                  spaceDown(Dimensions.space20),
                  TextButton(
                    onPressed: () {
                      Get.offAllNamed(RouteHelper.loginScreen);
                    },
                    child: DefaultText(
                      text: 'Logout',
                      textStyle: regularDefault.copyWith(
                        color: MyColor.bodyMutedTextColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
