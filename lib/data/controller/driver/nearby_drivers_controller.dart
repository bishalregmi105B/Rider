import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/helper.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/model/driver/nearby_driver_model.dart';
import 'package:ovorideuser/data/repo/driver/driver_repo.dart';
import 'package:ovorideuser/environment.dart';

class NearbyDriversController extends GetxController {
  DriverRepo driverRepo;
  NearbyDriversController({required this.driverRepo});

  bool isLoading = false;
  List<NearbyDriverModel> nearbyDrivers = [];
  Set<Marker> driverMarkers = {};
  GoogleMapController? mapController;
  Timer? _fetchTimer;
  Uint8List? driverMarkerIcon;

  // Filters
  int? selectedServiceId;
  int? selectedZoneId;
  double searchRadius = 10.0; // km

  @override
  void onInit() {
    super.onInit();
    _loadMarkerIcon();
  }

  Future<void> _loadMarkerIcon() async {
    driverMarkerIcon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 80);
    update();
  }

  void startFetchingNearbyDrivers() {
    fetchNearbyDrivers(); // Initial fetch
    _fetchTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchNearbyDrivers();
    });
  }

  void stopFetchingNearbyDrivers() {
    _fetchTimer?.cancel();
    _fetchTimer = null;
  }

  Future<void> fetchNearbyDrivers({bool useEnhanced = true}) async {
    if (!Get.isRegistered<AppLocationController>()) {
      printX('❌ AppLocationController not registered');
      return;
    }

    final locationController = Get.find<AppLocationController>();
    final position = locationController.currentPosition;

    if (position == null) {
      printX('❌ No location available');
      return;
    }

    try {
      final response = useEnhanced 
        ? await driverRepo.getNearbyDriversEnhanced(
            latitude: position.latitude,
            longitude: position.longitude,
            serviceId: selectedServiceId,
            zoneId: selectedZoneId,
            radius: searchRadius,
            minRating: 4.0,
            includeVehicleDetails: true,
          )
        : await driverRepo.getNearbyDrivers(
            latitude: position.latitude,
            longitude: position.longitude,
            serviceId: selectedServiceId,
            zoneId: selectedZoneId,
            radius: searchRadius,
          );

      if (response.statusCode == 200) {
        final data = response.responseJson;
        if (data['status'] == 'success') {
          final driversData = data['data']['drivers'] as List;
          nearbyDrivers = driversData
              .map((json) => NearbyDriverModel.fromJson(json))
              .toList();

          _updateDriverMarkers();
          
          printX('✅ Fetched ${nearbyDrivers.length} nearby drivers${useEnhanced ? " (enhanced)" : ""}');
          
          // Log ETA and vehicle details if available
          if (useEnhanced && nearbyDrivers.isNotEmpty) {
            printX('📊 Enhanced data available:');
            for (var driver in nearbyDrivers.take(3)) {
              printX('  Driver #${driver.id}: ETA=${driver.etaFormatted}, Vehicle=${driver.vehicle?.model ?? "N/A"}');
            }
          }
        }
      }
    } catch (e) {
      printX('❌ Error fetching nearby drivers: $e');
    }
  }

  void _updateDriverMarkers() {
    final newMarkers = <Marker>{};

    for (var driver in nearbyDrivers) {
      final markerId = MarkerId('driver_${driver.id}');
      final position = LatLng(driver.latitude, driver.longitude);

      // Build info window with ETA if available
      String snippet = '${driver.distanceKm}${MyUtils.getDistanceLabel(distance: driver.distanceKm.toString(), unit: Get.find<ApiClient>().getDistanceUnit())} away • ⭐ ${driver.rating}';
      if (driver.etaFormatted != null) {
        snippet = '${driver.etaFormatted} • $snippet';
      }
      if (driver.vehicle?.model != null) {
        snippet = '${driver.vehicle!.model} • $snippet';
      }

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: driverMarkerIcon != null
              ? BitmapDescriptor.bytes(
                  driverMarkerIcon!,
                  width: 25,
                  height: 40,
                  bitmapScaling: MapBitmapScaling.auto,
                )
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '${driver.serviceName}',
            snippet: snippet,
          ),
          onTap: () {
            printX('Driver tapped: ${driver.id}');
            // Can show driver details bottom sheet here
          },
        ),
      );
    }

    driverMarkers = newMarkers;
    update();
  }

  void setServiceFilter(int? serviceId) {
    selectedServiceId = serviceId;
    fetchNearbyDrivers();
  }

  void setZoneFilter(int? zoneId) {
    selectedZoneId = zoneId;
    fetchNearbyDrivers();
  }

  void setRadiusFilter(double radius) {
    searchRadius = radius;
    fetchNearbyDrivers();
  }

  void clearFilters() {
    selectedServiceId = null;
    selectedZoneId = null;
    searchRadius = 10.0;
    fetchNearbyDrivers();
  }

  CameraPosition getInitialCameraPosition() {
    if (Get.isRegistered<AppLocationController>()) {
      final locationController = Get.find<AppLocationController>();
      final position = locationController.currentPosition;
      if (position != null) {
        return CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: Environment.mapDefaultZoom,
        );
      }
    }
    // Default to some location if no position
    return const CameraPosition(
      target: LatLng(27.7172, 85.3240), // Kathmandu
      zoom: 12,
    );
  }

  Set<Marker> getAllMarkers() {
    final markers = <Marker>{...driverMarkers};

    // Add user location marker
    if (Get.isRegistered<AppLocationController>()) {
      final locationController = Get.find<AppLocationController>();
      final position = locationController.currentPosition;
      if (position != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
    }

    return markers;
  }

  void animateCameraToUserLocation() {
    if (Get.isRegistered<AppLocationController>()) {
      final locationController = Get.find<AppLocationController>();
      final position = locationController.currentPosition;
      if (position != null && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: Environment.mapDefaultZoom,
            ),
          ),
        );
      }
    }
  }

  @override
  void onClose() {
    stopFetchingNearbyDrivers();
    mapController?.dispose();
    super.onClose();
  }
}
