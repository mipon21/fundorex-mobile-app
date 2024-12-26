// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundorex/service/donate_service.dart';
import 'package:fundorex/service/event_book_pay_service.dart';
import 'package:fundorex/service/pay_services/payment_choose_service.dart';
import 'package:fundorex/service/rtl_service.dart';
import 'package:fundorex/view/utils/constant_colors.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../utils/others_helper.dart';

class RazorpayPaymentPage extends StatefulWidget {
  const RazorpayPaymentPage(
      {Key? key,
      required this.amount,
      required this.name,
      required this.phone,
      required this.email,
      required this.isFromEventBook})
      : super(key: key);

  final amount;
  final name;
  final phone;
  final email;
  final isFromEventBook;

  @override
  _RazorpayPaymentPageState createState() => _RazorpayPaymentPageState();
}

class _RazorpayPaymentPageState extends State<RazorpayPaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    initializeRazorPay();
  }

  void initializeRazorPay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    launchRazorPay(context);
  }

  void launchRazorPay(BuildContext context) {
    double amountToPay = double.parse(widget.amount) * 100;

    var options = {
      'key':
          Provider.of<PaymentChooseService>(context, listen: false).publicKey ??
              '',
      'amount': "$amountToPay",
      'name': widget.name,
      'description': ' ',
      'prefill': {'contact': widget.phone, 'email': widget.email}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Sucessfull");

    if (widget.isFromEventBook == true) {
      Provider.of<EventBookPayService>(context, listen: false)
          .makePaymentSuccess(context);
    } else {
      Provider.of<DonateService>(context, listen: false)
          .makePaymentSuccess(context);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payemt Failed");
    Provider.of<DonateService>(context, listen: false).setLoadingFalse();
    if (widget.isFromEventBook == true) {
      Provider.of<EventBookPayService>(context, listen: false)
          .doNext(context, paymentFailed: true);
    } else {
      Provider.of<DonateService>(context, listen: false)
          .doNext(context, paymentFailed: true);
    }
    // print("${response.code}\n${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // print("Payment Failed");
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        await OthersHelper().showPaymentWarning(context,
            isFromEventBook: widget.isFromEventBook);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text("Razorpay"),
        ),
        body: SizedBox(
          height: size.height,
          width: size.width,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(
                      top: 30, bottom: 20, left: 25, right: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: ConstantColors().greyFour,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Consumer<RtlService>(
                        builder: (context, rtlP, child) => Expanded(
                          flex: 1,
                          child: Text(
                            rtlP.currencyDirection == 'left'
                                ? "${rtlP.currency}${widget.amount}"
                                : "${widget.amount}${rtlP.currency}",
                            textAlign: rtlP.direction == 'ltr'
                                ? TextAlign.right
                                : TextAlign.left,
                            style: TextStyle(
                              color: ConstantColors().greyFour,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget textField(Size size, String text, bool isNumerical,
      TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height / 50),
      child: SizedBox(
        height: size.height / 15,
        width: size.width / 1.1,
        child: TextField(
          controller: controller,
          keyboardType: isNumerical ? TextInputType.number : null,
          decoration: InputDecoration(
            hintText: text,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
