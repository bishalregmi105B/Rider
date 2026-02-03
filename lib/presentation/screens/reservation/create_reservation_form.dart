import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/reservation/reservation_controller.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/model/location/selected_location_info.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/screens/reservation/reservation_success_screen.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/core/route/route.dart';

class CreateReservationForm extends StatefulWidget {
  const CreateReservationForm({super.key});

  @override
  State<CreateReservationForm> createState() => _CreateReservationFormState();
}

class _CreateReservationFormState extends State<CreateReservationForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _passengerCountController = TextEditingController(text: '1');
  final TextEditingController _specialRequirementsController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  
  // Location data from HomeController
  SelectedLocationInfo? _pickupLocation;
  SelectedLocationInfo? _destinationLocation;
  int? _selectedServiceId;
  
  // Date and Time
  DateTime? _selectedDate;
  TimeOfDay? _selectedPickupTime;
  TimeOfDay? _selectedReturnTime;
  DateTime? _recurringStartDate;
  DateTime? _recurringEndDate;
  
  // Booking Type
  String _reservationType = 'one_time';
  String _tripType = 'one_way';
  bool _isRecurring = false;
  bool _isRoundTrip = false;
  
  // Recurring Days
  final List<int> _selectedDays = [];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Service Selection
  // int? _selectedServiceId; // Not used currently
  
  @override
  void initState() {
    super.initState();
    
    // Get data from HomeController if available
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      
      // Pre-fill locations if available
      if (homeController.selectedLocations.isNotEmpty) {
        if (homeController.selectedLocations.length > 0) {
          _pickupLocation = homeController.selectedLocations[0];
          _pickupLocationController.text = _pickupLocation?.fullAddress ?? '';
        }
        if (homeController.selectedLocations.length > 1) {
          _destinationLocation = homeController.selectedLocations[1];
          _destinationController.text = _destinationLocation?.fullAddress ?? '';
        }
      }
      
      // Pre-select service if available
      if (homeController.selectedService.id != '-99' && homeController.selectedService.id != null) {
        _selectedServiceId = int.tryParse(homeController.selectedService.id.toString());
      }
    }
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _passengerCountController.dispose();
    _specialRequirementsController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: MyStrings.createReservation.tr,
        isShowBackBtn: true,
      ),
      body: GetBuilder<ReservationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CustomLoader());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReservationTypeSection(),
                  const SizedBox(height: Dimensions.space20),
                  _buildDateTimeSection(),
                  const SizedBox(height: Dimensions.space20),
                  _buildServiceSelectionSection(),
                  const SizedBox(height: Dimensions.space20),
                  _buildLocationSection(),
                  const SizedBox(height: Dimensions.space20),
                  _buildPassengerDetailsSection(),
                  const SizedBox(height: Dimensions.space20),
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: Dimensions.space30),
                  _buildSubmitButton(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservationTypeSection() {
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
            MyStrings.reservationType.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(MyStrings.oneTime.tr),
                  value: 'one_time',
                  groupValue: _reservationType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _reservationType = value!;
                      _isRecurring = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(MyStrings.recurring.tr),
                  value: 'recurring',
                  groupValue: _reservationType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _reservationType = value!;
                      _isRecurring = true;
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(MyStrings.oneWay.tr),
                  value: 'one_way',
                  groupValue: _tripType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _tripType = value!;
                      _isRoundTrip = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(MyStrings.roundTrip.tr),
                  value: 'round_trip',
                  groupValue: _tripType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _tripType = value!;
                      _isRoundTrip = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
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
          
          if (!_isRecurring) ...[
            // One-time reservation date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: MyColor.primaryColor),
              title: Text(_selectedDate == null 
                  ? MyStrings.selectDate.tr 
                  : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)),
              onTap: () => _selectDate(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: MyColor.primaryColor),
              title: Text(_selectedPickupTime == null 
                  ? MyStrings.selectPickupTime.tr 
                  : 'Pickup: ${_selectedPickupTime!.format(context)}'),
              onTap: () => _selectTime(context, true),
            ),
            if (_isRoundTrip) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time_filled, color: MyColor.primaryColor),
                title: Text(_selectedReturnTime == null 
                    ? MyStrings.selectReturnTime.tr 
                    : 'Return: ${_selectedReturnTime!.format(context)}'),
                onTap: () => _selectTime(context, false),
              ),
            ],
          ] else ...[
            // Recurring reservation
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.date_range, color: MyColor.primaryColor),
              title: Text(_recurringStartDate == null 
                  ? MyStrings.selectStartDate.tr 
                  : 'Start: ${DateFormat('MMM d, yyyy').format(_recurringStartDate!)}'),
              onTap: () => _selectRecurringDate(context, true),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.date_range, color: MyColor.primaryColor),
              title: Text(_recurringEndDate == null 
                  ? MyStrings.selectEndDate.tr 
                  : 'End: ${DateFormat('MMM d, yyyy').format(_recurringEndDate!)}'),
              onTap: () => _selectRecurringDate(context, false),
            ),
            const Divider(),
            Text(
              MyStrings.selectDays.tr,
              style: regularDefault.copyWith(color: MyColor.bodyTextColor),
            ),
            const SizedBox(height: Dimensions.space10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_weekDays.length, (index) {
                final dayNumber = index + 1;
                final isSelected = _selectedDays.contains(dayNumber);
                return FilterChip(
                  label: Text(_weekDays[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(dayNumber);
                      } else {
                        _selectedDays.remove(dayNumber);
                      }
                    });
                  },
                  selectedColor: MyColor.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: MyColor.primaryColor,
                );
              }),
            ),
            const SizedBox(height: Dimensions.space15),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: MyColor.primaryColor),
              title: Text(_selectedPickupTime == null 
                  ? MyStrings.selectPickupTime.tr 
                  : 'Daily Pickup: ${_selectedPickupTime!.format(context)}'),
              onTap: () => _selectTime(context, true),
            ),
            if (_isRoundTrip) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time_filled, color: MyColor.primaryColor),
                title: Text(_selectedReturnTime == null 
                    ? MyStrings.selectReturnTime.tr 
                    : 'Daily Return: ${_selectedReturnTime!.format(context)}'),
                onTap: () => _selectTime(context, false),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
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
          InkWell(
            onTap: () {
              // Navigate to location picker for pickup
              Get.toNamed(
                RouteHelper.locationPickUpScreen,
                arguments: [0],  // Index 0 for pickup
              )?.then((v) {
                // Location picker saves to HomeController, retrieve it from there
                if (Get.isRegistered<HomeController>()) {
                  final homeController = Get.find<HomeController>();
                  if (homeController.selectedLocations.isNotEmpty) {
                    setState(() {
                      _pickupLocation = homeController.selectedLocations[0];
                      _pickupLocationController.text = _pickupLocation?.fullAddress ?? '';
                    });
                  }
                }
              });
            },
            child: AbsorbPointer(
              child: CustomTextField(
                controller: _pickupLocationController,
                labelText: MyStrings.pickUpLocation.tr,
                hintText: MyStrings.enterPickupLocation.tr,
                prefixIcon: Icon(Icons.location_on, color: MyColor.primaryColor),
                suffixWidget: Icon(Icons.arrow_forward_ios, size: 16, color: MyColor.bodyTextColor),
                onChanged: (value) {},
                validator: (value) {
                  if (value == null || value.isEmpty || _pickupLocation == null) {
                    return MyStrings.pleaseEnterPickupLocation.tr;
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: Dimensions.space15),
          InkWell(
            onTap: () {
              // Navigate to location picker for destination
              Get.toNamed(
                RouteHelper.locationPickUpScreen,
                arguments: [1],  // Index 1 for destination
              )?.then((v) {
                // Location picker saves to HomeController, retrieve it from there
                if (Get.isRegistered<HomeController>()) {
                  final homeController = Get.find<HomeController>();
                  if (homeController.selectedLocations.length > 1) {
                    setState(() {
                      _destinationLocation = homeController.selectedLocations[1];
                      _destinationController.text = _destinationLocation?.fullAddress ?? '';
                    });
                  }
                }
              });
            },
            child: AbsorbPointer(
              child: CustomTextField(
                controller: _destinationController,
                labelText: MyStrings.destination.tr,
                hintText: MyStrings.enterDestination.tr,
                prefixIcon: Icon(Icons.flag, color: MyColor.primaryColor),
                suffixWidget: Icon(Icons.arrow_forward_ios, size: 16, color: MyColor.bodyTextColor),
                onChanged: (value) {},
                validator: (value) {
                  if (value == null || value.isEmpty || _destinationLocation == null) {
                    return MyStrings.pleaseEnterDestination.tr;
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetailsSection() {
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
            MyStrings.passengerDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          CustomTextField(
            controller: _passengerCountController,
            labelText: MyStrings.passengerCount.tr,
            hintText: '1',
            prefixIcon: Icon(Icons.group, color: MyColor.primaryColor),
            textInputType: TextInputType.number,
            onChanged: (value) {},
            validator: (value) {
              if (value == null || value.isEmpty) {
                return MyStrings.pleaseEnterPassengerCount.tr;
              }
              final count = int.tryParse(value);
              if (count == null || count < 1) {
                return MyStrings.invalidPassengerCount.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: Dimensions.space15),
          CustomTextField(
            controller: _contactNumberController,
            labelText: MyStrings.contactNumber.tr,
            hintText: MyStrings.enterContactNumber.tr,
            prefixIcon: Icon(Icons.phone, color: MyColor.primaryColor),
            textInputType: TextInputType.phone,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
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
          CustomTextField(
            controller: _specialRequirementsController,
            labelText: MyStrings.specialRequirements.tr,
            hintText: MyStrings.enterSpecialRequirements.tr,
            maxLines: 3,
            prefixIcon: Icon(Icons.note, color: MyColor.primaryColor),
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ReservationController controller) {
    return RoundedButton(
      text: MyStrings.createReservation.tr,
      press: () => _submitForm(controller),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectRecurringDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? DateTime.now().add(const Duration(days: 1))
          : (_recurringStartDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: isStartDate 
          ? DateTime.now()
          : (_recurringStartDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _recurringStartDate = picked;
        } else {
          _recurringEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup 
          ? (_selectedPickupTime ?? TimeOfDay.now())
          : (_selectedReturnTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _selectedPickupTime = picked;
        } else {
          _selectedReturnTime = picked;
        }
      });
    }
  }

  void _submitForm(ReservationController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate service selection
    if (_selectedServiceId == null) {
      CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService.tr]);
      return;
    }
    
    // Validate locations
    if (_pickupLocation == null) {
      CustomSnackBar.error(errorList: [MyStrings.pleaseEnterPickupLocation.tr]);
      return;
    }
    
    if (_destinationLocation == null) {
      CustomSnackBar.error(errorList: [MyStrings.pleaseEnterDestination.tr]);
      return;
    }

    // Validate date and time selection
    if (_isRecurring) {
      if (_recurringStartDate == null || _recurringEndDate == null) {
        CustomSnackBar.error(errorList: [MyStrings.pleaseSelectDates.tr]);
        return;
      }
      if (_selectedDays.isEmpty) {
        CustomSnackBar.error(errorList: [MyStrings.pleaseSelectDays.tr]);
        return;
      }
    } else {
      if (_selectedDate == null) {
        CustomSnackBar.error(errorList: [MyStrings.pleaseSelectDate.tr]);
        return;
      }
    }

    if (_selectedPickupTime == null) {
      CustomSnackBar.error(errorList: [MyStrings.pleaseSelectPickupTime.tr]);
      return;
    }

    if (_isRoundTrip && _selectedReturnTime == null) {
      CustomSnackBar.error(errorList: [MyStrings.pleaseSelectReturnTime.tr]);
      return;
    }

    // Prepare data with all required fields
    final Map<String, dynamic> data = {
      'service_id': _selectedServiceId,
      'reservation_type': _reservationType,
      'trip_type': _tripType,
      'pickup_location': _pickupLocationController.text,
      'pickup_latitude': _pickupLocation!.latitude ?? 0,
      'pickup_longitude': _pickupLocation!.longitude ?? 0,
      'destination': _destinationController.text,
      'destination_latitude': _destinationLocation!.latitude ?? 0,
      'destination_longitude': _destinationLocation!.longitude ?? 0,
      'passenger_count': int.parse(_passengerCountController.text),
      'special_requirements': _specialRequirementsController.text,
      'contact_number': _contactNumberController.text,
    };

    if (_isRecurring) {
      data['recurring_start_date'] = DateFormat('yyyy-MM-dd').format(_recurringStartDate!);
      data['recurring_end_date'] = DateFormat('yyyy-MM-dd').format(_recurringEndDate!);
      data['recurring_days'] = _selectedDays;
      data['pickup_time'] = '${_selectedPickupTime!.hour.toString().padLeft(2, '0')}:${_selectedPickupTime!.minute.toString().padLeft(2, '0')}';
      if (_isRoundTrip) {
        data['return_time'] = '${_selectedReturnTime!.hour.toString().padLeft(2, '0')}:${_selectedReturnTime!.minute.toString().padLeft(2, '0')}';
      }
    } else {
      data['reservation_date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      data['pickup_time'] = '${_selectedPickupTime!.hour.toString().padLeft(2, '0')}:${_selectedPickupTime!.minute.toString().padLeft(2, '0')}';
      if (_isRoundTrip) {
        data['return_time'] = '${_selectedReturnTime!.hour.toString().padLeft(2, '0')}:${_selectedReturnTime!.minute.toString().padLeft(2, '0')}';
      }
    }

    // Submit the form
    final success = await controller.createReservation(data);
    if (success && controller.selectedReservation != null) {
      // Navigate to success screen instead of just going back
      Get.off(
        () => ReservationSuccessScreen(reservation: controller.selectedReservation!),
      );
    }
  }
  
  Widget _buildServiceSelectionSection() {
    return GetBuilder<HomeController>(
      builder: (homeController) {
        final services = homeController.appServices;
        
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
                MyStrings.selectService.tr,
                style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
              ),
              const SizedBox(height: Dimensions.space15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
                decoration: BoxDecoration(
                  border: Border.all(color: MyColor.borderColor),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text(
                      MyStrings.selectService.tr,
                      style: regularDefault.copyWith(color: MyColor.hintTextColor),
                    ),
                    value: _selectedServiceId,
                    icon: Icon(Icons.arrow_drop_down, color: MyColor.primaryColor),
                    items: services.map((service) {
                      return DropdownMenuItem<int>(
                        value: int.tryParse(service.id.toString()),
                        child: Row(
                          children: [
                            if (service.image != null && service.image!.isNotEmpty)
                              Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.only(right: 10),
                                child: Image.network(
                                  service.image!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.directions_car, size: 20);
                                  },
                                ),
                              ),
                            Text(
                              service.name ?? '',
                              style: regularDefault.copyWith(color: MyColor.bodyTextColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceId = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
