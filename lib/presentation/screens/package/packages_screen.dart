import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/available_packages_tab.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/my_packages_tab.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<PackageController>();
      controller.loadAvailablePackages();
      controller.loadMyPackages();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: Scaffold(
        backgroundColor: MyColor.secondaryScreenBgColor,
        appBar: CustomAppBar(
          title: MyStrings.packages.tr,
        ),
        body: Column(
          children: [
            // Tabs - matching RideActivityScreen style
            Container(
              color: MyColor.colorWhite,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: MyColor.colorWhite),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
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
                  tabs: [
                    Tab(text: 'Available'),
                    Tab(text: MyStrings.active.tr),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            
            // Tab Content
            Expanded(
              child: GetBuilder<PackageController>(
                builder: (controller) {
                  return TabBarView(
                    controller: _tabController,
                    children: const [
                      AvailablePackagesTab(),
                      MyPackagesTab(showActiveOnly: true),
                      MyPackagesTab(showActiveOnly: false),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
