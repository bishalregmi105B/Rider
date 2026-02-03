import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/package_card.dart';

class AvailablePackagesTab extends StatelessWidget {
  const AvailablePackagesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PackageController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const CustomLoader();
        }

        if (controller.packageList.isEmpty) {
          return Center(
            child: NoDataWidget(
              text: MyStrings.noPackageFound.tr,
            ),
          );
        }

        return RefreshIndicator(
          color: MyColor.primaryColor,
          backgroundColor: MyColor.colorWhite,
          onRefresh: () async {
            await controller.loadAvailablePackages();
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
              vertical: Dimensions.space10,
            ),
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            itemCount: controller.packageList.length,
            separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space15),
            itemBuilder: (context, index) {
              final package = controller.packageList[index];
              return PackageCard(
                package: package,
                packageImagePath: controller.packageImagePath,
                serviceImagePath: controller.serviceImagePath,
                controller: controller,
                onTap: null, // Buy Now button handles purchase
              );
            },
          ),
        );
      },
    );
  }
}
