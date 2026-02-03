import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/model/driver/nearby_driver_model.dart';
import 'package:ovorideuser/data/repo/driver/driver_repo.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/helper.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/packages/polyline_animation/polyline_animation_v1.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {
  bool isLoading = false;
  final PolylineAnimator animator = PolylineAnimator();

  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  LatLng? _previousDriverLatLng;
  LatLng driverLatLng = const LatLng(0, 0);

  /// rotation for driver marker in degrees
  double driverRotation = 0.0;

  Map<PolylineId, Polyline> polylines = {};
  
  // Track if we should show driver route
  bool _showDriverRoute = false;

  // Map controller used by UI to set controller reference
  GoogleMapController? mapController;

  // Animation controller for interpolating marker movement
  late final AnimationController _animationController;
  
  // Track last marker count to reduce logging
  int? _lastMarkerCount;

  // Nearby drivers functionality
  Timer? _nearbyDriversTimer;
  List<NearbyDriverModel> nearbyDrivers = [];
  Uint8List? nearbyDriverIcon;
  Set<Marker> nearbyDriverMarkers = {};
  
  // Sequential notification - searching driver marker
  Marker? searchingDriverMarker;
  LatLng? searchingDriverLocation;
  
  // Track current driver being contacted
  String? currentSearchingDriverName;
  int? currentQueuePosition;
  int? totalDriversInQueue;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    _animationController.dispose();
    stopFetchingNearbyDrivers();
    super.onClose();
  }

  /// Start fetching nearby drivers for searching state
  void startFetchingNearbyDrivers({int? serviceId, int? zoneId}) {
    printX('🔵 startFetchingNearbyDrivers entered (serviceId: $serviceId, zoneId: $zoneId)');
    printX('🔵 About to call fetchNearbyDrivers...');
    fetchNearbyDrivers(serviceId: serviceId, zoneId: zoneId);
    printX('🔵 fetchNearbyDrivers call completed, setting up timer...');
    _nearbyDriversTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      printX('⏰ Timer triggered - calling fetchNearbyDrivers again');
      fetchNearbyDrivers(serviceId: serviceId, zoneId: zoneId);
    });
    printX('🔵 Timer setup complete');
  }

  /// Stop fetching nearby drivers
  void stopFetchingNearbyDrivers() {
    _nearbyDriversTimer?.cancel();
    _nearbyDriversTimer = null;
    nearbyDrivers.clear();
    nearbyDriverMarkers.clear();
    update();
  }

  /// Enable driver route tracking
  void enableDriverRouteTracking() {
    _showDriverRoute = true;
    printX('✅ Driver route tracking enabled');
  }

  /// Disable driver route tracking
  void disableDriverRouteTracking() {
    _showDriverRoute = false;
    // Remove driver route polylines
    polylines.remove(const PolylineId('driver_to_pickup'));
    polylines.remove(const PolylineId('driver_to_destination'));
    update();
    printX('🛑 Driver route tracking disabled');
  }

  /// Fetch nearby drivers from API
  Future<void> fetchNearbyDrivers({int? serviceId, int? zoneId}) async {
    // Reduce logging frequency in production
    if (nearbyDrivers.isEmpty) {
      printX('🔄 fetchNearbyDrivers called (serviceId: $serviceId, zoneId: $zoneId)');
    }
    
    if (!Get.isRegistered<AppLocationController>()) {
      printX('⚠️ AppLocationController not registered');
      return;
    }
    if (!Get.isRegistered<DriverRepo>()) {
      printX('⚠️ DriverRepo not registered');
      return;
    }

    final locationController = Get.find<AppLocationController>();
    final position = locationController.currentPosition;
    if (position == null) {
      printX('⚠️ Current position is null');
      return;
    }

    // Only log position on first call
    if (nearbyDrivers.isEmpty) {
      printX('📍 Fetching nearby drivers at (${position.latitude}, ${position.longitude})');
    }
    
    try {
      final driverRepo = Get.find<DriverRepo>();
      final response = await driverRepo.getNearbyDrivers(
        latitude: position.latitude,
        longitude: position.longitude,
        serviceId: serviceId,
        zoneId: zoneId,
        radius: 50.0, // Maximum allowed by backend
      );

      printX('📡 API Response: statusCode=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.responseJson;
        printX('📦 Response data: ${data['status']}, drivers=${data['data']?['drivers']?.length ?? 0}');
        
        if (data['status'] == 'success') {
          final driversData = data['data']['drivers'] as List;
          nearbyDrivers = driversData.map((json) => NearbyDriverModel.fromJson(json)).toList();
          _updateNearbyDriverMarkers();
          printX('✅ Loaded ${nearbyDrivers.length} nearby drivers on main map');
        } else {
          printX('❌ API returned non-success status: ${data['status']}');
        }
      } else {
        printX('❌ API returned error status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      printX('❌ Error fetching nearby drivers: $e');
      printX('Stack trace: $stackTrace');
    }
  }

  /// Update nearby driver markers
  Future<void> _updateNearbyDriverMarkers() async {
    if (nearbyDriverIcon == null) {
      nearbyDriverIcon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 80);
      printX('🎨 Loaded nearby driver marker icon');
    }

    final newMarkers = <Marker>{};
    for (var driver in nearbyDrivers) {
      final markerId = MarkerId('nearby_driver_${driver.id}');
      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(driver.latitude, driver.longitude),
          icon: nearbyDriverIcon != null
              ? BitmapDescriptor.bytes(
                  nearbyDriverIcon!,
                  width: 25,
                  height: 40,
                  bitmapScaling: MapBitmapScaling.auto,
                )
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '${driver.serviceName}',
            snippet: '${driver.distanceKm}${MyUtils.getDistanceLabel(distance: driver.distanceKm.toString(), unit: Get.find<ApiClient>().getDistanceUnit())} away • ⭐ ${driver.rating}',
          ),
        ),
      );
    }
    nearbyDriverMarkers = newMarkers;
    // Only log when driver count changes
    if (_lastMarkerCount != nearbyDriverMarkers.length) {
      printX('🔄 Updated nearby drivers: ${nearbyDriverMarkers.length}');
    }
    update();
  }

  /// Show marker for driver currently being contacted (sequential notification)
  Future<void> showSearchingDriverMarker({
    required LatLng driverLocation,
    required String driverName,
    required int queuePosition,
    required int totalDrivers,
  }) async {
    printX('🟢 Showing searching driver marker: $driverName at ${driverLocation.latitude}, ${driverLocation.longitude}');
    searchingDriverLocation = driverLocation;
    
    // Store the current search information
    currentSearchingDriverName = driverName;
    currentQueuePosition = queuePosition;
    totalDriversInQueue = totalDrivers;
    
    // Create green marker for driver being contacted
    final Uint8List? icon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 100);
    
    searchingDriverMarker = Marker(
      markerId: const MarkerId('searching_driver'),
      position: driverLocation,
      icon: icon != null
          ? BitmapDescriptor.bytes(
              icon,
              width: 30,
              height: 45,
              bitmapScaling: MapBitmapScaling.auto,
            )
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: '🔍 Contacting Driver',
        snippet: '$driverName (Driver $queuePosition of $totalDrivers)',
      ),
      zIndex: 1000, // Make sure it's on top
    );
    
    // Move camera to show the driver
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(driverLocation, 14),
      );
    }
    
    printX('✅ Showing searching driver marker at $driverLocation');
    update();
  }

  /// Clear searching driver marker (when driver accepts or timeout)
  void clearSearchingDriverMarker() {
    searchingDriverMarker = null;
    searchingDriverLocation = null;
    currentSearchingDriverName = null;
    currentQueuePosition = null;
    totalDriversInQueue = null;
    update();
    printX('🔴 Cleared searching driver marker');
  }

  /// Public method to receive driver location updates
  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    printX('ride map update $latLng, $isRunning');

    // If this is the first position - just set it
    if (driverLatLng.latitude == 0 && driverLatLng.longitude == 0) {
      _previousDriverLatLng = latLng;
      driverLatLng = latLng;
      getCurrentDriverAddress();
      _showDriverRoute = true;
      _updateDriverRoute(isRunning);
      update();
      return;
    }

    // Animate marker from old to new position
    _animateMarker(latLng);
    getCurrentDriverAddress();
    
    // Update driver route if needed
    if (_showDriverRoute) {
      _updateDriverRoute(isRunning);
    }
  }

  void _animateMarker(LatLng newPosition) {
    final oldPosition = _previousDriverLatLng ?? driverLatLng;
    _previousDriverLatLng = oldPosition;

    // stop any previous animation listeners
    _animationController.stop();
    _animationController.reset();

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    final latTween = Tween<double>(begin: oldPosition.latitude, end: newPosition.latitude);
    final lngTween = Tween<double>(begin: oldPosition.longitude, end: newPosition.longitude);

    void listener() {
      final lat = latTween.evaluate(animation);
      final lng = lngTween.evaluate(animation);
      final position = LatLng(lat, lng);

      // update rotation using last previous and current interpolated position
      driverRotation = _getRotation(
        oldPosition.latitude,
        oldPosition.longitude,
        position.latitude,
        position.longitude,
      );

      // update actual marker position used by UI
      driverLatLng = position;
      update(); // rebuild markers in the UI

      // Optionally follow the driver with camera
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }

    // remove previous listeners
    _animationController.removeListener(() {});
    _animationController.addListener(listener);

    _animationController.forward().whenComplete(() {
      // ensure final exact position is set and rotation updated
      driverLatLng = newPosition;
      driverRotation = _getRotation(
        oldPosition.latitude,
        oldPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      update();

      // update previous position for next animation
      _previousDriverLatLng = newPosition;
      // remove the listener to avoid duplicate calls
      _animationController.removeListener(listener);
    });
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  /// Calculates bearing (degrees) from (lat1, lon1) to (lat2, lon2)
  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    // convert to radians
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaLambda = _toRadians(lon2 - lon1);

    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final bearing = atan2(y, x);
    var bearingDegrees = (bearing * 180.0 / pi + 360.0) % 360.0; // normalize 0-360

    return bearingDegrees;
  }

  void loadMap({
    required LatLng pickup,
    required LatLng destination,
    bool? isRunning = false,
  }) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    getPolyLinePoints().then((data) {
      polylineCoordinates = data;
      generatePolyLineFromPoints(data);
      fitPolylineBounds(data);
      if (Get.isRegistered<RideDetailsController>()) {
        if (![AppStatus.RIDE_RUNNING, AppStatus.RIDE_ACTIVE, AppStatus.RIDE_COMPLETED].contains(Get.find<RideDetailsController>().ride.status)) {
          animator.animatePolyline(
            data,
            'polyline_id',
            MyColor.colorOrange,
            MyColor.primaryColor,
            polylines,
            () {
              if (Get.isRegistered<RideDetailsController>()) {
                if (![AppStatus.RIDE_RUNNING, AppStatus.RIDE_ACTIVE, AppStatus.RIDE_COMPLETED].contains(Get.find<RideDetailsController>().ride.status)) {
                  update();
                }
              }
            },
          );
        }
      }
    });

    await setCustomMarkerIcon();
  }

  void animateMapCameraPosition() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          zoom: Environment.mapDefaultZoom,
        ),
      ),
    );
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    isLoading = true;
    update();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: MyColor.getPrimaryColor(),
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    isLoading = false;
    update();
  }

  List<LatLng> polylineCoordinates = [];
  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        destination: PointLatLng(
          destinationLatLng.latitude,
          destinationLatLng.longitude,
        ),
        mode: TravelMode.driving,
      ),
      googleApiKey: Environment.mapKey,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      printX(result.errorMessage);
    }
    return polylineCoordinates;
  }

  // icons
  Uint8List? pickupIcon;
  Uint8List? destinationIcon;
  Uint8List? driverIcon;

  Set<Marker> getMarkers({
    required LatLng pickup,
    required LatLng destination,
    LatLng? maybeDriverLatLng,
  }) {
    // prefer currently animated driverLatLng
    final mkDriverLatLng = maybeDriverLatLng ?? driverLatLng;

    final markers = <Marker>{};

    // Add assigned driver marker (when ride is active/running)
    if (mkDriverLatLng.latitude != 0 || mkDriverLatLng.longitude != 0) {
      // Build driver info for marker
      String markerTitle = driverName;
      
      // Build snippet with ETA, vehicle, and address
      List<String> snippetParts = [];
      
      // Add ETA if available
      if (driverETA.isNotEmpty && driverDistance.isNotEmpty) {
        snippetParts.add('⏱️ ETA: $driverETA • 📏 $driverDistance');
      } else if (driverETA.isNotEmpty) {
        snippetParts.add('⏱️ ETA: $driverETA');
      }
      
      // Add vehicle info
      if (driverVehicle.isNotEmpty) {
        snippetParts.add(driverVehicle);
      }
      
      // Add address
      if (driverAddress.isNotEmpty && driverAddress != 'Loading...') {
        snippetParts.add(driverAddress);
      }
      
      String markerSnippet = snippetParts.join('\n');
      
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker_id'),
          position: mkDriverLatLng,
          rotation: driverRotation,
          anchor: const Offset(0.5, 0.5),
          icon: driverIcon == null
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.bytes(
                  driverIcon!,
                  width: 40,
                  height: 60,
                  bitmapScaling: MapBitmapScaling.auto,
                ),
          infoWindow: InfoWindow(
            title: '🚗 $markerTitle',
            snippet: markerSnippet,
            onTap: () {
              printX('Driver marker tapped: $markerTitle');
            },
          ),
          onTap: () async {
            getCurrentDriverAddress();
            printX('Driver current position $mkDriverLatLng');
            printX('Driver current address $driverAddress');
            update(); // Refresh to show updated info
          },
        ),
      );
    }

    // Add nearby drivers markers (only when searching - RIDE_PENDING status)
    if (Get.isRegistered<RideDetailsController>()) {
      final rideController = Get.find<RideDetailsController>();
      // Reduce logging - only log when marker count changes
      if (_lastMarkerCount != nearbyDriverMarkers.length) {
        printX('🗺️ Nearby drivers update: ${nearbyDriverMarkers.length} markers (status=${rideController.ride.status})');
        _lastMarkerCount = nearbyDriverMarkers.length;
      }
      if (rideController.ride.status == AppStatus.RIDE_PENDING) {
        markers.addAll(nearbyDriverMarkers);
      }
    }

    // pickup
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_marker_id'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: pickupIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                pickupIcon!,
                height: 45,
                width: 45,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () async {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
                zoom: Environment.mapDefaultZoom,
              ),
            ),
          );
        },
      ),
    );

    // destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination_marker_id'),
        position: LatLng(destination.latitude, destination.longitude),
        icon: destinationIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                destinationIcon!,
                height: 45,
                width: 45,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () async {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(destination.latitude, destination.longitude),
                zoom: Environment.mapDefaultZoom,
              ),
            ),
          );
        },
      ),
    );

    return markers;
  }

  Future<void> setCustomMarkerIcon() async {
    pickupIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 150);
    destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    driverIcon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 80);
    update();
  }

  String driverAddress = 'Loading...';
  String driverName = 'Your Driver';
  String driverVehicle = '';
  
  // ETA (Estimated Time of Arrival) information
  String driverETA = '';
  int? driverETASeconds;
  String driverDistance = '';

  Future<void> getCurrentDriverAddress() async {
    try {
      final List<Placemark> placeMark = await placemarkFromCoordinates(
        driverLatLng.latitude,
        driverLatLng.longitude,
      );
      driverAddress = "";
      driverAddress = "${placeMark[0].street} ${placeMark[0].subThoroughfare} ${placeMark[0].thoroughfare},${placeMark[0].subLocality},${placeMark[0].locality},${placeMark[0].country}";
      update();
      printX('appLocations position $driverAddress');
    } catch (e) {
      printX('Error in getting position: $e');
    }
  }

  /// Update driver info for marker display
  void updateDriverInfo({
    required String? firstName,
    required String? lastName,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleNumber,
  }) {
    // Build driver name
    if (firstName != null && lastName != null) {
      driverName = '$firstName $lastName';
    } else if (firstName != null) {
      driverName = firstName;
    } else {
      driverName = 'Your Driver';
    }

    // Build vehicle info
    List<String> vehicleParts = [];
    if (vehicleModel != null && vehicleModel.isNotEmpty) {
      vehicleParts.add(vehicleModel);
    }
    if (vehicleColor != null && vehicleColor.isNotEmpty) {
      vehicleParts.add(vehicleColor);
    }
    if (vehicleNumber != null && vehicleNumber.isNotEmpty && vehicleNumber != 'null') {
      vehicleParts.add('[$vehicleNumber]');
    }
    
    driverVehicle = vehicleParts.join(' ');
    
    printX('🚗 Driver info updated: $driverName, Vehicle: $driverVehicle');
    update();
  }

  /// Update driver route dynamically based on ride status
  Future<void> _updateDriverRoute(bool isRunning) async {
    if (driverLatLng.latitude == 0 || driverLatLng.longitude == 0) {
      return;
    }

    try {
      LatLng destination;
      String polylineIdStr;
      Color routeColor;

      if (isRunning) {
        // RUNNING: Driver → Destination (Green)
        destination = destinationLatLng;
        polylineIdStr = 'driver_to_destination';
        routeColor = MyColor.greenSuccessColor;
        printX('🟢 Drawing route: Driver → Destination');
      } else {
        // ACTIVE: Driver → Pickup (Blue)
        destination = pickupLatLng;
        polylineIdStr = 'driver_to_pickup';
        routeColor = MyColor.getPrimaryColor();
        printX('🔵 Drawing route: Driver → Pickup');
      }

      // Get route points
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(driverLatLng.latitude, driverLatLng.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
        googleApiKey: Environment.mapKey,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> routeCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Extract ETA information from the route result
        if (!isRunning && result.totalDurationValue != null) {
          // Only calculate ETA when driver is heading to pickup
          _extractETAFromResult(result);
        }

        // Create or update the driver route polyline
        PolylineId polylineId = PolylineId(polylineIdStr);
        Polyline driverPolyline = Polyline(
          polylineId: polylineId,
          color: routeColor,
          points: routeCoordinates,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
        );

        // Update polylines map
        polylines[polylineId] = driverPolyline;
        
        // Remove old polyline if switching status
        if (isRunning) {
          polylines.remove(const PolylineId('driver_to_pickup'));
        } else {
          polylines.remove(const PolylineId('driver_to_destination'));
        }

        update();
        printX('✅ Driver route updated with ${routeCoordinates.length} points');
      } else {
        printX('❌ No route points received: ${result.errorMessage}');
      }
    } catch (e) {
      printX('❌ Error updating driver route: $e');
    }
  }

  /// Extract and format ETA from Google Maps Directions API result
  void _extractETAFromResult(PolylineResult result) {
    try {
      // Get duration in seconds
      if (result.totalDurationValue != null && result.totalDurationValue! > 0) {
        driverETASeconds = result.totalDurationValue;
        
        // Format duration text
        int minutes = (driverETASeconds! / 60).round();
        if (minutes < 1) {
          driverETA = 'Less than 1 min';
        } else if (minutes == 1) {
          driverETA = '1 min';
        } else if (minutes < 60) {
          driverETA = '$minutes mins';
        } else {
          int hours = (minutes / 60).floor();
          int remainingMinutes = minutes % 60;
          if (remainingMinutes == 0) {
            driverETA = '$hours ${hours == 1 ? "hr" : "hrs"}';
          } else {
            driverETA = '$hours ${hours == 1 ? "hr" : "hrs"} $remainingMinutes mins';
          }
        }
        
        printX('⏱️ Driver ETA: $driverETA ($driverETASeconds seconds)');
      }
      
      // Get distance
      if (result.totalDistanceValue != null && result.totalDistanceValue! > 0) {
        double distanceKm = result.totalDistanceValue! / 1000;
        final distanceUnit = Get.find<ApiClient>().getDistanceUnit();
        
        if (distanceUnit.toLowerCase() == 'mile') {
          double distanceMiles = distanceKm * 0.621371;
          driverDistance = '${distanceMiles.toStringAsFixed(1)} mi';
        } else {
          driverDistance = '${distanceKm.toStringAsFixed(1)} km';
        }
        
        printX('📏 Driver distance: $driverDistance');
      }
      
      update();
    } catch (e) {
      printX('❌ Error extracting ETA: $e');
    }
  }

  /// Calculate ETA manually using Haversine formula and average speed
  /// This is a fallback method when Google Maps API is not available or fails
  void calculateETAManually({required LatLng driverLocation, required LatLng pickupLocation}) {
    try {
      // Calculate distance using Haversine formula
      double distanceInMeters = _calculateHaversineDistance(
        driverLocation.latitude,
        driverLocation.longitude,
        pickupLocation.latitude,
        pickupLocation.longitude,
      );
      
      // Assume average city driving speed of 30 km/h (adjustable)
      const double averageSpeedKmh = 30.0;
      const double averageSpeedMs = averageSpeedKmh / 3.6; // Convert to m/s
      
      // Calculate estimated time in seconds
      driverETASeconds = (distanceInMeters / averageSpeedMs).round();
      
      // Add 20% buffer for traffic and stops
      driverETASeconds = (driverETASeconds! * 1.2).round();
      
      // Format duration
      int minutes = (driverETASeconds! / 60).round();
      if (minutes < 1) {
        driverETA = 'Less than 1 min';
      } else if (minutes == 1) {
        driverETA = '1 min';
      } else if (minutes < 60) {
        driverETA = '$minutes mins';
      } else {
        int hours = (minutes / 60).floor();
        int remainingMinutes = minutes % 60;
        if (remainingMinutes == 0) {
          driverETA = '$hours ${hours == 1 ? "hr" : "hrs"}';
        } else {
          driverETA = '$hours ${hours == 1 ? "hr" : "hrs"} $remainingMinutes mins';
        }
      }
      
      // Format distance
      double distanceKm = distanceInMeters / 1000;
      final distanceUnit = Get.find<ApiClient>().getDistanceUnit();
      
      if (distanceUnit.toLowerCase() == 'mile') {
        double distanceMiles = distanceKm * 0.621371;
        driverDistance = '${distanceMiles.toStringAsFixed(1)} mi';
      } else {
        driverDistance = '${distanceKm.toStringAsFixed(1)} km';
      }
      
      printX('⏱️ Manual ETA calculated: $driverETA ($driverETASeconds seconds)');
      printX('📏 Manual distance calculated: $driverDistance');
      
      update();
    } catch (e) {
      printX('❌ Error calculating manual ETA: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    setMapFitToTour(Set<Polyline>.of(polylines.values));
  }

  void setMapFitToTour(Set<Polyline> p) {
    if (p.isEmpty) return;

    double minLat = p.first.points.first.latitude;
    double minLong = p.first.points.first.longitude;
    double maxLat = p.first.points.first.latitude;
    double maxLong = p.first.points.first.longitude;
    for (var poly in p) {
      for (var point in poly.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      }
    }
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)),
        30,
      ),
    );
  }
}
