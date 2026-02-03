import 'package:flutter/material.dart';
import 'package:ovorideuser/core/helper/date_converter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/services/local_storage_service.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';

import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../data/controller/payment_history/payment_history_controller.dart';
import '../../../components/animated_widget/expanded_widget.dart';
import '../../../components/column_widget/card_column.dart';

class CustomPaymentCard extends StatelessWidget {
  final int index;
  final int expandIndex;

  const CustomPaymentCard({
    super.key,
    required this.index,
    required this.expandIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentHistoryController>(
      builder: (controller) {
        final payment = controller.transactionList[index];

        return GestureDetector(
          onTap: () {
            controller.changeExpandIndex(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: MyColor.getCardBgColor(),
              boxShadow: MyUtils.getCardShadow(),
              borderRadius: BorderRadius.circular(Dimensions.moreRadius),
            ),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space16,
              vertical: Dimensions.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (Get.find<LocalStorageService>().canShowPrices())
                                Text(
                                  "${controller.currencySym}${StringConverter.formatNumber(payment.amount.toString())}",
                                  style: boldExtraLarge.copyWith(
                                    color: MyColor.getHeadingTextColor(),
                                  ),
                                ),
                              if (payment.transactionType != null) ...[
                                SizedBox(width: Dimensions.space8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.space5,
                                    vertical: Dimensions.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: payment.isWebTransaction 
                                    ? MyColor.colorPurple.withValues(alpha: 0.1)
                                    : MyColor.colorGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    payment.isWebTransaction ? 'WEB' : 'RIDE',
                                    style: boldDefault.copyWith(
                                      fontSize: 10,
                                      color: payment.isWebTransaction 
                                          ? MyColor.colorPurple 
                                          : MyColor.colorGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          spaceDown(Dimensions.space5),
                          Text(
                            payment.trxNumber ?? payment.ride?.uid ?? '',
                            style: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                          ),
                          if (payment.isWebTransaction && payment.remark != null) ...[
                            spaceDown(Dimensions.space3),
                            Text(
                              payment.remark!.replaceAll('_', ' ').capitalizeFirst ?? '',
                              style: regularSmall.copyWith(
                                color: MyColor.colorGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.space5,
                            vertical: Dimensions.space2,
                          ),
                          decoration: BoxDecoration(
                            color: MyUtils.paymentStatusColor(payment.paymentType ?? '1').withValues(alpha: 0.01),
                            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            border: Border.all(
                              color: MyUtils.paymentStatusColor(payment.paymentType ?? '0'),
                            ),
                          ),
                          child: Text(
                            MyUtils.paymentStatus(payment.paymentType ?? '1'),
                            style: boldDefault.copyWith(
                              fontSize: 16,
                              color: MyUtils.paymentStatusColor(
                                payment.paymentType ?? '0',
                              ),
                            ),
                          ),
                        ),
                        spaceDown(Dimensions.space15),
                        Text(
                          DateConverter.estimatedDate(
                            DateTime.tryParse('${payment.createdAt}') ?? DateTime.now(),
                          ),
                          style: regularSmall.copyWith(
                            color: MyColor.getBodyTextColor(),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ExpandedSection(
                  expand: controller.expandIndex == index,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomDivider(space: Dimensions.space15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (payment.isRidePayment) ...[
                            CardColumn(
                              header: MyStrings.pickUpLocation,
                              body: payment.ride?.pickupLocation ?? "",
                              bodyMaxLine: 5,
                              space: Dimensions.space10,
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            spaceDown(Dimensions.space10),
                            CardColumn(
                              alignmentEnd: false,
                              header: MyStrings.destination,
                              body: payment.ride?.destination ?? "",
                              bodyMaxLine: 5,
                              space: Dimensions.space8,
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                          if (payment.isWebTransaction) ...[
                            CardColumn(
                              header: "Transaction Type",
                              body: payment.remark?.replaceAll('_', ' ').capitalizeFirst ?? "Web Payment",
                              bodyMaxLine: 3,
                              space: Dimensions.space10,
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            spaceDown(Dimensions.space10),
                            CardColumn(
                              alignmentEnd: false,
                              header: "Description",
                              body: payment.description ?? "",
                              bodyMaxLine: 5,
                              space: Dimensions.space8,
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Dimensions.space10),
                      if (payment.isRidePayment)
                        Row(
                          children: [
                            Expanded(
                              child: CardColumn(
                                header: MyStrings.distance,
                                body: '${payment.ride?.getDistance()} ${MyUtils.getDistanceLabel(distance: payment.ride?.distance, unit: Get.find<ApiClient>().getDistanceUnit())}',
                                headerTextStyle: regularDefault,
                                bodyTextStyle: regularSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: MyColor.getTextColor().withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: CardColumn(
                                alignmentEnd: true,
                                header: MyStrings.duration,
                                body: payment.ride?.duration ?? '',
                                headerTextStyle: regularDefault,
                                bodyTextStyle: regularSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: MyColor.getTextColor().withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (payment.isWebTransaction)
                        Row(
                          children: [
                            Expanded(
                              child: CardColumn(
                                header: "Source",
                                body: payment.source?.capitalizeFirst ?? 'Website',
                                headerTextStyle: regularDefault,
                                bodyTextStyle: regularSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: MyColor.getTextColor().withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: CardColumn(
                                alignmentEnd: true,
                                header: "Type",
                                body: payment.trxType == '+' ? 'Credit' : payment.trxType == '-' ? 'Debit' : 'Payment',
                                headerTextStyle: regularDefault,
                                bodyTextStyle: regularSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: payment.trxType == '+' 
                                      ? MyColor.colorGreen 
                                      : payment.trxType == '-' 
                                          ? MyColor.colorRed 
                                          : MyColor.getTextColor().withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
