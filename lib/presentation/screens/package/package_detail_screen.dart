import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/model/package/package_model.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/card/app_body_card.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';

class PackageDetailScreen extends StatelessWidget {
  final UserPackageModel userPackage;
  final String packageImagePath;
  final String driverImagePath;
  final String serviceImagePath;

  const PackageDetailScreen({
    super.key,
    required this.userPackage,
    required this.packageImagePath,
    required this.driverImagePath,
    required this.serviceImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final package = userPackage.package;

    return AnnotatedRegionWidget(
      child: Scaffold(
        backgroundColor: MyColor.secondaryScreenBgColor,
        appBar: CustomAppBar(
          title: package?.name ?? 'Package Details',
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: Dimensions.screenPaddingHV,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Image  
              if (package?.image != null && package!.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  child: MyImageWidget(
                    imageUrl: '$packageImagePath/${package.image}',
                    height: 180,
                    width: double.infinity,
                    boxFit: BoxFit.cover,
                  ),
                ),
              if (package?.image != null) spaceDown(Dimensions.space15),
              
              AppBodyWidgetCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Package Name & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          package?.name ?? '',
                          style: boldLarge.copyWith(
                            fontSize: 24,
                            color: MyColor.getHeadingTextColor(),
                          ),
                        ),
                      ),
                      _buildStatusBadge(userPackage.status),
                    ],
                  ),
                  spaceDown(Dimensions.space10),

                  // Description
                  if (package?.description != null)
                    Text(
                      package!.description!,
                      style: regularDefault.copyWith(
                        color: MyColor.bodyMutedTextColor,
                      ),
                    ),

                  spaceDown(Dimensions.space20),

                  // Package Info
                  _buildInfoCard(),

                  spaceDown(Dimensions.space20),

                    // Trip Type & Schedule Info
                    if (userPackage.tripType != null || 
                        userPackage.selectedDays != null || 
                        userPackage.selectedTimeSlots != null ||
                        userPackage.scheduleStartDate != null)
                      _buildScheduleInfo(),
                  ],
                ),
              ),

              // Weekly Schedule Section
              _buildWeeklyScheduleSection(),
              
              spaceDown(Dimensions.space15),
              // Driver Info
              if (userPackage.driver != null) ...[_buildDriverCard(), spaceDown(Dimensions.space15)],

              // Route Info (if fixed location)
              if (package?.hasFixedLocations ?? false) ...[_buildRouteCard(), spaceDown(Dimensions.space15)],

              // Auto-Start Info Message
              if (userPackage.status == 1 && 
                  (userPackage.remainingRides ?? 0) > 0) ...[_buildAutoStartInfo(), spaceDown(Dimensions.space15)],

              // No Driver Warning
              if (userPackage.status == 1 && userPackage.driver == null) ...[_buildNoDriverWarning(), spaceDown(Dimensions.space15)],
          ],
        ),
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
      default:
        statusText = MyStrings.cancelled.tr;
        statusColor = MyColor.colorGrey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space12,
        vertical: Dimensions.space8,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: regularDefault.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final package = userPackage.package;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          children: [
            _buildInfoRow(Icons.check_circle, MyStrings.used.tr, 
                '${userPackage.usedRides}', MyColor.greenSuccessColor),
            Divider(),
            _buildInfoRow(Icons.pending, MyStrings.remaining.tr,
                '${userPackage.remainingRides ?? 0}', MyColor.getPrimaryColor()),
            Divider(),
            _buildInfoRow(Icons.calendar_today, MyStrings.expiresOn.tr,
                userPackage.expireDate, MyColor.colorGrey),
            Divider(),
            _buildInfoRow(Icons.attach_money, MyStrings.amountPaid.tr,
                userPackage.amountPaid ?? '0', MyColor.colorGrey),
            // Show dynamic pricing indicator if applicable
            if (package?.hasDynamicPricing == true) ...[
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.space8),
                child: Row(
                  children: [
                    Icon(Icons.calculate, color: MyColor.colorOrange, size: 24),
                    spaceSide(Dimensions.space12),
                    Expanded(
                      child: Text(
                        'Dynamic Pricing Applied',
                        style: regularDefault.copyWith(
                          fontWeight: FontWeight.w500,
                          color: MyColor.colorOrange,
                        ),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.space8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          spaceSide(Dimensions.space12),
          Expanded(
            child: Text(
              label,
              style: regularDefault.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: boldDefault.copyWith(color: MyColor.getHeadingTextColor()),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: MyColor.getPrimaryColor(), size: 24),
                spaceSide(Dimensions.space10),
                Text(
                  'Schedule Information',
                  style: boldLarge.copyWith(
                    fontSize: 18,
                    color: MyColor.getHeadingTextColor(),
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space15),

            // Trip Type
            if (userPackage.tripType != null) ...[
              Row(
                children: [
                  Icon(
                    userPackage.isTwoWay ? Icons.swap_horiz : Icons.arrow_forward,
                    color: userPackage.isTwoWay ? MyColor.greenSuccessColor : MyColor.primaryColor,
                    size: 20,
                  ),
                  spaceSide(Dimensions.space8),
                  Text(
                    'Trip Type:',
                    style: regularDefault.copyWith(color: MyColor.bodyMutedTextColor),
                  ),
                  spaceSide(Dimensions.space8),
                  Text(
                    userPackage.tripTypeName,
                    style: boldDefault.copyWith(
                      color: userPackage.isTwoWay ? MyColor.greenSuccessColor : MyColor.primaryColor,
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space12),
            ],

            // Selected Days
            if (userPackage.selectedDays != null && userPackage.selectedDays!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_today, color: MyColor.colorGrey, size: 20),
                  spaceSide(Dimensions.space8),
                  Text(
                    'Days:',
                    style: regularDefault.copyWith(color: MyColor.bodyMutedTextColor),
                  ),
                  spaceSide(Dimensions.space8),
                  Expanded(
                    child: Text(
                      userPackage.selectedDaysString,
                      style: boldDefault.copyWith(color: MyColor.getHeadingTextColor()),
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space12),
            ],

            // Selected Time Slots
            if (userPackage.selectedTimeSlots != null && userPackage.selectedTimeSlots!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.access_time, color: MyColor.colorGrey, size: 20),
                  spaceSide(Dimensions.space8),
                  Text(
                    'Time Slots:',
                    style: regularDefault.copyWith(color: MyColor.bodyMutedTextColor),
                  ),
                  spaceSide(Dimensions.space8),
                  Text(
                    userPackage.selectedTimeSlotsString,
                    style: boldDefault.copyWith(color: MyColor.getHeadingTextColor()),
                  ),
                ],
              ),
              spaceDown(Dimensions.space12),
            ],

            // Schedule Start Date
            if (userPackage.scheduleStartDate != null) ...[
              Row(
                children: [
                  Icon(Icons.event_available, color: MyColor.colorGrey, size: 20),
                  spaceSide(Dimensions.space8),
                  Text(
                    'Start Date:',
                    style: regularDefault.copyWith(color: MyColor.bodyMutedTextColor),
                  ),
                  spaceSide(Dimensions.space8),
                  Text(
                    userPackage.scheduleStartDate!,
                    style: boldDefault.copyWith(color: MyColor.getHeadingTextColor()),
                  ),
                ],
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleSection() {
    if (userPackage.schedules == null || userPackage.schedules!.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spaceDown(Dimensions.space20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Schedule (${userPackage.schedules!.length} rides)',
                style: boldDefault.copyWith(
                  fontSize: 18,
                  color: MyColor.getHeadingTextColor(),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.space10,
                  vertical: Dimensions.space5,
                ),
                decoration: BoxDecoration(
                  color: MyColor.getPrimaryColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                ),
                child: Text(
                  '${userPackage.schedules!.where((s) => s.status == 1).length} completed',
                  style: regularDefault.copyWith(
                    fontSize: Dimensions.fontSmall,
                    color: MyColor.getPrimaryColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        spaceDown(Dimensions.space15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
          child: Column(
            children: _buildGroupedSchedules(userPackage.schedules!),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedSchedules(List<UserPackageScheduleModel> schedules) {
    // Group by day
    final Map<String, List<UserPackageScheduleModel>> groupedByDay = {};
    for (var schedule in schedules) {
      final day = schedule.dayName ?? 'Unknown';
      if (!groupedByDay.containsKey(day)) {
        groupedByDay[day] = [];
      }
      groupedByDay[day]!.add(schedule);
    }

    List<Widget> widgets = [];
    
    groupedByDay.forEach((day, daySchedules) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: Dimensions.space12),
          decoration: BoxDecoration(
            color: MyColor.neutral100,
            borderRadius: BorderRadius.circular(Dimensions.largeRadius),
            border: Border.all(color: MyColor.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.space12),
                decoration: BoxDecoration(
                  color: MyColor.getPrimaryColor().withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.largeRadius),
                    topRight: Radius.circular(Dimensions.largeRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: MyColor.getPrimaryColor()),
                    spaceSide(Dimensions.space8),
                    Text(
                      day,
                      style: boldDefault.copyWith(
                        fontSize: 16,
                        color: MyColor.getHeadingTextColor(),
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${daySchedules.length} ${daySchedules.length == 1 ? 'slot' : 'slots'}',
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.bodyMutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...daySchedules.map((schedule) => _buildScheduleItem(schedule)),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  Widget _buildScheduleItem(UserPackageScheduleModel schedule) {
    Color statusColor = schedule.isCompleted ? MyColor.greenSuccessColor : MyColor.colorGrey;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.space12,
        vertical: Dimensions.space8,
      ),
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: schedule.isMorning 
              ? MyColor.primaryColor.withValues(alpha: 0.3)
              : MyColor.colorOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                schedule.isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                size: 16,
                color: schedule.isMorning ? MyColor.primaryColor : MyColor.colorOrange,
              ),
              spaceSide(Dimensions.space5),
              Text(
                '${schedule.timeSlot?.toUpperCase()}',
                style: boldDefault.copyWith(
                  fontSize: 14,
                  color: MyColor.getHeadingTextColor(),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.space8,
                  vertical: Dimensions.space3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                ),
                child: Text(
                  schedule.statusText,
                  style: regularDefault.copyWith(
                    fontSize: Dimensions.fontExtraSmall,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: MyColor.greenSuccessColor),
              spaceSide(Dimensions.space5),
              Expanded(
                child: Text(
                  schedule.pickupLocation ?? 'N/A',
                  style: regularSmall.copyWith(color: MyColor.bodyMutedTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (schedule.pickupTime != null)
                Text(
                  schedule.pickupTime!,
                  style: boldSmall.copyWith(color: MyColor.getHeadingTextColor()),
                ),
            ],
          ),
          spaceDown(Dimensions.space5),
          Row(
            children: [
              Icon(Icons.flag, size: 14, color: MyColor.colorRed),
              spaceSide(Dimensions.space5),
              Expanded(
                child: Text(
                  schedule.dropLocation ?? 'N/A',
                  style: regularSmall.copyWith(color: MyColor.bodyMutedTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (schedule.dropTime != null)
                Text(
                  schedule.dropTime!,
                  style: boldSmall.copyWith(color: MyColor.getHeadingTextColor()),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Row(
          children: [
            if (userPackage.driver?.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: MyImageWidget(
                  imageUrl: '$driverImagePath/${userPackage.driver!.image}',
                  width: 60,
                  height: 60,
                  boxFit: BoxFit.cover,
                  isProfile: true,
                ),
              ),
            spaceSide(Dimensions.space15),
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
                  spaceDown(Dimensions.space5),
                  Text(
                    '${userPackage.driver?.firstname ?? ''} ${userPackage.driver?.lastname ?? ''}',
                    style: boldDefault.copyWith(
                      fontSize: Dimensions.fontLarge,
                      color: MyColor.getHeadingTextColor(),
                    ),
                  ),
                  if (userPackage.driver?.mobile != null)
                    Text(
                      userPackage.driver!.mobile!,
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.bodyMutedTextColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fixed Route',
              style: boldLarge.copyWith(
                fontSize: Dimensions.fontOverLarge,
                color: MyColor.getHeadingTextColor(),
              ),
            ),
            spaceDown(Dimensions.space15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: MyColor.getPrimaryColor()),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From', style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.bodyMutedTextColor,
                      )),
                      Text(
                        userPackage.package?.startLocation ?? '',
                        style: regularDefault.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag, color: MyColor.colorRed),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To', style: regularDefault.copyWith(
                        fontSize: Dimensions.fontSmall,
                        color: MyColor.bodyMutedTextColor,
                      )),
                      Text(
                        userPackage.package?.endLocation ?? '',
                        style: regularDefault.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoStartInfo() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(color: MyColor.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: MyColor.primaryColor),
          spaceSide(Dimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rides Start Automatically',
                  style: semiBoldDefault.copyWith(
                    color: MyColor.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                spaceDown(Dimensions.space5),
                Text(
                  'Your scheduled rides will start automatically at their designated times. You\'ll receive notifications when each ride begins.',
                  style: regularSmall.copyWith(
                    color: MyColor.getTextColor(),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriverWarning() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(color: MyColor.colorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: MyColor.colorRed),
          spaceSide(Dimensions.space12),
          Expanded(
            child: Text(
              'No driver assigned yet. Please contact support.',
              style: regularDefault.copyWith(color: MyColor.colorRed),
            ),
          ),
        ],
      ),
    );
  }

}
