import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/data/model/package/package_model.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/presentation/components/card/app_body_card.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:get/get.dart';

class PackageCard extends StatelessWidget {
  final PackageModel package;
  final String packageImagePath;
  final String serviceImagePath;
  final VoidCallback? onTap;
  final PackageController controller;

  const PackageCard({
    super.key,
    required this.package,
    required this.packageImagePath,
    required this.serviceImagePath,
    required this.controller,
    this.onTap,
  });

  void _handlePurchase() {
    // Launch public package purchase page in browser (like donation page)
    // User will see package details, login, confirm and complete purchase
    final url = '${UrlContainer.domainUrl}/package/show/${package.id}';
    MyUtils.launchUrlToBrowser(url);
  }

  @override
  Widget build(BuildContext context) {
    return AppBodyWidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Image
          if (package.image != null && package.image!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              child: MyImageWidget(
                imageUrl: '${UrlContainer.domainUrl}/$packageImagePath/${package.image}',
                height: 140,
                width: double.infinity,
                boxFit: BoxFit.cover,
              ),
            ),
          spaceDown(package.image != null ? Dimensions.space12 : 0),
          
          // Package Name with Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.name ?? '',
                  style: boldLarge.copyWith(
                    fontSize: Dimensions.fontOverLarge,
                    color: MyColor.getTextColor(),
                  ),
                ),
              ),
              spaceSide(Dimensions.space8),
              // Trip Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space8,
                  vertical: Dimensions.space5,
                ),
                decoration: BoxDecoration(
                  color: package.isTwoWay 
                      ? MyColor.greenSuccessColor.withValues(alpha: 0.1) 
                      : MyColor.getPrimaryColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      package.isTwoWay ? Icons.swap_horiz : Icons.arrow_forward,
                      size: 14,
                      color: package.isTwoWay 
                          ? MyColor.greenSuccessColor 
                          : MyColor.getPrimaryColor(),
                    ),
                    spaceSide(Dimensions.space5),
                    Text(
                      package.tripTypeName,
                      style: boldSmall.copyWith(
                        color: package.isTwoWay 
                            ? MyColor.greenSuccessColor 
                            : MyColor.getPrimaryColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
                  if (package.hasWeeklySchedule) ...[
                    spaceDown(Dimensions.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MyColor.colorOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: MyColor.colorOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Weekly Schedule',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MyColor.colorOrange,
                            ),
                          ),
                          if (package.allowsCustomization) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 10,
                              color: MyColor.colorOrange,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  spaceDown(Dimensions.space8),
                  
                  // Description
                  if (package.description != null && package.description!.isNotEmpty)
                    Text(
                      package.description!,
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontDefault,
                        color: MyColor.getBodyTextColor(),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  spaceDown(Dimensions.space12),
                  
          // Package Details
          Container(
            margin: const EdgeInsets.symmetric(vertical: Dimensions.space12),
            padding: const EdgeInsets.all(Dimensions.space12),
            decoration: BoxDecoration(
              color: MyColor.screenBgColor,
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            child: Row(
              children: [
                // Rides Count
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.directions_car_outlined,
                    label: MyStrings.rides.tr,
                    value: '${package.totalRides ?? 0}',
                  ),
                ),
                Container(
                  height: 35,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.space10),
                  color: MyColor.borderColor,
                ),
                // Validity
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule_outlined,
                    label: MyStrings.validity.tr,
                    value: '${package.durationDays ?? 0} ${MyStrings.days.tr}',
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(space: Dimensions.space12),
                  
                  // Price and Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price - only show if prices can be shown
                      if (Get.find<LocalStorageService>().canShowPrices()) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.hasDynamicPricing ? 'Starting from' : MyStrings.price.tr,
                              style: regularDefault.copyWith(
                                fontSize: Dimensions.fontSmall,
                                color: MyColor.bodyMutedTextColor,
                              ),
                            ),
                            spaceDown(Dimensions.space3),
                            Text(
                              '${controller.packageRepo.apiClient.getCurrency(isSymbol: true)}${StringConverter.formatNumber(package.displayPrice)}',
                              style: boldLarge.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: MyColor.getPrimaryColor(),
                              ),
                            ),
                            if (package.hasDynamicPricing) ...[
                              spaceDown(Dimensions.space3),
                              Row(
                                children: [
                                  Icon(Icons.calculate, size: 12, color: MyColor.colorOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dynamic Pricing',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: MyColor.colorOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MyStrings.priceByDriver.tr,
                              style: regularDefault.copyWith(
                                fontSize: Dimensions.fontSmall,
                                color: MyColor.bodyMutedTextColor,
                              ),
                            ),
                            spaceDown(Dimensions.space3),
                            Row(
                              children: [
                                Icon(Icons.handshake, size: 20, color: MyColor.getPrimaryColor()),
                                const SizedBox(width: 4),
                                Text(
                                  'Driver Will Set Price',
                                  style: boldDefault.copyWith(
                                    fontSize: Dimensions.fontDefault,
                                    color: MyColor.getPrimaryColor(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      
                      // Purchase Button
                      RoundedButton(
                        text: MyStrings.buyNow.tr,
                        press: _handlePurchase,
                        cornerRadius: Dimensions.defaultRadius,
                        width: 0.35,
                      ),
                    ],
                  ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: MyColor.getPrimaryColor()),
        spaceDown(Dimensions.space5),
        Text(
          value,
          style: boldDefault.copyWith(
            fontSize: Dimensions.fontLarge,
            color: MyColor.getTextColor(),
          ),
        ),
        Text(
          label,
          style: regularSmall.copyWith(
            color: MyColor.bodyMutedTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
