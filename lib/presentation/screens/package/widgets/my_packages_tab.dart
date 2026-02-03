import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/screens/package/package_detail_screen.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/user_package_card.dart';

class MyPackagesTab extends StatelessWidget {
  final bool showActiveOnly;
  const MyPackagesTab({Key? key, required this.showActiveOnly}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PackageController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const CustomLoader();
        }

        // Filter packages based on showActiveOnly flag
        final filteredPackages = showActiveOnly 
            ? controller.myPackageList.where((p) => p.status == 1).toList()
            : controller.myPackageList;

        if (filteredPackages.isEmpty) {
          return Center(
            child: NoDataWidget(
              text: showActiveOnly 
                  ? '${MyStrings.no.tr} ${MyStrings.active.tr.toLowerCase()} ${MyStrings.packages.tr.toLowerCase()}'
                  : MyStrings.noPackageFound.tr,
            ),
          );
        }

        return RefreshIndicator(
          color: MyColor.primaryColor,
          backgroundColor: MyColor.colorWhite,
          onRefresh: () async {
            await controller.loadMyPackages();
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
              vertical: Dimensions.space10,
            ),
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            itemCount: filteredPackages.length,
            separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space15),
            itemBuilder: (context, index) {
              final userPackage = filteredPackages[index];
              return UserPackageCard(
                userPackage: userPackage,
                packageImagePath: controller.packageImagePath,
                serviceImagePath: controller.serviceImagePath,
                driverImagePath: controller.driverImagePath,
                onTap: () {
                  // Navigate to package detail screen
                  Get.to(() => PackageDetailScreen(
                    userPackage: userPackage,
                    packageImagePath: controller.packageImagePath,
                    driverImagePath: controller.driverImagePath,
                    serviceImagePath: controller.serviceImagePath,
                  ));
                },
              );
            },
          ),
        );
      },
    );
  }
}
