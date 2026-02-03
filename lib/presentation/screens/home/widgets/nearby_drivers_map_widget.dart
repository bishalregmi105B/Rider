import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/data/controller/driver/nearby_drivers_controller.dart';

class NearbyDriversMapWidget extends StatefulWidget {
  final double height;
  final bool showDriverCount;
  final int? serviceId;

  const NearbyDriversMapWidget({
    Key? key,
    this.height = 300,
    this.showDriverCount = true,
    this.serviceId,
  }) : super(key: key);

  @override
  State<NearbyDriversMapWidget> createState() => _NearbyDriversMapWidgetState();
}

class _NearbyDriversMapWidgetState extends State<NearbyDriversMapWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NearbyDriversController>()) {
        final controller = Get.find<NearbyDriversController>();
        if (widget.serviceId != null) {
          controller.setServiceFilter(widget.serviceId);
        }
        controller.startFetchingNearbyDrivers();
      }
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<NearbyDriversController>()) {
      Get.find<NearbyDriversController>().stopFetchingNearbyDrivers();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NearbyDriversController>(
      builder: (controller) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MyColor.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: controller.getInitialCameraPosition(),
                  markers: controller.getAllMarkers(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  onMapCreated: (GoogleMapController mapController) {
                    controller.mapController = mapController;
                  },
                ),

                // Driver Count Badge (top-left)
                if (widget.showDriverCount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: MyColor.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_taxi,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${controller.nearbyDrivers.length} Available',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // My Location Button (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        controller.animateCameraToUserLocation();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: MyColor.primaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // Refresh Button (bottom-right)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        controller.fetchNearbyDrivers();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: MyColor.primaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // Loading Indicator
                if (controller.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
