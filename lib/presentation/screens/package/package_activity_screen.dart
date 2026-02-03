import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/available_packages_tab.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/my_packages_tab.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PackageActivityScreen extends StatefulWidget {
  final VoidCallback? onBackPress;
  const PackageActivityScreen({super.key, this.onBackPress});

  @override
  State<PackageActivityScreen> createState() => _PackageActivityScreenState();
}

class _PackageActivityScreenState extends State<PackageActivityScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this, initialIndex: selectedTab);
    
    WidgetsBinding.instance.addPostFrameCallback((time) {
      final controller = Get.find<PackageController>();
      // Load data based on selected tab
      if (selectedTab == 0) {
        controller.loadAvailablePackages();
      } else {
        controller.loadMyPackages();
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void changeTab(int index) {
    selectedTab = index;
    final controller = Get.find<PackageController>();
    
    if (index == 0) {
      controller.loadAvailablePackages();
    } else {
      controller.loadMyPackages();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.secondaryScreenBgColor,
      appBar: CustomAppBar(
        title: MyStrings.packages.tr,
        backBtnPress: () {
          if (Get.currentRoute == RouteHelper.dashboard) {
            if (widget.onBackPress != null) {
              widget.onBackPress?.call();
            }
          } else {
            Get.back();
          }
        },
      ),
      body: GetBuilder<PackageController>(
        builder: (controller) {
          return Column(
            children: [
              Container(
                color: MyColor.colorWhite,
                child: DefaultTabController(
                  length: 2,
                  initialIndex: selectedTab,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: MyColor.colorWhite),
                          ),
                        ),
                        child: TabBar(
                          controller: tabController,
                          tabAlignment: TabAlignment.start,
                          dividerColor: MyColor.borderColor,
                          indicator: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: MyColor.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.label,
                          isScrollable: true,
                          labelColor: MyColor.primaryColor,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          unselectedLabelColor: MyColor.colorBlack,
                          physics: const BouncingScrollPhysics(),
                          onTap: (i) {
                            changeTab(i);
                          },
                          tabs: [
                            Tab(text: MyStrings.availablePackages.tr),
                            Tab(text: MyStrings.myPackages.tr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space10,
                  ),
                  child: selectedTab == 0 
                      ? const AvailablePackagesTab()
                      : const MyPackagesTab(showActiveOnly: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
