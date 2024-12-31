// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fundorex/service/donate_service.dart';
import 'package:fundorex/service/event_book_pay_service.dart';
import 'package:fundorex/service/pay_services/payment_choose_service.dart';
import 'package:fundorex/view/utils/config.dart';
import 'package:fundorex/view/utils/constant_colors.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StripeService with ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? paymentIntentData;

  void setLoadingTrue() {
    isLoading = true;
    notifyListeners();
  }

  void setLoadingFalse() {
    isLoading = false;
    notifyListeners();
  }

  // Display the payment sheet
  Future<void> displayPaymentSheet(BuildContext context, {required bool isFromEventBook}) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((_) async {
        print('Stripe payment successful');
        if (isFromEventBook) {
          Provider.of<EventBookPayService>(context, listen: false).makePaymentSuccess(context);
        } else {
          Provider.of<DonateService>(context, listen: false).makePaymentSuccess(context);
        }
        paymentIntentData = null;
      }).onError((error, stackTrace) {
        _handlePaymentError(context, isFromEventBook, error, stackTrace);
      });
    } on StripeException catch (e) {
      debugPrint('Stripe Exception: $e');
      _handlePaymentError(context, isFromEventBook);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _handlePaymentError(context, isFromEventBook);
    }
  }

  // Helper method to calculate the amount for Stripe (convert to cents)
  String calculateAmount(String amount) {
    final parsedAmount = (int.parse(amount)) * 100;
    return parsedAmount.toStringAsFixed(0);
  }

  // Create a payment intent with Stripe
  Future<Map<String, dynamic>?> createPaymentIntent(String amount, String currency, BuildContext context) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var headers = {
        'Authorization': 'Bearer ${Provider.of<PaymentChooseService>(context, listen: false).secretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: headers,
      );

      var responseData = jsonDecode(response.body);

      // Ensure data types are consistent
      if (responseData['order_id'] is int) {
        responseData['order_id'] = responseData['order_id'].toString();
      }

      debugPrint('Payment Intent Response: $responseData');
      return responseData;
    } catch (error) {
      debugPrint('Error creating payment intent: $error');
      return null;
    }
  }

  // Main payment logic
  Future<void> makePayment(BuildContext context, {required bool isFromEventBook}) async {
    var amount, name, email;

    if (isFromEventBook) {
      final eventService = Provider.of<EventBookPayService>(context, listen: false);
      amount = double.parse(eventService.eventPrice).toStringAsFixed(0);
      name = eventService.name;
      email = eventService.email;
    } else {
      final donateService = Provider.of<DonateService>(context, listen: false);
      amount = (donateService.donationAmountWithTips + donateService.transactionFeeAmount).toString();
      name = donateService.userEnteredNameWhileDonating;
      email = donateService.userEnteredEmailWhileDonating;
    }

    try {
      var publishableKey = await getStripeKey();
      Stripe.publishableKey = publishableKey;
      Stripe.instance.applySettings();

      paymentIntentData = await createPaymentIntent(amount, 'USD', context);

      if (paymentIntentData != null && paymentIntentData!['order_id'] is int) {
        paymentIntentData!['order_id'] = paymentIntentData!['order_id'].toString();
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: name,
        ),
      );

      displayPaymentSheet(context, isFromEventBook: isFromEventBook);
    } catch (e, s) {
      debugPrint('Payment exception: $e $s');
      _handlePaymentError(context, isFromEventBook);
    }
  }

  // Fetch the Stripe key from the server
  Future<String> getStripeKey() async {
    const defaultPublicKey = 'pk_test_51GwS1SEmGOuJLTMsIeYKFtfAT3o3Fc6IOC7wyFmmxA2FIFQ3ZigJ2z1s4ZOweKQKlhaQr1blTH9y6HR2PMjtq1Rx00vqE8LO0x';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    var response = await http.post(
      Uri.parse('$baseApi/user/payment-gateway-list'),
      headers: headers,
    );

    if (response.statusCode == 201) {
      var paymentList = jsonDecode(response.body)['gateway_list'];
      for (var gateway in paymentList) {
        if (gateway['name'] == 'stripe') {
          return gateway['public_key'] ?? defaultPublicKey;
        }
      }
    }

    return defaultPublicKey;
  }

  // Handle payment failure
  void _handlePaymentError(BuildContext context, bool isFromEventBook, [dynamic error, dynamic stackTrace]) {
    debugPrint('Payment failed: $error $stackTrace');
    if (isFromEventBook) {
      Provider.of<EventBookPayService>(context, listen: false).doNext(context, paymentFailed: true);
    } else {
      Provider.of<DonateService>(context, listen: false).doNext(context, paymentFailed: true);
    }
  }
}

// Display a payment failure alert
class StripeFailedAlert extends StatelessWidget {
  const StripeFailedAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment failed'),
      actions: [
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Provider.of<PaymentChooseService>(context, listen: false).setLoadingFalse();
          },
          child: Text(
            'Ok',
            style: TextStyle(color: ConstantColors().primaryColor),
          ),
        ),
      ],
    );
  }
}
