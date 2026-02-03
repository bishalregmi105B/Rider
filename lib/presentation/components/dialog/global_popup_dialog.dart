import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';

class GlobalPopupDialog extends StatelessWidget {
  final PopupSettings popup;
  const GlobalPopupDialog({super.key, required this.popup});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((popup.imageUrl ?? '').isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      popup.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: MyColor.getCardBgColor(),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                              color: MyColor.getPrimaryColor(),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  popup.title ?? MyStrings.appName,
                                  style: semiBoldExtraLarge.copyWith(color: MyColor.colorBlack),
                                ),
                                if ((popup.subtitle ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: Dimensions.space5),
                                    child: Text(
                                      popup.subtitle!,
                                      style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            color: MyColor.getBodyTextColor(),
                          ),
                        ],
                      ),
                      if ((popup.message ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: Dimensions.space12),
                          child: Text(
                            popup.message!,
                            style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                          ),
                        ),
                      const SizedBox(height: Dimensions.space20),
                      Row(
                        children: [
                          Expanded(
                            child: RoundedButton(
                              text: MyStrings.close.tr,
                              press: () => Navigator.pop(context),
                              bgColor: MyColor.getPrimaryColor(),
                              textStyle: semiBoldDefault.copyWith(color: MyColor.colorWhite),
                            ),
                          ),
                          if ((popup.buttonText ?? '').isNotEmpty && (popup.buttonUrl ?? '').isNotEmpty) ...[
                            const SizedBox(width: Dimensions.space10),
                            Expanded(
                              child: RoundedButton(
                                text: popup.buttonText ?? MyStrings.learnMore.tr,
                                press: () {
                                  MyUtils.launchUrlToBrowser(popup.buttonUrl ?? '');
                                  Navigator.pop(context);
                                },
                                bgColor: MyColor.primaryColor.withOpacity(.85),
                                textStyle: semiBoldDefault.copyWith(color: MyColor.colorWhite),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
