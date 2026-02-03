import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/user_package_card.dart';
import 'package:ovorideuser/presentation/screens/package/package_detail_screen.dart';

class MyPackagesScreen extends StatefulWidget {
  const MyPackagesScreen({Key? key}) : super(key: key);

  @override
  State<MyPackagesScreen> createState() => _MyPackagesScreenState();
}

class _MyPackagesScreenState extends State<MyPackagesScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<PackageController>().loadMyPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(MyStrings.myPackages.tr),
        backgroundColor: MyColor.primaryColor,
      ),
      body: GetBuilder<PackageController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          if (controller.myPackageList.isEmpty) {
            return const NoDataWidget();
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadMyPackages(),
            child: ListView.builder(
              padding: EdgeInsets.all(Dimensions.space15),
              itemCount: controller.myPackageList.length,
              itemBuilder: (context, index) {
                final userPackage = controller.myPackageList[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.space15),
                  child: UserPackageCard(
                    userPackage: userPackage,
                    packageImagePath: controller.packageImagePath,
                    serviceImagePath: controller.serviceImagePath,
                    driverImagePath: controller.driverImagePath,
                    onTap: () {
                      Get.to(() => PackageDetailScreen(
                        userPackage: userPackage,
                        packageImagePath: controller.packageImagePath,
                        driverImagePath: controller.driverImagePath,
                        serviceImagePath: controller.serviceImagePath,
                      ));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
