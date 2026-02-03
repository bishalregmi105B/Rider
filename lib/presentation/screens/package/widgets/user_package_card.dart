import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/package/package_model.dart';
import 'package:ovorideuser/presentation/components/card/app_body_card.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';

class UserPackageCard extends StatelessWidget {
  final UserPackageModel userPackage;
  final String packageImagePath;
  final String serviceImagePath;
  final String driverImagePath;
  final VoidCallback? onTap;

  const UserPackageCard({
    super.key,
    required this.userPackage,
    required this.packageImagePath,
    required this.serviceImagePath,
    required this.driverImagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final package = userPackage.package;
    
    return GestureDetector(
      onTap: onTap,
      child: AppBodyWidgetCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge at top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package Name
                      Text(
                        package?.name ?? '',
                        style: boldLarge.copyWith(
                          fontSize: Dimensions.fontOverLarge,
                          color: MyColor.getTextColor(),
                        ),
                      ),
                      if (package?.description != null && package!.description!.isNotEmpty) ...[
                        spaceDown(Dimensions.space5),
                        Text(
                          package.description!,
                          style: regularDefault.copyWith(
                            fontSize: Dimensions.fontSmall,
                            color: MyColor.bodyMutedTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(userPackage.status),
              ],
            ),
            spaceDown(Dimensions.space12),
            
            // Usage Information
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: MyColor.screenBgColor,
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      label: MyStrings.used.tr,
                      value: '${userPackage.usedRides}',
                      color: MyColor.greenSuccessColor,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: MyColor.borderColor,
                  ),
                  spaceSide(Dimensions.space10),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.pending_outlined,
                      label: MyStrings.remaining.tr,
                      value: '${userPackage.remainingRides ?? 0}',
                      color: MyColor.getPrimaryColor(),
                    ),
                  ),
                ],
              ),
            ),
            spaceDown(Dimensions.space12),
                  
            // Validity Information
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: MyColor.bodyMutedTextColor),
                spaceSide(Dimensions.space8),
                Text(
                  '${MyStrings.expiresOn.tr}: ${userPackage.expireDate}',
                  style: regularDefault.copyWith(
                    fontSize: Dimensions.fontDefault,
                    color: MyColor.getBodyTextColor(),
                  ),
                ),
              ],
            ),
            
            // Schedule Information (if available)
            if (userPackage.selectedDays != null && userPackage.selectedDays!.isNotEmpty) ...[
              spaceDown(Dimensions.space12),
              const CustomDivider(space: Dimensions.space12),
              // Trip Type
              if (userPackage.tripType != null) ...[
                Row(
                  children: [
                    Icon(
                      userPackage.isTwoWay ? Icons.swap_horiz : Icons.arrow_forward,
                      size: 18,
                      color: userPackage.isTwoWay ? MyColor.greenSuccessColor : MyColor.primaryColor,
                    ),
                    spaceSide(Dimensions.space8),
                    Text(
                      userPackage.tripTypeName,
                      style: boldDefault.copyWith(
                        fontSize: Dimensions.fontDefault,
                        color: MyColor.getHeadingTextColor(),
                      ),
                    ),
                  ],
                ),
                spaceDown(Dimensions.space8),
              ],
              // Selected Days
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event, size: 18, color: MyColor.getPrimaryColor()),
                  spaceSide(Dimensions.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Days',
                          style: regularDefault.copyWith(
                            fontSize: Dimensions.fontSmall,
                            color: MyColor.bodyMutedTextColor,
                          ),
                        ),
                        spaceDown(Dimensions.space3),
                        Text(
                          userPackage.selectedDaysString,
                          style: boldDefault.copyWith(
                            fontSize: Dimensions.fontDefault,
                            color: MyColor.getHeadingTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Time Slots
              if (userPackage.selectedTimeSlots != null && userPackage.selectedTimeSlots!.isNotEmpty) ...[
                spaceDown(Dimensions.space8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: MyColor.colorOrange),
                    spaceSide(Dimensions.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Slots',
                            style: regularDefault.copyWith(
                              fontSize: Dimensions.fontSmall,
                              color: MyColor.bodyMutedTextColor,
                            ),
                          ),
                          spaceDown(Dimensions.space3),
                          Text(
                            userPackage.selectedTimeSlotsString,
                            style: boldDefault.copyWith(
                              fontSize: Dimensions.fontDefault,
                              color: MyColor.getHeadingTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
            // Schedule Count
            if (userPackage.schedules != null && userPackage.schedules!.isNotEmpty) ...[
              spaceDown(Dimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space10,
                  vertical: Dimensions.space8,
                ),
                decoration: BoxDecoration(
                  color: MyColor.getPrimaryColor().withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: MyColor.getPrimaryColor()),
                    spaceSide(Dimensions.space5),
                    Text(
                      '${userPackage.schedules!.length} scheduled rides',
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.getPrimaryColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Dynamic Pricing Indicator
            if (package?.hasDynamicPricing == true) ...[
              spaceDown(Dimensions.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space10,
                  vertical: Dimensions.space8,
                ),
                decoration: BoxDecoration(
                  color: MyColor.colorOrange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calculate, size: 16, color: MyColor.colorOrange),
                    spaceSide(Dimensions.space5),
                    Text(
                      'Dynamic Pricing Applied',
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.colorOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Driver Information (if assigned)
            if (userPackage.driver != null) ...[
              spaceDown(Dimensions.space15),
              const CustomDivider(space: Dimensions.space12),
              Container(
                padding: const EdgeInsets.all(Dimensions.space12),
                decoration: BoxDecoration(
                  color: MyColor.getPrimaryColor().withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Row(
                  children: [
                    // Driver Image
                    if (userPackage.driver?.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: MyImageWidget(
                          imageUrl: '${UrlContainer.domainUrl}/$driverImagePath/${userPackage.driver!.image}',
                          width: 50,
                          height: 50,
                          boxFit: BoxFit.cover,
                          isProfile: true,
                        ),
                      ),
                    spaceSide(Dimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MyStrings.assignedDriver.tr,
                            style: regularDefault.copyWith(
                              fontSize: Dimensions.fontSmall,
                              color: MyColor.bodyMutedTextColor,
                            ),
                          ),
                          spaceDown(Dimensions.space3),
                          Text(
                            '${userPackage.driver?.firstname ?? ''} ${userPackage.driver?.lastname ?? ''}',
                            style: boldDefault.copyWith(
                              fontSize: Dimensions.fontDefault,
                              fontWeight: FontWeight.w600,
                              color: MyColor.getHeadingTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int? status) {
    String statusText;
    Color statusColor;
    
    switch (status) {
      case 1:
        statusText = MyStrings.active.tr;
        statusColor = MyColor.greenSuccessColor;
        break;
      case 2:
        statusText = MyStrings.completed.tr;
        statusColor = MyColor.getPrimaryColor();
        break;
      case 3:
        statusText = MyStrings.expired.tr;
        statusColor = MyColor.colorRed;
        break;
      case 0:
      default:
        statusText = MyStrings.cancelled.tr;
        statusColor = MyColor.colorGrey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space5,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: regularDefault.copyWith(
          fontSize: Dimensions.fontSmall,
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        spaceDown(Dimensions.space5),
        Text(
          value,
          style: boldLarge.copyWith(
            fontSize: Dimensions.fontLarge,
            fontWeight: FontWeight.w700,
            color: MyColor.getHeadingTextColor(),
          ),
        ),
        spaceDown(Dimensions.space3),
        Text(
          label,
          style: regularDefault.copyWith(
            fontSize: Dimensions.fontSmall,
            color: MyColor.bodyMutedTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}