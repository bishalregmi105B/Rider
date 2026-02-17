import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';

class ScheduleRideBottomSheet extends StatefulWidget {
  final Function(DateTime selectedDateTime) onScheduleSelected;
  final bool isReservation;
  final Function(Map<String, dynamic>)? onReservationCreated;

  const ScheduleRideBottomSheet({
    Key? key,
    required this.onScheduleSelected,
    this.isReservation = false,
    this.onReservationCreated,
  }) : super(key: key);

  @override
  State<ScheduleRideBottomSheet> createState() => _ScheduleRideBottomSheetState();
}

class _ScheduleRideBottomSheetState extends State<ScheduleRideBottomSheet> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String reservationType = 'one_time';
  String tripType = 'one_way';
  List<int> recurringDays = [];
  DateTime? recurringEndDate;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow for reservations, 1 hour from now for scheduled rides
    final now = DateTime.now();
    if (widget.isReservation) {
      // For reservations, default to tomorrow
      selectedDate = DateTime(now.year, now.month, now.day + 1);
      selectedTime = TimeOfDay(hour: 9, minute: 0);
    } else {
      selectedDate = DateTime(now.year, now.month, now.day);
      selectedTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(Duration(days: widget.isReservation ? 1 : 0)),
      firstDate: DateTime.now().add(Duration(days: widget.isReservation ? 1 : 0)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MyColor.primaryColor,
              onPrimary: MyColor.colorWhite,
              surface: MyColor.colorWhite,
              onSurface: MyColor.colorBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MyColor.primaryColor,
              onPrimary: MyColor.colorWhite,
              surface: MyColor.colorWhite,
              onSurface: MyColor.colorBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  DateTime? get combinedDateTime {
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  bool get isValid {
    final combined = combinedDateTime;
    if (combined == null) return false;
    return combined.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.mediumRadius),
          topRight: Radius.circular(Dimensions.mediumRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MyStrings.scheduleRide.tr,
                style: boldLarge.copyWith(fontSize: Dimensions.fontLarge),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: MyColor.colorGrey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: Dimensions.space10),

          // Subtitle
          Text(
            MyStrings.selectPickupDateTime.tr,
            style: regularDefault.copyWith(color: MyColor.colorGrey),
          ),

          SizedBox(height: Dimensions.space25),

          // Date Picker
          _buildDateTimeTile(
            icon: Icons.calendar_today,
            title: MyStrings.pickupDate.tr,
            value: selectedDate != null ? DateFormat('EEEE, MMM d, y').format(selectedDate!) : MyStrings.selectDate.tr,
            onTap: () => _selectDate(context),
          ),

          SizedBox(height: Dimensions.space15),

          // Time Picker
          _buildDateTimeTile(
            icon: Icons.access_time,
            title: MyStrings.pickupTime.tr,
            value: selectedTime != null ? selectedTime!.format(context) : MyStrings.selectTime.tr,
            onTap: () => _selectTime(context),
          ),

          SizedBox(height: Dimensions.space20),

          // Info message
          if (combinedDateTime != null)
            Container(
              padding: EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: MyColor.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                border: Border.all(color: MyColor.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: MyColor.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: Text(
                      '${MyStrings.driversWillBeNotified.tr} ${DateFormat('MMM d, y \'at\' h:mm a').format(combinedDateTime!)}',
                      style: regularSmall.copyWith(color: MyColor.primaryColor),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: Dimensions.space25),

          // Confirm Button
          RoundedButton(
            text: MyStrings.confirmSchedule.tr,
            press: isValid
                ? () {
                    widget.onScheduleSelected(combinedDateTime!);
                    Navigator.pop(context);
                  }
                : () {}, // Provide empty function for disabled state
            bgColor: isValid ? MyColor.primaryColor : MyColor.colorGrey,
            isDisabled: !isValid,
          ),

          SizedBox(height: Dimensions.space10),
        ],
      ),
    );
  }

  Widget _buildDateTimeTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
      child: Container(
        padding: EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: MyColor.screenBgColor,
          borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
          border: Border.all(color: MyColor.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.space10),
              decoration: BoxDecoration(
                color: MyColor.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              child: Icon(icon, color: MyColor.primaryColor, size: 24),
            ),
            SizedBox(width: Dimensions.space15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: regularSmall.copyWith(color: MyColor.colorGrey),
                  ),
                  SizedBox(height: Dimensions.space5),
                  Text(
                    value,
                    style: semiBoldDefault.copyWith(
                      color: selectedDate != null || selectedTime != null ? MyColor.colorBlack : MyColor.colorGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: MyColor.colorGrey),
          ],
        ),
      ),
    );
  }
}
