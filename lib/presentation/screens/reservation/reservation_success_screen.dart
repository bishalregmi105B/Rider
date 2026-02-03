import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/model/reservation/reservation_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:intl/intl.dart';

class ReservationSuccessScreen extends StatefulWidget {
  final ReservationModel reservation;
  
  const ReservationSuccessScreen({super.key, required this.reservation});

  @override
  State<ReservationSuccessScreen> createState() => _ReservationSuccessScreenState();
}

class _ReservationSuccessScreenState extends State<ReservationSuccessScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.getScreenBgColor(),
      body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Card
                  Container(
                    decoration: BoxDecoration(
                      color: MyColor.colorWhite,
                      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: MyColor.colorBlack.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header with gradient
                        Container(
                          padding: const EdgeInsets.all(Dimensions.space30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                MyColor.primaryColor,
                                MyColor.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.cardRadius),
                              topRight: Radius.circular(Dimensions.cardRadius),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: MyColor.colorWhite,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 50,
                                  color: MyColor.primaryColor,
                                ),
                              ),
                              spaceDown(Dimensions.space15),
                              Text(
                                MyStrings.reservationConfirmed.tr,
                                style: boldOverLarge.copyWith(
                                  color: MyColor.colorWhite,
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              spaceDown(Dimensions.space10),
                              Text(
                                MyStrings.reservationSuccessMessage.tr,
                                style: regularDefault.copyWith(
                                  color: MyColor.colorWhite.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(Dimensions.space20),
                          child: Column(
                            children: [
                              // Reservation Code
                              Container(
                                padding: const EdgeInsets.all(Dimensions.space20),
                                decoration: BoxDecoration(
                                  color: MyColor.getCardBgColor(),
                                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      MyStrings.yourReservationCode.tr,
                                      style: regularDefault.copyWith(
                                        color: MyColor.bodyTextColor,
                                      ),
                                    ),
                                    spaceDown(Dimensions.space10),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        widget.reservation.reservationCode ?? 'N/A',
                                        style: boldExtraLarge.copyWith(
                                          color: MyColor.primaryColor,
                                          fontSize: 24,
                                          letterSpacing: 1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                    spaceDown(Dimensions.space5),
                                    Text(
                                      MyStrings.saveCodeReference.tr,
                                      style: regularSmall.copyWith(
                                        color: MyColor.bodyTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              spaceDown(Dimensions.space20),
                              
                              // Details Grid
                              _buildDetailsSection(),
                              
                              spaceDown(Dimensions.space20),
                              
                              // Location Info
                              _buildLocationSection(),
                              
                              spaceDown(Dimensions.space20),
                              
                              // What's Next
                              _buildWhatsNextSection(),
                              
                              spaceDown(Dimensions.space25),
                              
                              // Action Buttons
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  spaceDown(Dimensions.space20),
                  
                  // Contact Support
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: '${MyStrings.needHelp.tr} ',
                        style: regularDefault.copyWith(
                          color: MyColor.bodyTextColor,
                        ),
                        children: [
                          TextSpan(
                            text: MyStrings.contactSupport.tr,
                            style: semiBoldDefault.copyWith(
                              color: MyColor.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final reservation = widget.reservation;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: MyColor.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    MyStrings.scheduleInformation.tr,
                    style: semiBoldDefault.copyWith(
                      color: MyColor.primaryTextColor,
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space12),
              
              if (reservation.reservationType == 'recurring') ...[
                _buildDetailRow(MyStrings.type.tr, MyStrings.recurring.tr),
                _buildDetailRow(
                  MyStrings.period.tr,
                  '${DateFormat('MMM dd').format(DateTime.parse(reservation.recurringStartDate!))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(reservation.recurringEndDate!))}',
                ),
                if (reservation.recurringDays != null && reservation.recurringDays!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: reservation.recurringDays!.map((day) {
                        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dayNames[day - 1],
                            style: regularSmall.copyWith(
                              color: MyColor.colorWhite,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ] else ...[
                _buildDetailRow(
                  MyStrings.date.tr,
                  DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(reservation.reservationDate!)),
                ),
              ],
              
              _buildDetailRow(
                MyStrings.pickupTime.tr,
                reservation.pickupTime?.toString() ?? 'N/A',
              ),
              
              if (reservation.returnTime != null)
                _buildDetailRow(
                  MyStrings.returnTime.tr,
                  reservation.returnTime.toString(),
                ),
            ],
          ),
        ),
        
        const SizedBox(width: Dimensions.space15),
        
        // Trip Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, size: 18, color: MyColor.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    MyStrings.tripInformation.tr,
                    style: semiBoldDefault.copyWith(
                      color: MyColor.primaryTextColor,
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space12),
              
              _buildDetailRow(
                MyStrings.service.tr,
                reservation.service?.name ?? 'N/A',
              ),
              _buildDetailRow(
                MyStrings.tripType.tr,
                reservation.tripType?.replaceAll('_', ' ').capitalize ?? 'N/A',
              ),
              _buildDetailRow(
                MyStrings.passengers.tr,
                '${reservation.passengerCount ?? 1}',
              ),
              if (reservation.estimatedAmount != null)
                _buildDetailRow(
                  MyStrings.estimatedFare.tr,
                  reservation.estimatedAmount!,
                  valueColor: MyColor.primaryColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: regularSmall.copyWith(
                color: MyColor.bodyTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: semiBoldSmall.copyWith(
                color: valueColor ?? MyColor.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: MyColor.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.pickup.tr,
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reservation.pickupLocation ?? 'N/A',
                      style: semiBoldDefault.copyWith(
                        color: MyColor.primaryTextColor,
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
              Icon(Icons.flag, color: MyColor.secondaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.destination.tr,
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reservation.destination ?? 'N/A',
                      style: semiBoldDefault.copyWith(
                        color: MyColor.primaryTextColor,
                      ),
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

  Widget _buildWhatsNextSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade900, size: 20),
              const SizedBox(width: 8),
              Text(
                MyStrings.whatsNext.tr,
                style: semiBoldDefault.copyWith(
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space12),
          
          _buildWhatsNextItem(MyStrings.confirmationMessage.tr),
          _buildWhatsNextItem(MyStrings.driverDetailsMessage.tr),
          _buildWhatsNextItem(MyStrings.reminderMessage.tr),
          _buildWhatsNextItem(MyStrings.cancellationMessage.tr),
        ],
      ),
    );
  }

  Widget _buildWhatsNextItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: regularSmall.copyWith(
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Reservations Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Get.offAllNamed(RouteHelper.dashboard, arguments: [0]);
              // Navigate to reservations tab if you have one
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.space15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: MyColor.colorWhite),
                const SizedBox(width: 8),
                Text(
                  MyStrings.viewMyReservations.tr,
                  style: semiBoldDefault.copyWith(
                    color: MyColor.colorWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        spaceDown(Dimensions.space12),
        
        // Book Another Ride Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Get.offAllNamed(RouteHelper.dashboard, arguments: [0]);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: MyColor.primaryColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.space15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: MyColor.primaryColor),
                const SizedBox(width: 8),
                Text(
                  MyStrings.bookAnotherRide.tr,
                  style: semiBoldDefault.copyWith(
                    color: MyColor.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
