import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/shimmer/create_ride_shimmer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/bottomsheet/ride_meassage_bottom_sheet_body.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_offer_rate_widget.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_select_payment_method.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/passenger_bottom_sheet.dart';
import 'package:ovorideuser/presentation/widgets/schedule_ride_bottom_sheet.dart';

class RideCreateForm extends StatelessWidget {
  const RideCreateForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MyStrings.findDriver.tr,
              style: boldLarge.copyWith(
                color: MyColor.getRideTitleColor(),
                fontWeight: FontWeight.w500,
                fontSize: Dimensions.fontTitleLarge,
              ),
            ),
            spaceDown(Dimensions.space10),
            // Show scheduled ride info if scheduled
            if (controller.isScheduledRide && controller.scheduledDateTime != null) ...[
              Container(
                padding: EdgeInsets.all(Dimensions.space12),
                decoration: BoxDecoration(
                  color: MyColor.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  border: Border.all(color: MyColor.primaryColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: MyColor.primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: Dimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MyStrings.scheduled.tr,
                            style: semiBoldDefault.copyWith(
                              color: MyColor.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: Dimensions.space5),
                          Text(
                            '${controller.scheduledDateTime!.day}/${controller.scheduledDateTime!.month}/${controller.scheduledDateTime!.year} at ${controller.scheduledDateTime!.hour}:${controller.scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                            style: regularSmall.copyWith(
                              color: MyColor.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: MyColor.primaryColor, size: 20),
                      onPressed: () {
                        controller.clearScheduledDateTime();
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              spaceDown(Dimensions.space12),
            ],
            if (controller.isLoading) ...[
              CreateRideShimmer(),
            ] else ...[
              // Only show payment method selection when payment system is enabled
              if (controller.homeRepo.apiClient.isPaymentSystemEnabled()) ...[
                InkWell(
                  onTap: () {
                    if (controller.isPriceLoading == false) {
                      CustomBottomSheet(
                        child: const HomeSelectPaymentMethod(),
                      ).customBottomSheet(context);
                    }
                  },
                  child: InnerShadowContainer(
                  width: double.infinity,
                  backgroundColor: MyColor.neutral50,
                  borderRadius: Dimensions.largeRadius,
                  blur: 6,
                  offset: Offset(3, 3),
                  shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                  isShadowTopLeft: true,
                  isShadowBottomRight: true,
                  padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (controller.selectedPaymentMethod.id == '-1' || controller.selectedPaymentMethod.id == '-9') ...[
                            CustomSvgPicture(
                              image: MyIcons.money,
                              color: MyColor.primaryColor,
                              width: Dimensions.space30,
                              height: Dimensions.space30,
                            ),
                          ] else ...[
                            MyImageWidget(
                              imageUrl: '${UrlContainer.domainUrl}/${controller.gatewayImagePath}/${controller.selectedPaymentMethod.method?.image}',
                              width: Dimensions.space30,
                              height: Dimensions.space30,
                              boxFit: BoxFit.fitWidth,
                              radius: 4,
                            ),
                          ],
                          spaceSide(Dimensions.space10),
                          Text(
                            (controller.selectedPaymentMethod.id == '-1' ? MyStrings.paymentMethod.tr : controller.selectedPaymentMethod.method?.name ?? MyStrings.paymentMethod).tr,
                            style: regularDefault.copyWith(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: MyColor.getRideSubTitleColor(),
                        size: 16,
                      ),
                    ],
                    ),
                  ),
                ),
                spaceDown(Dimensions.space15),
              ],
              // Only show offer rate selection when prices can be shown
              if (Get.find<LocalStorageService>().canShowPrices()) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          if (controller.selectedService.id != '-99') {
                            if (controller.isPriceLoading == false) {
                              controller.updateMainAmount(controller.mainAmount);
                              CustomBottomSheet(child: const HomeOfferRateWidget()).customBottomSheet(context);
                            }
                          } else {
                            CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                          }
                      },
                      child: InnerShadowContainer(
                        width: double.infinity,
                        backgroundColor: MyColor.neutral50,
                        borderRadius: Dimensions.largeRadius,
                        blur: 6,
                        offset: Offset(3, 3),
                        shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                        isShadowTopLeft: true,
                        isShadowBottomRight: true,
                        padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  controller.mainAmount == 0 ? MyStrings.offerYourRate.tr : '${StringConverter.formatDouble(controller.mainAmount.toString())} ${controller.defaultCurrency}',
                                  style: regularDefault.copyWith(
                                    color: MyColor.bodyTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: MyColor.getRideSubTitleColor(),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    spaceSide(Dimensions.space15),
                  ],
                ),
                spaceDown(Dimensions.space15),
              ] else ...[
                // When payment is disabled, add spacing
                spaceDown(Dimensions.space15),
              ],
              // Passenger selection (always shown regardless of payment system)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () {
                        if (controller.selectedService.id != '-99') {
                          if (controller.isPriceLoading == false) {
                            CustomBottomSheet(
                              child: const PassengerBottomSheet(),
                            ).customBottomSheet(context);
                          }
                        } else {
                          CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                        }
                      },
                      child: InnerShadowContainer(
                        width: double.infinity,
                        backgroundColor: MyColor.neutral50,
                        borderRadius: Dimensions.largeRadius,
                        blur: 6,
                        offset: Offset(3, 3),
                        shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                        isShadowTopLeft: true,
                        isShadowBottomRight: true,
                        padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomSvgPicture(
                                  image: MyIcons.user,
                                  color: MyColor.primaryColor,
                                ),
                                spaceSide(Dimensions.space8),
                                Text(
                                  "${controller.passenger.toString()} ${MyStrings.person.tr}",
                                  style: regularDefault.copyWith(),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: MyColor.getRideSubTitleColor(),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space15),
              // Buttons: Find Driver (Now), Book for Later, and Reserve Ride
              // Show based on instant ride and reservation toggles
              if (controller.homeRepo.apiClient.isInstantRideEnabled()) ...[
                // When instant ride is enabled - show Find Driver prominently
                RoundedButton(
                  text: MyStrings.findDriver.tr,
                  isLoading: controller.isSubmitLoading && !controller.isScheduledRide,
                  press: () {
                    if (controller.isValidForNewRide()) {
                      controller.clearScheduledDateTime();
                      controller.createRide();
                    }
                  },
                  isOutlined: false,
                ),
                const SizedBox(height: Dimensions.space12),
                Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: MyStrings.bookForLater.tr,
                        isLoading: controller.isSubmitLoading && controller.isScheduledRide,
                        press: () {
                          if (controller.isValidForNewRide()) {
                            Get.bottomSheet(
                              ScheduleRideBottomSheet(
                                onScheduleSelected: (dateTime) {
                                  controller.setScheduledDateTime(dateTime);
                                  controller.createRide();
                                },
                              ),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );
                          }
                        },
                        isOutlined: true,
                        textColor: MyColor.primaryColor,
                        bgColor: MyColor.transparentColor,
                        borderColor: MyColor.primaryColor,
                      ),
                    ),
                    if (Get.find<LocalStorageService>().isReservationEnabled()) ...[
                      const SizedBox(width: Dimensions.space12),
                      Expanded(
                        child: RoundedButton(
                          text: MyStrings.reserveRide.tr,
                          press: () {
                            Get.toNamed(RouteHelper.createReservationScreen);
                          },
                          isOutlined: true,
                          textColor: MyColor.greenSuccessColor,
                          bgColor: MyColor.transparentColor,
                          borderColor: MyColor.greenSuccessColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                // When instant ride is disabled - show Book for Later and Reserve Ride
                Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: MyStrings.bookForLater.tr,
                        isLoading: controller.isSubmitLoading && controller.isScheduledRide,
                        press: () {
                          if (controller.isValidForNewRide()) {
                            Get.bottomSheet(
                              ScheduleRideBottomSheet(
                                onScheduleSelected: (dateTime) {
                                  controller.setScheduledDateTime(dateTime);
                                  controller.createRide();
                                },
                              ),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );
                          }
                        },
                        isOutlined: false,
                        textColor: MyColor.colorWhite,
                        bgColor: MyColor.primaryColor,
                      ),
                    ),
                    if (Get.find<LocalStorageService>().isReservationEnabled()) ...[
                      const SizedBox(width: Dimensions.space12),
                      Expanded(
                        child: RoundedButton(
                          text: MyStrings.reserveRide.tr,
                          press: () {
                            Get.toNamed(RouteHelper.createReservationScreen);
                          },
                          isOutlined: true,
                          textColor: MyColor.greenSuccessColor,
                          bgColor: MyColor.transparentColor,
                          borderColor: MyColor.greenSuccessColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              // Note button below
              spaceDown(Dimensions.space12),
              Center(
                child: IconButton(
                  onPressed: () {
                    if (controller.isPriceLoading == false) {
                      CustomBottomSheet(
                        child: const RideMassageBottomSheet(),
                      ).customBottomSheet(context);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12, vertical: Dimensions.space12),
                    decoration: BoxDecoration(
                      color: MyColor.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        Dimensions.largeRadius,
                      ),
                      border: Border.all(
                        color: MyColor.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSvgPicture(
                          image: MyIcons.note,
                          color: MyColor.primaryColor,
                          height: Dimensions.space20,
                          width: Dimensions.space20,
                        ),
                        const SizedBox(width: Dimensions.space8),
                        Text(
                          MyStrings.addNote.tr,
                          style: regularDefault.copyWith(
                            color: MyColor.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
