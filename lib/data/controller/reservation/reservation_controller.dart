import 'package:get/get.dart';
import 'package:ovorideuser/data/model/reservation/reservation_model.dart';
import 'package:ovorideuser/data/repo/reservation/reservation_repo.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ReservationController extends GetxController {
  ReservationRepo reservationRepo;
  ReservationController({required this.reservationRepo});

  bool isLoading = false;
  List<ReservationModel> reservationList = [];
  List<ReservationModel> activeReservationList = [];
  List<ReservationModel> upcomingReservationList = [];
  List<ReservationModel> historyReservationList = [];
  ReservationModel? selectedReservation;
  List<ReservationScheduleModel> reservationSchedules = [];
  
  String serviceImagePath = '';
  String driverImagePath = '';


  // Get all user reservations
  Future<void> loadMyReservations() async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.getMyReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        serviceImagePath = data['data']['service_image_path'] ?? '';
        driverImagePath = data['data']['driver_image_path'] ?? '';

        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          reservationList.clear();
          var reservationData = data['data']['reservations']['data'] as List;
          for (var reservation in reservationData) {
            reservationList.add(ReservationModel.fromJson(reservation));
          }
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load reservations']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get active reservations
  Future<void> loadActiveReservations() async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.getActiveReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          activeReservationList.clear();
          var reservationData = data['data']['reservations']['data'] as List;
          for (var reservation in reservationData) {
            activeReservationList.add(ReservationModel.fromJson(reservation));
          }
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading active reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load active reservations']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get upcoming reservations
  Future<void> loadUpcomingReservations() async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.getUpcomingReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          upcomingReservationList.clear();
          var reservationData = data['data']['reservations']['data'] as List;
          for (var reservation in reservationData) {
            upcomingReservationList.add(ReservationModel.fromJson(reservation));
          }
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading upcoming reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load upcoming reservations']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get reservation details
  Future<void> loadReservationDetail(int id) async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.getReservationDetail(id);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['reservation'] != null) {
          selectedReservation = ReservationModel.fromJson(data['data']['reservation']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading reservation detail: $e');
      CustomSnackBar.error(errorList: ['Failed to load reservation details']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Create new reservation
  Future<bool> createReservation(Map<String, dynamic> data) async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.createReservation(data);

      if (response.statusCode == 200) {
        var responseData = response.responseJson;
        if (responseData['data']['reservation'] != null) {
          selectedReservation = ReservationModel.fromJson(responseData['data']['reservation']);
        }
        CustomSnackBar.success(successList: [response.message]);
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error creating reservation: $e');
      CustomSnackBar.error(errorList: ['Failed to create reservation']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Update reservation
  Future<bool> updateReservation(int id, Map<String, dynamic> data) async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.updateReservation(id, data);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message]);
        await loadReservationDetail(id);
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error updating reservation: $e');
      CustomSnackBar.error(errorList: ['Failed to update reservation']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Cancel reservation
  Future<bool> cancelReservation(int id, String reason) async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.cancelReservation(id, reason);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message]);
        // Refresh the reservation list
        await loadMyReservations();
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error cancelling reservation: $e');
      CustomSnackBar.error(errorList: ['Failed to cancel reservation']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Get reservation schedules
  Future<void> loadReservationSchedules(int id) async {
    isLoading = true;
    update();

    try {
      var response = await reservationRepo.getReservationSchedules(id);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['schedules'] != null) {
          reservationSchedules.clear();
          data['data']['schedules'].forEach((schedule) {
            reservationSchedules.add(ReservationScheduleModel.fromJson(schedule));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading reservation schedules: $e');
      CustomSnackBar.error(errorList: ['Failed to load schedules']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Filter reservations by status
  List<ReservationModel> getReservationsByStatus(int status) {
    return reservationList.where((reservation) => reservation.status == status).toList();
  }

  // Get pending reservations
  List<ReservationModel> get pendingReservations {
    return getReservationsByStatus(ReservationModel.STATUS_PENDING);
  }

  // Get confirmed reservations
  List<ReservationModel> get confirmedReservations {
    return getReservationsByStatus(ReservationModel.STATUS_CONFIRMED);
  }

  // Get completed reservations
  List<ReservationModel> get completedReservations {
    return getReservationsByStatus(ReservationModel.STATUS_COMPLETED);
  }

  // Get cancelled reservations
  List<ReservationModel> get cancelledReservations {
    return getReservationsByStatus(ReservationModel.STATUS_CANCELLED);
  }

  // Check if there are any active reservations
  bool get hasActiveReservations {
    return activeReservationList.isNotEmpty;
  }

  // Check if there are any upcoming reservations
  bool get hasUpcomingReservations {
    return upcomingReservationList.isNotEmpty;
  }

  // Clear all data
  void clearData() {
    reservationList.clear();
    activeReservationList.clear();
    upcomingReservationList.clear();
    historyReservationList.clear();
    selectedReservation = null;
    reservationSchedules.clear();
    update();
  }
}
