import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/reservation/reservation_controller.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/reservation/widgets/reservation_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationsScreen extends StatefulWidget {
  final Function? onBackPress;
  const ReservationsScreen({Key? key, this.onBackPress}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load reservations
    final controller = Get.find<ReservationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyReservations();
      controller.loadActiveReservations();
      controller.loadUpcomingReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.secondaryScreenBgColor,
      appBar: CustomAppBar(
        title: MyStrings.reservations.tr,
        backBtnPress: () {
          if (widget.onBackPress != null) {
            widget.onBackPress!();
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          }
        },
        actionsWidget: [
          // Create reservation button in AppBar
          TextButton.icon(
            onPressed: () async {
              // Open website in browser using URL launcher
              final url = Uri.parse('${UrlContainer.domainUrl}/user/reservation/create');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                CustomSnackBar.error(errorList: ['Could not open reservation form']);
              }
            },
            icon: const Icon(Icons.add, color: MyColor.colorWhite, size: 20),
            label: Text(
              MyStrings.createReservation.tr,
              style: const TextStyle(
                color: MyColor.colorWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: MyColor.primaryColor.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GetBuilder<ReservationController>(
        builder: (controller) {
          return Column(
            children: [
              Container(
                color: MyColor.colorWhite,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: MyColor.primaryColor,
                  indicatorWeight: 3,
                  labelColor: MyColor.primaryColor,
                  unselectedLabelColor: MyColor.bodyTextColor,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: MyStrings.active.tr),
                    Tab(text: MyStrings.upcoming.tr),
                    Tab(text: MyStrings.history.tr),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Reservations Tab
                    _buildReservationList(
                      controller.activeReservationList,
                      MyStrings.noActiveReservations.tr,
                      controller.isLoading,
                    ),
                    // Upcoming Reservations Tab
                    _buildReservationList(
                      controller.upcomingReservationList,
                      MyStrings.noUpcomingReservations.tr,
                      controller.isLoading,
                    ),
                    // History Tab
                    _buildReservationList(
                      controller.historyReservationList.isEmpty ? controller.completedReservations + controller.cancelledReservations : controller.historyReservationList,
                      MyStrings.noReservationHistory.tr,
                      controller.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReservationList(List reservations, String emptyMessage, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (reservations.isEmpty) {
      return Center(
        child: NoDataWidget(
          text: emptyMessage,
        ),
      );
    }

    return RefreshIndicator(
      color: MyColor.primaryColor,
      backgroundColor: MyColor.colorWhite,
      onRefresh: () async {
        final controller = Get.find<ReservationController>();
        await controller.loadMyReservations();
        await controller.loadActiveReservations();
        await controller.loadUpcomingReservations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.space12),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return ReservationCard(
            reservation: reservations[index],
            serviceImagePath: Get.find<ReservationController>().serviceImagePath,
            driverImagePath: Get.find<ReservationController>().driverImagePath,
          );
        },
      ),
    );
  }
}
