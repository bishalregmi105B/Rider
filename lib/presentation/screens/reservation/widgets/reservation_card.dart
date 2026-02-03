import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/reservation/reservation_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final String serviceImagePath;
  final String driverImagePath;

  const ReservationCard({
    Key? key,
    required this.reservation,
    required this.serviceImagePath,
    required this.driverImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RouteHelper.reservationDetailScreen,
          arguments: reservation.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.space12),
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
          boxShadow: [
            BoxShadow(
              color: MyColor.colorBlack.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reservation Code & Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.reservationCode ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reservation.statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                        if (reservation.isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MyColor.colorPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync,
                                  size: 12,
                                  color: MyColor.colorPurple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  MyStrings.recurring.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: MyColor.colorPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Date & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getDateText(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reservation.getPickupTimeString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                    if (reservation.tripType == 'round_trip' && reservation.getReturnTimeString() != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Return: ${reservation.getReturnTimeString()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: MyColor.colorOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: Dimensions.space12),
            const Divider(height: 1),
            const SizedBox(height: Dimensions.space12),

            // Location Info
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MyColor.greenSuccessColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: MyColor.borderColor,
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MyColor.redCancelTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.pickupLocation ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reservation.destination ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.space12),
            const Divider(height: 1),
            const SizedBox(height: Dimensions.space12),

            // Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Service & Driver Info
                Row(
                  children: [
                    if (reservation.service != null) ...[
                      // Service Icon
                      if (reservation.service!.image != null)
                        MyImageWidget(
                          imageUrl: "${UrlContainer.domainUrl}/$serviceImagePath${reservation.service!.image}",
                          height: 24,
                          width: 24,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        reservation.service!.name ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                    ],
                    if (reservation.driver != null) ...[
                      const SizedBox(width: Dimensions.space10),
                      Container(
                        width: 1,
                        height: 16,
                        color: MyColor.borderColor,
                      ),
                      const SizedBox(width: Dimensions.space10),
                      // Driver Info
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MyColor.borderColor,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: reservation.driver!.image != null
                                  ? MyImageWidget(
                                      imageUrl: "${UrlContainer.domainUrl}/$driverImagePath${reservation.driver!.image}",
                                      height: 24,
                                      width: 24,
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 16,
                                      color: MyColor.bodyTextColor,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reservation.driver!.fullname,
                            style: TextStyle(
                              fontSize: 12,
                              color: MyColor.bodyTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                // Amount - only show if prices can be shown
                if (reservation.estimatedAmount != null && 
                    Get.find<LocalStorageService>().canShowPrices())
                  Text(
                    '\$${reservation.estimatedAmount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyColor.primaryColor,
                    ),
                  ),
              ],
            ),

            // Additional Info for Recurring
            if (reservation.isRecurring) ...[
              const SizedBox(height: Dimensions.space10),
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  color: MyColor.screenBgColor,
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius / 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: MyColor.bodyTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.recurringDaysText,
                          style: TextStyle(
                            fontSize: 11,
                            color: MyColor.bodyTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${reservation.completedOccurrences ?? 0}/${reservation.totalOccurrences ?? 0} ${MyStrings.completed.tr}',
                      style: TextStyle(
                        fontSize: 11,
                        color: MyColor.bodyTextColor,
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

  Color _getStatusColor() {
    switch (reservation.status) {
      case ReservationModel.STATUS_PENDING:
        return MyColor.colorYellow;
      case ReservationModel.STATUS_CONFIRMED:
        return MyColor.primaryColor;
      case ReservationModel.STATUS_DRIVER_ASSIGNED:
        return MyColor.colorPurple;
      case ReservationModel.STATUS_IN_PROGRESS:
        return MyColor.primaryColor;
      case ReservationModel.STATUS_COMPLETED:
        return MyColor.greenSuccessColor;
      case ReservationModel.STATUS_CANCELLED:
        return MyColor.redCancelTextColor;
      default:
        return MyColor.bodyTextColor;
    }
  }

  String _getDateText() {
    if (reservation.isRecurring) {
      final startDate = reservation.recurringStartDate ?? '';
      final endDate = reservation.recurringEndDate ?? '';
      if (startDate.isNotEmpty && endDate.isNotEmpty) {
        // Format: Jan 01 - Feb 15
        return '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}';
      }
    }
    return _formatDate(reservation.reservationDate ?? '');
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatShortDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    } catch (e) {
      return date;
    }
  }
}
