import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/menu/my_menu_controller.dart';
import 'package:ovorideuser/data/controller/pusher/global_pusher_controller.dart';
import 'package:ovorideuser/data/controller/ride/all_ride_controller.dart';
import 'package:ovorideuser/data/repo/auth/general_setting_repo.dart';
import 'package:ovorideuser/data/repo/menu_repo/menu_repo.dart';
import 'package:ovorideuser/data/services/background_pusher_service.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/screens/home/home_screen.dart';
import 'package:ovorideuser/presentation/screens/profile_and_settings/profile_and_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ovorideuser/presentation/screens/ride/ride_activity_screen.dart';
import 'package:ovorideuser/presentation/screens/package/packages_screen.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/data/repo/package/package_repo.dart';
import 'package:ovorideuser/presentation/screens/reservation/reservations_screen.dart';
import 'package:ovorideuser/data/controller/reservation/reservation_controller.dart';
import 'package:ovorideuser/data/repo/reservation/reservation_repo.dart';
import '../../../core/utils/dimensions.dart';
import '../../../core/utils/my_color.dart';
import '../../components/will_pop_widget.dart';
import '../../packages/flutter_floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import '../drawer/drawer_screen.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  late GlobalKey<ScaffoldState> _dashBoardScaffoldKey;
  late List<Widget> _widgets;
  int selectedIndex = 0;
  bool isPackageEnabled = true;
  bool isReservationEnabled = true;

  @override
  void initState() {
    // Handle both int and List<int> arguments
    dynamic args = Get.arguments;
    int index = 0;
    if (args is int) {
      index = args;
    } else if (args is List && args.isNotEmpty) {
      index = args[0] is int ? args[0] : 0;
    }
    selectedIndex = index;
    super.initState();

    Get.put(GeneralSettingRepo(apiClient: Get.find()));
    Get.put(MenuRepo(apiClient: Get.find()));
    Get.put(MyMenuController(menuRepo: Get.find(), repo: Get.find()));
    final pusherController = Get.put(GlobalPusherController(apiClient: Get.find()));
    
    // Check if package and reservation systems are enabled
    final LocalStorageService localStorage = Get.find();
    isPackageEnabled = localStorage.isPackageEnabled();
    isReservationEnabled = localStorage.isReservationEnabled();
    
    // Initialize Package Controller only if enabled
    if (isPackageEnabled) {
      Get.put(PackageRepo(apiClient: Get.find()));
      Get.put(PackageController(packageRepo: Get.find()));
    }
    
    // Initialize Reservation Controller only if enabled
    if (isReservationEnabled) {
      Get.put(ReservationRepo(apiClient: Get.find()));
      Get.put(ReservationController(reservationRepo: Get.find()));
    }
    
    _dashBoardScaffoldKey = GlobalKey<ScaffoldState>();

    // Build widget list based on enabled features
    _widgets = <Widget>[
      HomeScreen(dashBoardScaffoldKey: _dashBoardScaffoldKey),
      RideActivityScreen(
        onBackPress: () {
          changeScreen(0);
        },
      ),
    ];
    
    // Add package or reservation screen based on what's enabled
    if (isPackageEnabled && isReservationEnabled) {
      // If both are enabled, show packages by default (can be changed to show both)
      _widgets.add(const PackagesScreen());
    } else if (isPackageEnabled) {
      _widgets.add(const PackagesScreen());
    } else if (isReservationEnabled) {
      _widgets.add(const ReservationsScreen());
    }
    
    // Always add settings screen at the end
    _widgets.add(const ProfileAndSettingsScreen());
    
    WidgetsBinding.instance.addPostFrameCallback((t) {
      pusherController.ensureConnection();
      
      // Initialize background Pusher service for notifications
      BackgroundPusherService().initialize();
    });
  }
  
  @override
  void dispose() {
    BackgroundPusherService().dispose();
    super.dispose();
  }

  void closeDrawer() {
    _dashBoardScaffoldKey.currentState!.closeEndDrawer();
  }

  void changeScreen(int val) {
    setState(() {
      selectedIndex = val;
    });
  }

  List<FloatingNavbarItem> _buildNavItems() {
    List<FloatingNavbarItem> items = [
      FloatingNavbarItem(
        icon: LineIcons.home,
        title: MyStrings.home.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == 0 ? MyIcons.homeActive : MyIcons.home,
          color: selectedIndex == 0 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
      FloatingNavbarItem(
        icon: LineIcons.city,
        title: MyStrings.activity.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == 1 ? MyIcons.activityActive : MyIcons.activity,
          color: selectedIndex == 1 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
    ];

    // Add package or reservation tab based on what's enabled
    if (isPackageEnabled && isReservationEnabled) {
      // Show packages if both are enabled (can be customized to show user preference)
      items.add(
        FloatingNavbarItem(
          icon: LineIcons.box,
          title: MyStrings.packages.tr,
          customWidget: Icon(
            LineIcons.box,
            color: selectedIndex == 2 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
          ),
        ),
      );
    } else if (isPackageEnabled) {
      items.add(
        FloatingNavbarItem(
          icon: LineIcons.box,
          title: MyStrings.packages.tr,
          customWidget: Icon(
            LineIcons.box,
            color: selectedIndex == 2 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
          ),
        ),
      );
    } else if (isReservationEnabled) {
      items.add(
        FloatingNavbarItem(
          icon: LineIcons.calendarAlt,
          title: MyStrings.reservations.tr,
          customWidget: Icon(
            LineIcons.calendarAlt,
            color: selectedIndex == 2 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
          ),
        ),
      );
    }

    // Always add menu tab at the end
    int menuIndex = (isPackageEnabled || isReservationEnabled) ? 3 : 2;
    items.add(
      FloatingNavbarItem(
        icon: LineIcons.list,
        title: MyStrings.menu.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == menuIndex ? MyIcons.menuActive : MyIcons.menu,
          color: selectedIndex == menuIndex ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        MyUtils.closeKeyboard();
      },
      child: AnnotatedRegionWidget(
        systemNavigationBarColor: MyColor.colorWhite,
        statusBarColor: MyColor.transparentColor,
        child: GetBuilder<MyMenuController>(
          builder: (controller) {
            return Scaffold(
              key: _dashBoardScaffoldKey,
              extendBody: true,
              endDrawer: AppDrawerScreen(
                closeFunction: closeDrawer,
                callback: (val) {
                  selectedIndex = val;
                  setState(() {});
                  closeDrawer(); // closeDrawer
                },
              ),
              body: WillPopWidget(child: IndexedStack(index: selectedIndex, children: _widgets)),
              bottomNavigationBar: FloatingNavbar(
                inLine: true,
                fontSize: 11,
                backgroundColor: MyColor.colorWhite,
                unselectedItemColor: MyColor.bodyMutedTextColor,
                selectedItemColor: MyColor.primaryColor,
                borderRadius: Dimensions.space50,
                itemBorderRadius: Dimensions.space50,
                selectedBackgroundColor: MyColor.primaryColor.withValues(
                  alpha: 0.09,
                ),
                onTap: (int val) {
                  controller.repo.apiClient.storeCurrentTab(val.toString());
                  changeScreen(val);
                  if (Get.isRegistered<AllRideController>()) {
                    Get.find<AllRideController>().changeTab(0);
                  }
                },
                margin: const EdgeInsetsDirectional.only(
                  start: Dimensions.space20,
                  end: Dimensions.space20,
                  bottom: Dimensions.space15,
                ),
                currentIndex: selectedIndex,
                items: _buildNavItems(),
              ),
            );
          },
        ),
      ),
    );
  }
}
