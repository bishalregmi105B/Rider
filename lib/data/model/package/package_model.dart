class PackageModel {
  int? id;
  String? name;
  String? description;
  String? image;
  String? price;
  int? durationDays;
  int? durationWeeks;
  int? totalRides;
  int? maxRidersPerRide;
  int? locationType;
  String? startLocation;
  String? startLatitude;
  String? startLongitude;
  String? endLocation;
  String? endLatitude;
  String? endLongitude;
  int? tripType;
  bool? hasSchedule;
  bool? allowCustomTiming;
  bool? showInHeader;
  int? status;
  List<ServiceModel>? services;
  List<PackageScheduleModel>? schedules;
  
  // Dynamic pricing fields
  bool? useDynamicPricing;
  String? basePrice;
  String? pricePerDay;
  String? pricePerSlot;
  String? multiSlotDiscount;
  String? multiDayDiscount;

  // Location type constants
  static const int LOCATION_FIXED = 1;
  static const int LOCATION_USER_SELECT = 2;

  // Trip type constants
  static const int TRIP_TYPE_ONE_WAY = 1;
  static const int TRIP_TYPE_TWO_WAY = 2;

  PackageModel({
    this.id,
    this.name,
    this.description,
    this.image,
    this.price,
    this.durationDays,
    this.durationWeeks,
    this.totalRides,
    this.maxRidersPerRide,
    this.locationType,
    this.startLocation,
    this.startLatitude,
    this.startLongitude,
    this.endLocation,
    this.endLatitude,
    this.endLongitude,
    this.tripType,
    this.hasSchedule,
    this.allowCustomTiming,
    this.showInHeader,
    this.status,
    this.services,
    this.schedules,
    this.useDynamicPricing,
    this.basePrice,
    this.pricePerDay,
    this.pricePerSlot,
    this.multiSlotDiscount,
    this.multiDayDiscount,
  });

  PackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    image = json['image'];
    price = json['price'].toString();
    durationDays = json['duration_days'];
    durationWeeks = json['duration_weeks'];
    totalRides = json['total_rides'];
    maxRidersPerRide = json['max_riders_per_ride'];
    locationType = json['location_type'];
    startLocation = json['start_location'];
    startLatitude = json['start_latitude'];
    startLongitude = json['start_longitude'];
    endLocation = json['end_location'];
    endLatitude = json['end_latitude'];
    endLongitude = json['end_longitude'];
    tripType = json['trip_type'];
    hasSchedule = json['has_schedule'] == 1 || json['has_schedule'] == true;
    allowCustomTiming = json['allow_custom_timing'] == 1 || json['allow_custom_timing'] == true;
    showInHeader = json['show_in_header'] == 1 || json['show_in_header'] == true;
    status = json['status'];
    // Dynamic pricing fields
    useDynamicPricing = json['use_dynamic_pricing'] == 1 || json['use_dynamic_pricing'] == true;
    basePrice = json['base_price']?.toString();
    pricePerDay = json['price_per_day']?.toString();
    pricePerSlot = json['price_per_slot']?.toString();
    multiSlotDiscount = json['multi_slot_discount']?.toString();
    multiDayDiscount = json['multi_day_discount']?.toString();
    if (json['services'] != null) {
      services = <ServiceModel>[];
      json['services'].forEach((v) {
        services!.add(ServiceModel.fromJson(v));
      });
    }
    if (json['schedules'] != null) {
      schedules = <PackageScheduleModel>[];
      json['schedules'].forEach((v) {
        schedules!.add(PackageScheduleModel.fromJson(v));
      });
    }
  }

  bool get hasFixedLocations => locationType == LOCATION_FIXED;
  bool get allowsUserLocationSelection => locationType == LOCATION_USER_SELECT;
  bool get isOneWay => tripType == TRIP_TYPE_ONE_WAY;
  bool get isTwoWay => tripType == TRIP_TYPE_TWO_WAY;
  String get tripTypeName => isTwoWay ? 'Two-way' : 'One-way';
  bool get hasWeeklySchedule => hasSchedule == true;
  bool get allowsCustomization => allowCustomTiming == true;
  
  /// Calculate dynamic price based on selected days and time slots
  double calculateDynamicPrice({
    required List<int> selectedDays,
    required Map<int, List<String>> selectedTimeSlots,
  }) {
    if (useDynamicPricing != true) {
      return double.tryParse(price ?? '0') ?? 0.0;
    }

    double totalPrice = double.tryParse(basePrice ?? '0') ?? 0.0;
    int dayCount = selectedDays.length;
    int totalSlots = 0;
    int daysWithBothSlots = 0;

    // Count total slots and days with both morning & evening
    for (var day in selectedDays) {
      final slots = selectedTimeSlots[day] ?? [];
      totalSlots += slots.length;
      if (slots.length >= 2) {
        daysWithBothSlots++;
      }
    }

    // Add day costs
    totalPrice += dayCount * (double.tryParse(pricePerDay ?? '0') ?? 0.0);
    
    // Add slot costs
    totalPrice += totalSlots * (double.tryParse(pricePerSlot ?? '0') ?? 0.0);
    
    // Apply multi-slot discount
    if (daysWithBothSlots > 0 && multiSlotDiscount != null) {
      final discount = (double.tryParse(multiSlotDiscount ?? '0') ?? 0.0);
      if (discount > 0) {
        totalPrice -= (totalPrice * discount / 100);
      }
    }
    
    // Apply multi-day discount (more than 3 days)
    if (dayCount > 3 && multiDayDiscount != null) {
      final discount = (double.tryParse(multiDayDiscount ?? '0') ?? 0.0);
      if (discount > 0) {
        totalPrice -= (totalPrice * discount / 100);
      }
    }
    
    return totalPrice > 0 ? totalPrice : 0.0;
  }
  
  /// Get display price - returns base price for dynamic, regular price otherwise
  String get displayPrice {
    if (useDynamicPricing == true) {
      return basePrice ?? '0';
    }
    return price ?? '0';
  }
  
  /// Check if this package uses dynamic pricing
  bool get hasDynamicPricing => useDynamicPricing == true;
}

class PackageScheduleModel {
  int? dayOfWeek;
  String? dayName;
  ScheduleSlot? morning;
  ScheduleSlot? evening;

  PackageScheduleModel({
    this.dayOfWeek,
    this.dayName,
    this.morning,
    this.evening,
  });

  PackageScheduleModel.fromJson(Map<String, dynamic> json) {
    dayOfWeek = json['day_of_week'];
    dayName = json['day_name'];
    morning = json['morning'] != null ? ScheduleSlot.fromJson(json['morning']) : null;
    evening = json['evening'] != null ? ScheduleSlot.fromJson(json['evening']) : null;
  }

  bool get hasMorningSlot => morning != null;
  bool get hasEveningSlot => evening != null;
}

class ScheduleSlot {
  LocationData? pickup;
  LocationData? drop;

  ScheduleSlot({this.pickup, this.drop});

  ScheduleSlot.fromJson(Map<String, dynamic> json) {
    pickup = json['pickup'] != null ? LocationData.fromJson(json['pickup']) : null;
    drop = json['drop'] != null ? LocationData.fromJson(json['drop']) : null;
  }
}

class LocationData {
  String? location;
  String? latitude;
  String? longitude;
  String? time;

  LocationData({this.location, this.latitude, this.longitude, this.time});

  LocationData.fromJson(Map<String, dynamic> json) {
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    time = json['time'];
  }
}

class ServiceModel {
  int? id;
  String? name;
  String? subtitle;
  String? image;

  ServiceModel({this.id, this.name, this.subtitle, this.image});

  ServiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    subtitle = json['subtitle'];
    image = json['image'];
  }
}

class UserPackageModel {
  int? id;
  int? userId;
  int? packageId;
  int? driverId;
  String? transactionId;
  String? amountPaid;
  String? price;
  int? totalRides;
  int? ridesUsed;
  int? ridesRemaining;
  int? remainingRides; // Keep for backward compatibility
  int? tripType;
  List<int>? selectedDays;
  List<String>? selectedTimeSlots;
  Map<String, dynamic>? customSchedule;
  String? scheduleStartDate;
  String? purchasedAt;
  String? expiresAt;
  int? status;
  int? daysRemaining;
  
  // Direct fields from API
  String? packageName;
  String? packageDescription;
  String? packageImage;
  
  PackageModel? package;
  DriverInfo? driver;
  List<UserPackageScheduleModel>? schedules;

  // Computed properties
  int get usedRides => ridesUsed ?? ((totalRides ?? 0) - (ridesRemaining ?? remainingRides ?? 0));
  
  String get expireDate => expiresAt ?? 'N/A';
  
  double get usagePercentage {
    if (totalRides == null || totalRides == 0) return 0;
    int used = ridesUsed ?? usedRides;
    return (used / totalRides!) * 100;
  }

  int getDaysRemaining() {
    if (daysRemaining != null) return daysRemaining!;
    if (expiresAt == null) return 0;
    try {
      final expiry = DateTime.parse(expiresAt!);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Active';
      case 2:
        return 'Expired';
      case 3:
        return 'Completed';
      case 0:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get tripTypeName => tripType == 2 ? 'Two-way' : 'One-way';
  bool get isOneWay => tripType == 1;
  bool get isTwoWay => tripType == 2;

  String get selectedDaysString {
    if (selectedDays == null || selectedDays!.isEmpty) return 'All days';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return selectedDays!.map((day) => dayNames[day - 1]).join(', ');
  }

  String get selectedTimeSlotsString {
    if (selectedTimeSlots == null || selectedTimeSlots!.isEmpty) return 'N/A';
    return selectedTimeSlots!.map((slot) => slot[0].toUpperCase() + slot.substring(1)).join(' & ');
  }

  UserPackageModel({
    this.id,
    this.userId,
    this.packageId,
    this.driverId,
    this.transactionId,
    this.amountPaid,
    this.price,
    this.totalRides,
    this.ridesUsed,
    this.ridesRemaining,
    this.remainingRides,
    this.tripType,
    this.selectedDays,
    this.selectedTimeSlots,
    this.customSchedule,
    this.scheduleStartDate,
    this.purchasedAt,
    this.expiresAt,
    this.status,
    this.daysRemaining,
    this.packageName,
    this.packageDescription,
    this.packageImage,
    this.package,
    this.driver,
    this.schedules,
  });

  UserPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    packageId = json['package_id'];
    driverId = json['driver_id'];
    transactionId = json['transaction_id'];
    amountPaid = json['amount_paid']?.toString();
    price = json['price']?.toString();
    totalRides = json['total_rides'];
    ridesUsed = json['rides_used'];
    ridesRemaining = json['rides_remaining'];
    remainingRides = json['remaining_rides']; // Backward compatibility
    tripType = json['trip_type'];
    selectedDays = json['selected_days'] != null ? List<int>.from(json['selected_days']) : null;
    selectedTimeSlots = json['selected_time_slots'] != null ? List<String>.from(json['selected_time_slots']) : null;
    customSchedule = json['custom_schedule'];
    scheduleStartDate = json['schedule_start_date'];
    purchasedAt = json['purchased_at'];
    expiresAt = json['expires_at'];
    status = json['status'];
    daysRemaining = json['days_remaining'];
    packageName = json['package_name'];
    packageDescription = json['package_description'];
    packageImage = json['package_image'];
    package = json['package'] != null ? PackageModel.fromJson(json['package']) : null;
    driver = json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null;
    if (json['schedules'] != null) {
      schedules = <UserPackageScheduleModel>[];
      json['schedules'].forEach((v) {
        schedules!.add(UserPackageScheduleModel.fromJson(v));
      });
    }
  }
}

class UserPackageScheduleModel {
  int? id;
  int? userPackageId;
  int? dayOfWeek;
  String? dayName;
  String? timeSlot;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? pickupTime;
  String? dropLocation;
  String? dropLatitude;
  String? dropLongitude;
  String? dropTime;
  int? status;
  String? scheduledDate;
  String? completedAt;

  UserPackageScheduleModel({
    this.id,
    this.userPackageId,
    this.dayOfWeek,
    this.dayName,
    this.timeSlot,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupTime,
    this.dropLocation,
    this.dropLatitude,
    this.dropLongitude,
    this.dropTime,
    this.status,
    this.scheduledDate,
    this.completedAt,
  });

  UserPackageScheduleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userPackageId = json['user_package_id'];
    dayOfWeek = json['day_of_week'];
    dayName = json['day_name'];
    timeSlot = json['time_slot'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    pickupTime = json['pickup_time'];
    dropLocation = json['drop_location'];
    dropLatitude = json['drop_latitude'];
    dropLongitude = json['drop_longitude'];
    dropTime = json['drop_time'];
    status = json['status'];
    scheduledDate = json['scheduled_date'];
    completedAt = json['completed_at'];
  }

  bool get isPending => status == 0;
  bool get isCompleted => status == 1;
  bool get isMorning => timeSlot == 'morning';
  bool get isEvening => timeSlot == 'evening';
  
  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Completed';
      case 2:
        return 'Skipped';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

class DriverInfo {
  int? id;
  String? firstname;
  String? lastname;
  String? email;
  String? mobile;
  String? image;

  String get fullname => '${firstname ?? ''} ${lastname ?? ''}'.trim();

  DriverInfo({this.id, this.firstname, this.lastname, this.email, this.mobile, this.image});

  DriverInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstname = json['firstname'];
    lastname = json['lastname'];
    email = json['email'];
    mobile = json['mobile'];
    image = json['image'];
  }
}

class PackageRideModel {
  int? id;
  int? userPackageId;
  int? rideId;
  int? userId;
  int? driverId;
  int? rideNumber;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  String? startedAt;
  String? completedAt;
  int? riderConfirmed;
  int? driverConfirmed;
  String? riderConfirmedAt;
  String? driverConfirmedAt;
  int? status;

  // Status constants
  static const int STATUS_PENDING = 0;
  static const int STATUS_ACTIVE = 1;
  static const int STATUS_RUNNING = 2;
  static const int STATUS_COMPLETED = 3;
  static const int STATUS_CANCELLED = 9;

  PackageRideModel({
    this.id,
    this.userPackageId,
    this.rideId,
    this.userId,
    this.driverId,
    this.rideNumber,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.startedAt,
    this.completedAt,
    this.riderConfirmed,
    this.driverConfirmed,
    this.riderConfirmedAt,
    this.driverConfirmedAt,
    this.status,
  });

  PackageRideModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userPackageId = json['user_package_id'];
    rideId = json['ride_id'];
    userId = json['user_id'];
    driverId = json['driver_id'];
    rideNumber = json['ride_number'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    destination = json['destination'];
    destinationLatitude = json['destination_latitude'];
    destinationLongitude = json['destination_longitude'];
    startedAt = json['started_at'];
    completedAt = json['completed_at'];
    riderConfirmed = json['rider_confirmed'];
    driverConfirmed = json['driver_confirmed'];
    riderConfirmedAt = json['rider_confirmed_at'];
    driverConfirmedAt = json['driver_confirmed_at'];
    status = json['status'];
  }

  bool get isBothConfirmed => riderConfirmed == 1 && driverConfirmed == 1;
  bool get isPendingConfirmation => riderConfirmed == 0 || driverConfirmed == 0;
  
  String get statusText {
    switch (status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_ACTIVE:
        return 'Active';
      case STATUS_RUNNING:
        return 'Running';
      case STATUS_COMPLETED:
        return 'Completed';
      case STATUS_CANCELLED:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
