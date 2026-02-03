import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/reservation/reservation_controller.dart';
import 'package:ovorideuser/data/model/reservation/reservation_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ReservationController>().loadReservationDetail(widget.reservationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: MyStrings.reservationDetails.tr,
        isShowBackBtn: true,
      ),
      body: GetBuilder<ReservationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CustomLoader());
          }

          if (controller.selectedReservation == null) {
            return Center(
              child: Text(
                MyStrings.noDataFound.tr,
                style: regularDefault.copyWith(color: MyColor.bodyTextColor),
              ),
            );
          }

          final reservation = controller.selectedReservation!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(reservation),
                const SizedBox(height: Dimensions.space15),
                if (reservation.driver != null) ...[
                  _buildDriverInfoCard(reservation),
                  const SizedBox(height: Dimensions.space15),
                ],
                _buildServiceInfoCard(reservation),
                const SizedBox(height: Dimensions.space15),
                _buildLocationCard(reservation),
                const SizedBox(height: Dimensions.space12),
                _buildScheduleCard(reservation),
                if (reservation.isRecurring && reservation.schedules != null && reservation.schedules!.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.space12),
                  _buildScheduleInstancesCard(reservation),
                ],
                const SizedBox(height: Dimensions.space12),
                _buildBookingSummaryCard(reservation),
                const SizedBox(height: Dimensions.space12),
                _buildAdditionalInfoCard(reservation),
                if (reservation.canBeCancelled())
                  _buildCancelButton(reservation, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${reservation.reservationCode ?? ''}',
                style: semiBoldExtraLarge.copyWith(
                  color: MyColor.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space10,
                  vertical: Dimensions.space5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(reservation.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(
                  reservation.statusText,
                  style: semiBoldDefault.copyWith(
                    color: _getStatusColor(reservation.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            children: [
              Icon(
                reservation.isRecurring ? Icons.repeat : Icons.event,
                color: MyColor.bodyTextColor,
                size: 18,
              ),
              const SizedBox(width: Dimensions.space5),
              Text(
                reservation.isRecurring ? MyStrings.recurring.tr : MyStrings.oneTime.tr,
                style: regularDefault.copyWith(color: MyColor.bodyTextColor),
              ),
              const SizedBox(width: Dimensions.space15),
              Icon(
                reservation.isRoundTrip ? Icons.swap_horiz : Icons.arrow_forward,
                color: MyColor.bodyTextColor,
                size: 18,
              ),
              const SizedBox(width: Dimensions.space5),
              Text(
                reservation.isRoundTrip ? MyStrings.roundTrip.tr : MyStrings.oneWay.tr,
                style: regularDefault.copyWith(color: MyColor.bodyTextColor),
              ),
            ],
          ),
          if (reservation.estimatedAmount != null && Get.find<LocalStorageService>().canShowPrices()) ...[
            const CustomDivider(space: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MyStrings.estimatedFare.tr,
                  style: regularDefault.copyWith(color: MyColor.bodyTextColor),
                ),
                Text(
                  '\$${reservation.estimatedAmount}',
                  style: semiBoldLarge.copyWith(color: MyColor.primaryColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(ReservationModel reservation) {
    final driver = reservation.driver;
    if (driver == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.driverDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: MyImageWidget(
                  imageUrl: '${UrlContainer.domainUrl}/assets/images/driver/${driver.image}',
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullname,
                      style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
                    ),
                    const SizedBox(height: Dimensions.space5),
                    if (driver.mobile != null)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: MyColor.bodyTextColor),
                          const SizedBox(width: Dimensions.space5),
                          Text(
                            driver.mobile!,
                            style: regularDefault.copyWith(color: MyColor.bodyTextColor),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(ReservationModel reservation) {
    final service = reservation.service;
    if (service == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.serviceDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                child: MyImageWidget(
                  imageUrl: '${UrlContainer.domainUrl}/assets/admin/images/service/${service.image}',
                  height: 50,
                  width: 50,
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name ?? '',
                      style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
                    ),
                    if (service.subtitle != null)
                      Text(
                        service.subtitle!,
                        style: regularDefault.copyWith(color: MyColor.bodyTextColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.locationDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MyColor.greenSuccessColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.pickUpLocation.tr,
                      style: regularSmall.copyWith(color: MyColor.bodyTextColor),
                    ),
                    Text(
                      reservation.pickupLocation ?? '',
                      style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MyColor.redCancelTextColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.destination.tr,
                      style: regularSmall.copyWith(color: MyColor.bodyTextColor),
                    ),
                    Text(
                      reservation.destination ?? '',
                      style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.scheduleDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          if (reservation.isRecurring) ...[
            Row(
              children: [
                Icon(Icons.date_range, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Text(
                  '${_formatDate(reservation.recurringStartDate ?? '')} - ${_formatDate(reservation.recurringEndDate ?? '')}',
                  style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            Row(
              children: [
                Icon(Icons.repeat, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Text(
                  reservation.recurringDaysText,
                  style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Text(
                  _formatDate(reservation.reservationDate ?? ''),
                  style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                ),
              ],
            ),
          ],
          const SizedBox(height: Dimensions.space10),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: MyColor.bodyTextColor),
              const SizedBox(width: Dimensions.space10),
              Text(
                'Pickup: ${reservation.getPickupTimeString() ?? 'N/A'}',
                style: regularDefault.copyWith(color: MyColor.primaryTextColor),
              ),
            ],
          ),
          if (reservation.isRoundTrip && reservation.getReturnTimeString() != null) ...[
            const SizedBox(height: Dimensions.space10),
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Text(
                  'Return: ${reservation.getReturnTimeString()}',
                  style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleInstancesCard(ReservationModel reservation) {
    final schedules = reservation.schedules!.take(10).toList();
    
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyColor.primaryColor, MyColor.primaryColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_month, color: MyColor.colorWhite, size: 20),
              ),
              const SizedBox(width: Dimensions.space10),
              Text(
                'Schedule Instances',
                style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space10),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Container(
                padding: const EdgeInsets.all(Dimensions.space12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyColor.neutral50, MyColor.neutral100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MyColor.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: MyColor.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: Dimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(schedule.scheduledDate ?? ''),
                            style: semiBoldDefault.copyWith(
                              color: MyColor.primaryTextColor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${schedule.dayName} - ${schedule.scheduledPickupTime ?? 'N/A'}',
                            style: regularSmall.copyWith(
                              color: MyColor.bodyTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getScheduleStatusGradient(schedule.status),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        schedule.statusText,
                        style: regularSmall.copyWith(
                          color: MyColor.colorWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (reservation.schedules!.length > 10) ...[
            const SizedBox(height: Dimensions.space10),
            Center(
              child: Text(
                'Showing first 10 schedules of ${reservation.schedules!.length} total',
                style: regularSmall.copyWith(
                  color: MyColor.bodyTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyColor.primaryColor, MyColor.primaryColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt, color: MyColor.colorWhite, size: 20),
              ),
              const SizedBox(width: Dimensions.space10),
              Text(
                'Booking Summary',
                style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Trip Type',
                  reservation.tripType == 'round_trip' ? 'Round Trip' : 'One Way',
                  Icons.sync_alt,
                  MyColor.informationColor,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: _buildSummaryItem(
                  'Passengers',
                  '${reservation.passengerCount ?? 1}',
                  Icons.group,
                  MyColor.greenSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Distance',
                  '${reservation.estimatedDistance?.toStringAsFixed(2) ?? '0'} ${MyUtils.getDistanceLabel(distance: reservation.estimatedDistance?.toString(), unit: Get.find<ApiClient>().getDistanceUnit())}',
                  Icons.straighten,
                  MyColor.colorPurple,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: _buildSummaryItem(
                  'Duration',
                  '${(reservation.estimatedDuration?.toInt() ?? 0)} min',
                  Icons.access_time,
                  MyColor.colorOrange,
                ),
              ),
            ],
          ),
          if (reservation.estimatedAmount != null && Get.find<LocalStorageService>().canShowPrices()) ...[
            const SizedBox(height: Dimensions.space15),
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: MyColor.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Fare',
                    style: regularDefault.copyWith(
                      color: MyColor.bodyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    reservation.estimatedAmount ?? 'N/A',
                    style: semiBoldExtraLarge.copyWith(
                      color: MyColor.primaryColor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (reservation.completedOccurrences != null && reservation.isRecurring) ...[
            const SizedBox(height: Dimensions.space10),
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: MyColor.greenSuccessColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed Trips',
                    style: regularDefault.copyWith(
                      color: MyColor.bodyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${reservation.completedOccurrences} / ${reservation.totalOccurrences ?? reservation.schedules?.length ?? 0}',
                    style: semiBoldLarge.copyWith(
                      color: MyColor.greenSuccessColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: regularSmall.copyWith(
                  color: MyColor.bodyTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: semiBoldDefault.copyWith(
              color: MyColor.primaryTextColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getScheduleStatusGradient(int? status) {
    switch (status) {
      case ReservationScheduleModel.STATUS_PENDING:
        return [MyColor.colorYellow, MyColor.colorAmber];
      case ReservationScheduleModel.STATUS_RIDE_CREATED:
        return [MyColor.informationColor, MyColor.informationColor.withValues(alpha: 0.8)];
      case ReservationScheduleModel.STATUS_COMPLETED:
        return [MyColor.greenSuccessColor, MyColor.colorGreen];
      case ReservationScheduleModel.STATUS_CANCELLED:
        return [MyColor.redCancelTextColor, MyColor.colorRed];
      case ReservationScheduleModel.STATUS_SKIPPED:
        return [MyColor.colorGrey, MyColor.colorGrey2];
      default:
        return [MyColor.bodyTextColor, MyColor.bodyTextColor.withValues(alpha: 0.8)];
    }
  }

  Widget _buildAdditionalInfoCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.additionalInformation.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          if (reservation.passengerCount != null) ...[
            Row(
              children: [
                Icon(Icons.group, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Text(
                  '${MyStrings.passengerCount.tr}: ${reservation.passengerCount}',
                  style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
          ],
          if (reservation.specialRequirements != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 18, color: MyColor.bodyTextColor),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MyStrings.specialRequirements.tr,
                        style: regularSmall.copyWith(color: MyColor.bodyTextColor),
                      ),
                      Text(
                        reservation.specialRequirements!,
                        style: regularDefault.copyWith(color: MyColor.primaryTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelButton(ReservationModel reservation, ReservationController controller) {
    return RoundedButton(
      text: MyStrings.cancelReservation.tr,
      bgColor: MyColor.redCancelTextColor,
      press: () => _showCancelDialog(reservation, controller),
    );
  }

  void _showCancelDialog(ReservationModel reservation, ReservationController controller) {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text(MyStrings.cancelReservation.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(MyStrings.areYouSure.tr),
            const SizedBox(height: Dimensions.space15),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: MyStrings.reason.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(MyStrings.no.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                Get.back();
                final success = await controller.cancelReservation(
                  reservation.id!,
                  reasonController.text,
                );
                if (success) {
                  Get.back();
                  CustomSnackBar.success(successList: [MyStrings.reservationCancelledSuccessfully.tr]);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.redCancelTextColor,
            ),
            child: Text(MyStrings.yes.tr),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int? status) {
    if (status == null) return MyColor.bodyTextColor;
    switch (status) {
      case ReservationModel.STATUS_PENDING:
        return MyColor.colorYellow;
      case ReservationModel.STATUS_CONFIRMED:
      case ReservationModel.STATUS_DRIVER_ASSIGNED:
        return MyColor.greenSuccessColor;
      case ReservationModel.STATUS_CANCELLED:
        return MyColor.redCancelTextColor;
      case ReservationModel.STATUS_COMPLETED:
        return MyColor.informationColor;
      default:
        return MyColor.bodyTextColor;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
