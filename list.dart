import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

int env = 0; // 1 to live
// mpesa credentials
String consumerKey = 'pqit27XxyX7naIlyvPVzd2GpH2nkmzej';
String consumerSecret = 'hmAYhaS4um8P3yzv';
String passkey =
    'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
String initiator = 'apiop37';
int businessShortcode = 174379;
int shortcode = 603021;
int store_shortcode = 600000;

// callback uris
// stk
String stk_callback = 'https://survtechnologies.co.ke/callbacks';

// register urls
String register_confirmation = 'https://survtechnologies.co.ke/confirmation';
String register_validation = 'https://survtechnologies.co.ke/validation';

//

// globals
Codec<String, String> base64_ = utf8.fuse(base64);
String environment = env == 0 ? 'sandbox' : 'api';
main(List<String> args) async {
  // String accessToken  = await get_access_token();
  // push_stk(1, 254716437799, 'TestDartPayment', "Please Pay");
  // var accessToken = await register_urls();
  var accessToken = await simulate_transaction(10, 'Test');

  print(accessToken);
}

// access token
Future get_access_token() async {
  var response = await http.get(
      "https://$environment.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      headers: {
        HttpHeaders.authorizationHeader:
            'Basic ' + base64_.encode('${consumerKey}:${consumerSecret}'),
        'Accept': 'application/json'
      });

  var resp = json.decode(response.body);

  return resp['access_token'];
}

// stk
Future push_stk(num amount, num phone, dynamic account,
    dynamic transaction_description) async {
  String accessToken = await get_access_token();

  DateFormat date = DateFormat('yyyyMMddHHmmss');
  String timestamp = date.format(DateTime.now());
  String password =
      base64_.encode('${businessShortcode}${passkey}${timestamp}');

  // transaction type

  String transactionType;
  if (businessShortcode == shortcode) {
    transactionType = 'CustomerPayBillOnline';
  } else {
    transactionType = 'CustomerBuyGoodsOnline';
  }

  if (env == 0) {
    transactionType = 'CustomerPayBillOnline';
    shortcode = businessShortcode;
  }

  Map<String, dynamic> body = {
    'BusinessShortCode': businessShortcode,
    'Password': password,
    'Timestamp': timestamp,
    'TransactionType': transactionType,
    'Amount': amount,
    'PartyA': phone,
    'PartyB': shortcode,
    'PhoneNumber': phone,
    'CallBackURL': stk_callback,
    'AccountReference': account,
    'TransactionDesc': transaction_description
  };

  var send_push = await http.post(
      'https://$environment.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
      body: json.encode(body),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $accessToken'
      });

  return json.decode(send_push.body);
}

/**
 * register urls
 * 
 * Please handle validation and confirmation on your
 * server scripts
 */
Future register_urls() async {
  String accessToken = await get_access_token();

  // handle tills
  if (businessShortcode == shortcode) {
    shortcode = businessShortcode;
  } else {
    shortcode = store_shortcode;
  }

  Map<String, dynamic> body = {
    'ShortCode': shortcode,
    'ResponseType': 'Completed',
    'ConfirmationURL': register_validation,
    'ValidationURL': register_validation
  };

  var response = await http.post(
      'https://$environment.safaricom.co.ke/mpesa/c2b/v1/registerurl',
      body: json.encode(body),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $accessToken'
      });

  return json.decode(response.body);
}

/**
 * Simulate Transaction
 * 
 * Please check the confirmation and validation responses on your server
 */
Future simulate_transaction(num amount, dynamic billRef, {num phone = 254708374149}) async {
  String accessToken = await get_access_token();

  Map<String, dynamic> body = {
    'ShortCode': businessShortcode,
    'CommandID': 'CustomerPayBillOnline',
    'Amount': amount,
    'Msisdn': phone,
    'BillRefNumber': billRef
  };

  var simulate_response =
      await http.post('https://$environment.safaricom.co.ke/mpesa/c2b/v1/simulate', body: json.encode(body), headers: {
    HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    HttpHeaders.contentTypeHeader: 'application/json'
  });

  return simulate_response.body;
}
