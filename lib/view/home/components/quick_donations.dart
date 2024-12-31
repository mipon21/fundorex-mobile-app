import 'package:flutter/material.dart';
import 'package:fundorex/helper/extension/string_extension.dart';
import 'package:fundorex/service/quick_donation_dropdown_service.dart';
import 'package:fundorex/service/rtl_service.dart';
import 'package:fundorex/view/payment/donation_payment_choose_page.dart';
import 'package:fundorex/view/utils/common_helper.dart';
import 'package:fundorex/view/utils/common_styles.dart';
import 'package:fundorex/view/utils/constant_colors.dart';
import 'package:fundorex/view/utils/others_helper.dart';
import 'package:provider/provider.dart';

import '../../../service/campaign_details_service.dart';

class QuickDonations extends StatelessWidget {
  const QuickDonations({super.key, required this.amountController});

  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    ConstantColors cc = ConstantColors();

    return Consumer<QuickDonationDropdownService>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonHelper().titleCommon('Quick Donations'),
          sizedBoxCustom(18),
          provider.campaignDropdownList.isNotEmpty
              ? Consumer<RtlService>(
                  builder: (context, rtlP, child) => Row(
                    children: [
                      // Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: cc.greySecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: provider.selectedCampaign,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: cc.greyFour,
                              ),
                              iconSize: 26,
                              elevation: 17,
                              style: TextStyle(color: cc.greyFour),
                              onChanged: (newValue) {
                                if (newValue != null &&
                                    provider.campaignDropdownList
                                        .contains(newValue)) {
                                  provider.setCampaignValue(newValue);

                                  // Setting the ID of the selected value
                                  provider.setCampaignId(
                                    provider.campaignDropdownIndexList[provider
                                        .campaignDropdownList
                                        .indexOf(newValue)],
                                  );
                                }
                              },
                              items: provider.campaignDropdownList
                                  .toSet() // Remove duplicate entries if any
                                  .map<DropdownMenuItem<String>>((value) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cc.greyPrimary.withOpacity(.8),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Donate Button
                      SizedBox(
                        width: 90,
                        child: CommonHelper().buttonPrimary('Donate', () {
                          if (provider.selectedCampaignId != null) {
                            Provider.of<CampaignDetailsService>(context,
                                    listen: false)
                                .fetchCampaignDetails(
                              context: context,
                              campaignId: provider.selectedCampaignId,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    DonationPaymentChoosePage(
                                  campaignId: provider.selectedCampaignId,
                                ),
                              ),
                            );
                          } else {
                            'Please select a campaign'.tr().showToast();
                          }
                        }, paddingVertical: 16, borderRadius: 5),
                      ),
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
