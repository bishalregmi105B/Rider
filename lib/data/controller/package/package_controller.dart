import 'package:get/get.dart';
import 'package:ovorideuser/data/model/package/package_model.dart';
import 'package:ovorideuser/data/repo/package/package_repo.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class PackageController extends GetxController {
  PackageRepo packageRepo;
  PackageController({required this.packageRepo});

  bool isLoading = false;
  List<PackageModel> packageList = [];
  List<UserPackageModel> myPackageList = [];
  List<UserPackageModel> activePackageList = [];
  List<UserPackageModel> packageHistoryList = [];
  PackageModel? selectedPackage;
  UserPackageModel? selectedUserPackage;
  List<UserPackageScheduleModel> userPackageSchedules = [];
  Map<String, dynamic>? packageUsageStats;

  String packageImagePath = '';
  String serviceImagePath = '';
  String driverImagePath = '';

  @override
  void onInit() {
    super.onInit();
  }

  // Get available packages
  Future<void> loadAvailablePackages() async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getAvailablePackages();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';

        if (data['data']['packages'] != null) {
          packageList.clear();
          data['data']['packages'].forEach((package) {
            packageList.add(PackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading packages: $e');
      CustomSnackBar.error(errorList: ['Failed to load packages']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get my purchased packages
  Future<void> loadMyPackages() async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getMyPackages();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['packages'] != null) {
          myPackageList.clear();
          data['data']['packages'].forEach((package) {
            myPackageList.add(UserPackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading my packages: $e');
      CustomSnackBar.error(errorList: ['Failed to load your packages']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Purchase package
  Future<bool> purchasePackage(int packageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.purchasePackage(packageId);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message]);
        // Reload my packages
        await loadMyPackages();
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error purchasing package: $e');
      CustomSnackBar.error(errorList: ['Failed to purchase package']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get package details
  Future<void> loadPackageDetails(int packageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getPackageDetails(packageId);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';

        if (data['data']['package'] != null) {
          selectedPackage = PackageModel.fromJson(data['data']['package']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package details: $e');
      CustomSnackBar.error(errorList: ['Failed to load package details']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get user package details
  Future<void> loadUserPackageDetails(int userPackageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getUserPackageDetails(userPackageId);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['user_package'] != null) {
          selectedUserPackage = UserPackageModel.fromJson(data['data']['user_package']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading user package details: $e');
      CustomSnackBar.error(errorList: ['Failed to load package details']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get active packages only
  Future<void> loadActivePackages() async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getActivePackages();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['packages'] != null) {
          activePackageList.clear();
          data['data']['packages'].forEach((package) {
            activePackageList.add(UserPackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading active packages: $e');
      CustomSnackBar.error(errorList: ['Failed to load active packages']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get package history (expired/completed)
  Future<void> loadPackageHistory() async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getPackageHistory();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['packages'] != null) {
          packageHistoryList.clear();
          data['data']['packages'].forEach((package) {
            packageHistoryList.add(UserPackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package history: $e');
      CustomSnackBar.error(errorList: ['Failed to load package history']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get package usage statistics
  Future<void> loadPackageUsage(int userPackageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getPackageUsage(userPackageId);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['user_package'] != null) {
          selectedUserPackage = UserPackageModel.fromJson(data['data']['user_package']);
        }
        
        packageUsageStats = {
          'usage_stats': data['data']['usage_stats'],
          'schedule_stats': data['data']['schedule_stats'],
        };
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package usage: $e');
      CustomSnackBar.error(errorList: ['Failed to load package usage']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get package with schedule details
  Future<void> loadPackageWithSchedule(int packageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getPackageWithSchedule(packageId);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';

        if (data['data']['package'] != null) {
          selectedPackage = PackageModel.fromJson(data['data']['package']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package with schedule: $e');
      CustomSnackBar.error(errorList: ['Failed to load package schedule']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Purchase package with custom schedule
  Future<bool> purchasePackageWithSchedule({
    required int packageId,
    required int tripType,
    required List<int> selectedDays,
    required Map<int, List<String>> selectedTimeSlots,
    required String scheduleStartDate,
    Map<String, dynamic>? customSchedule,
  }) async {
    isLoading = true;
    update();

    try {
      // Find the package to calculate dynamic price
      PackageModel? package = selectedPackage ?? packageList.firstWhereOrNull((p) => p.id == packageId);
      
      // Calculate dynamic price if applicable
      double? calculatedPrice;
      if (package != null && package.hasDynamicPricing) {
        calculatedPrice = package.calculateDynamicPrice(
          selectedDays: selectedDays,
          selectedTimeSlots: selectedTimeSlots,
        );
      }

      Map<String, dynamic> data = {
        'package_id': packageId,
        'trip_type': tripType,
        'selected_days': selectedDays,
        'selected_time_slots': _convertTimeSlotsToList(selectedTimeSlots),
        'schedule_start_date': scheduleStartDate,
      };

      if (customSchedule != null) {
        data['custom_schedule'] = customSchedule;
      }
      
      // Add calculated price for validation
      if (calculatedPrice != null) {
        data['calculated_price'] = calculatedPrice;
      }

      var response = await packageRepo.purchasePackageWithSchedule(data);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message]);
        // Reload active packages
        await loadActivePackages();
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error purchasing package with schedule: $e');
      CustomSnackBar.error(errorList: ['Failed to purchase package']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Helper to convert time slots map to list format for API
  List<String> _convertTimeSlotsToList(Map<int, List<String>> timeSlotsMap) {
    List<String> result = [];
    timeSlotsMap.forEach((day, slots) {
      result.addAll(slots);
    });
    return result;
  }

  // Calculate package price based on selection
  double calculatePackagePrice({
    required PackageModel package,
    required List<int> selectedDays,
    required Map<int, List<String>> selectedTimeSlots,
  }) {
    if (package.hasDynamicPricing) {
      return package.calculateDynamicPrice(
        selectedDays: selectedDays,
        selectedTimeSlots: selectedTimeSlots,
      );
    }
    return double.tryParse(package.price ?? '0') ?? 0.0;
  }

  // Get user's package schedules
  Future<void> loadUserPackageSchedules(int userPackageId) async {
    isLoading = true;
    update();

    try {
      var response = await packageRepo.getUserPackageSchedules(userPackageId);

      if (response.statusCode == 200) {
        var data = response.responseJson;

        if (data['data']['user_package'] != null) {
          selectedUserPackage = UserPackageModel.fromJson(data['data']['user_package']);
        }

        if (data['data']['schedules'] != null) {
          userPackageSchedules.clear();
          data['data']['schedules'].forEach((schedule) {
            // Parse the schedule data - it's grouped by day
            if (schedule['morning'] != null) {
              userPackageSchedules.add(UserPackageScheduleModel.fromJson(schedule['morning']));
            }
            if (schedule['evening'] != null) {
              userPackageSchedules.add(UserPackageScheduleModel.fromJson(schedule['evening']));
            }
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading user package schedules: $e');
      CustomSnackBar.error(errorList: ['Failed to load schedules']);
    } finally {
      isLoading = false;
      update();
    }
  }

  void clearData() {
    packageList.clear();
    myPackageList.clear();
    activePackageList.clear();
    packageHistoryList.clear();
    userPackageSchedules.clear();
    selectedPackage = null;
    selectedUserPackage = null;
    packageUsageStats = null;
    update();
  }
}
