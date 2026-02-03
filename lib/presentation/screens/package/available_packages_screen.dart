import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/controller/package/package_controller.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/package/package_model.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/screens/package/widgets/package_card.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class AvailablePackagesScreen extends StatefulWidget {
  const AvailablePackagesScreen({Key? key}) : super(key: key);

  @override
  State<AvailablePackagesScreen> createState() => _AvailablePackagesScreenState();
}

class _AvailablePackagesScreenState extends State<AvailablePackagesScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<PackageController>().loadAvailablePackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(MyStrings.packages.tr),
        backgroundColor: MyColor.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Get.toNamed(RouteHelper.myPackagesScreen);
            },
          ),
        ],
      ),
      body: GetBuilder<PackageController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          if (controller.packageList.isEmpty) {
            return const NoDataWidget();
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadAvailablePackages(),
            child: ListView.builder(
              padding: EdgeInsets.all(Dimensions.space15),
              itemCount: controller.packageList.length,
              itemBuilder: (context, index) {
                final package = controller.packageList[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.space15),
                  child: PackageCard(
                    package: package,
                    packageImagePath: controller.packageImagePath,
                    serviceImagePath: controller.serviceImagePath,
                    controller: controller,
                    onTap: () => _showPurchaseConfirmation(package, controller),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseConfirmation(package, PackageController controller) {
    final isPaymentEnabled = controller.packageRepo.apiClient.isPaymentSystemEnabled();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(MyStrings.confirmPurchase.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPaymentEnabled && Get.find<LocalStorageService>().canShowPrices())
              Text('${MyStrings.purchasePackageConfirm.tr} "${package.name}" ${MyStrings.for_.tr} ${package.price}?')
            else ...[
              Text('${MyStrings.purchasePackageConfirm.tr} "${package.name}"?'),
              if (!isPaymentEnabled) ...[
                SizedBox(height: 10),
                Text(
                  'Note: All payments and pricing will be handled directly with your assigned driver.',
                  style: TextStyle(fontSize: 12, color: MyColor.bodyMutedTextColor),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MyStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await controller.purchasePackage(package.id!);
              if (success) {
                if (!isPaymentEnabled) {
                  CustomSnackBar.success(
                    successList: ['Package purchased! Payment will be arranged with driver.'],
                  );
                }
                Get.toNamed(RouteHelper.myPackagesScreen);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MyColor.primaryColor),
            child: Text(MyStrings.confirm.tr),
          ),
        ],
      ),
    );
  }
}
