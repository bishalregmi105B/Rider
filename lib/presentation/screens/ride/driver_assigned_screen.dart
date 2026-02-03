import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen driver assigned screen (like WhatsApp call)
/// Shows when app is in background and a driver is assigned
class DriverAssignedScreen extends StatefulWidget {
  const DriverAssignedScreen({super.key});

  @override
  State<DriverAssignedScreen> createState() => _DriverAssignedScreenState();
}

class _DriverAssignedScreenState extends State<DriverAssignedScreen> 
    with TickerProviderStateMixin {
  
  RideModel? ride;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _vibrateTimer;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Get ride data from arguments - handle different types
    final args = Get.arguments;
    if (args is RideModel) {
      ride = args;
    } else if (args is String) {
      // If it's just a ride ID, navigate to ride details instead
      Get.offNamed(RouteHelper.rideDetailsScreen, arguments: args);
      return;
    } else if (args is Map) {
      // Handle map with ride data
      final rideData = args['ride'];
      if (rideData is RideModel) {
        ride = rideData;
      } else {
        Get.offNamed(RouteHelper.rideDetailsScreen, arguments: rideData.toString());
        return;
      }
    } else {
      // Invalid arguments, go back
      Get.back();
      return;
    }
    
    // Keep screen awake
    WakelockPlus.enable();
    
    // Initialize animations
    _initializeAnimations();
    
    // Play sound and vibrate
    _startVibration();
    
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  void _initializeAnimations() {
    // Pulse animation for driver avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start slide animation
    _slideController.forward();
  }
  
  void _startVibration() async {
    // Check if device can vibrate
    bool? canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      // Vibrate pattern: vibrate for 500ms, pause for 1000ms, repeat
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        Vibration.vibrate(duration: 500);
      });
      
      // Stop after 5 seconds
      Timer(const Duration(seconds: 5), () {
        _stopVibration();
      });
    }
  }
  
  void _stopVibration() {
    _vibrateTimer?.cancel();
    Vibration.cancel();
  }
  
  void _handleViewDetails() {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _cleanup();
    Get.back();
    Get.toNamed(RouteHelper.rideDetailsScreen, arguments: ride!.id);
  }
  
  void _handleContactDriver() {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _cleanup();
    Get.back();
    // Contact driver functionality - can be implemented with phone dialer
    Get.snackbar(
      'Contact Driver',
      'Opening driver contact...',
      backgroundColor: MyColor.primaryColor,
      colorText: MyColor.colorWhite,
      snackPosition: SnackPosition.TOP,
    );
  }
  
  void _cleanup() {
    _stopVibration();
    WakelockPlus.disable();
  }
  
  @override
  void dispose() {
    _cleanup();
    _pulseController.dispose();
    _slideController.dispose();
    
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: MyColor.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // If ride is null, show loading or return empty container
    // This can happen during navigation transitions
    if (ride == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MyColor.primaryColor,
              MyColor.primaryColor.withValues(alpha: 0.8),
              MyColor.screenBgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(Dimensions.space20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: MyColor.colorWhite,
                      size: 48,
                    ),
                    const SizedBox(height: Dimensions.space10),
                    Text(
                      'Driver Assigned!',
                      style: boldExtraLarge.copyWith(
                        color: MyColor.colorWhite,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space5),
                    Text(
                      'Your driver is on the way',
                      style: regularDefault.copyWith(
                        color: MyColor.colorWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(Dimensions.space20),
                    padding: const EdgeInsets.all(Dimensions.space20),
                    decoration: BoxDecoration(
                      color: MyColor.colorWhite,
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                      boxShadow: [
                        BoxShadow(
                          color: MyColor.colorBlack.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Driver avatar with pulse animation
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MyColor.primaryColor.withValues(alpha: 0.1),
                              border: Border.all(
                                color: MyColor.primaryColor,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: MyColor.primaryColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: Dimensions.space20),
                        
                        // Driver info
                        if (ride!.driver != null) ...[
                          Text(
                            '${ride!.driver?.firstname ?? ''} ${ride!.driver?.lastname ?? ''}',
                            style: boldLarge.copyWith(
                              color: MyColor.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.space5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: MyColor.colorOrange,
                                size: 20,
                              ),
                              const SizedBox(width: Dimensions.space5),
                              Text(
                                ride!.driver?.avgRating ?? '0.0',
                                style: semiBoldDefault.copyWith(
                                  color: MyColor.bodyTextColor,
                                ),
                              ),
                              const SizedBox(width: Dimensions.space10),
                              Text(
                                '(${ride!.driver?.totalReviews ?? '0'} reviews)',
                                style: regularSmall.copyWith(
                                  color: MyColor.colorGrey2,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: Dimensions.space30),
                        
                        // Vehicle info
                        Container(
                          padding: const EdgeInsets.all(Dimensions.space15),
                          decoration: BoxDecoration(
                            color: MyColor.borderColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildVehicleInfo(
                                Icons.directions_car,
                                ride!.driver?.vehicleData?.model?.name ?? ride!.driver?.brand?.name ?? 'Unknown',
                                'Vehicle',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: MyColor.borderColor,
                              ),
                              _buildVehicleInfo(
                                Icons.pin,
                                ride!.driver?.vehicleData?.vehicleNumber ?? 'N/A',
                                'Number',
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: Dimensions.space20),
                        
                        // ETA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: MyColor.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: Dimensions.space5),
                            Text(
                              'Arriving in ${ride!.duration ?? "N/A"} min',
                              style: semiBoldDefault.copyWith(
                                color: MyColor.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(Dimensions.space20),
                child: Row(
                  children: [
                    // Contact Driver button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isProcessing ? null : _handleContactDriver,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: MyColor.greenSuccessColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: MyColor.greenSuccessColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: MyColor.colorWhite,
                                  size: 22,
                                ),
                                const SizedBox(width: Dimensions.space10),
                                Text(
                                  'Contact Driver',
                                  style: boldDefault.copyWith(
                                    color: MyColor.colorWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: Dimensions.space15),
                    
                    // View Details button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isProcessing ? null : _handleViewDetails,
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: MyColor.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: MyColor.colorWhite,
                                    strokeWidth: 2,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: MyColor.colorWhite,
                                        size: 22,
                                      ),
                                      const SizedBox(width: Dimensions.space10),
                                      Text(
                                        'View Details',
                                        style: boldDefault.copyWith(
                                          color: MyColor.colorWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVehicleInfo(IconData icon, String text, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: MyColor.primaryColor,
          size: 24,
        ),
        const SizedBox(height: Dimensions.space5),
        Text(
          text,
          style: semiBoldDefault.copyWith(
            color: MyColor.primaryTextColor,
          ),
        ),
        Text(
          label,
          style: regularSmall.copyWith(
            color: MyColor.colorGrey2,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
