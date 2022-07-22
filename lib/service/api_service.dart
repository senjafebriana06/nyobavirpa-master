import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nyobavirpa/config.dart';
import 'package:nyobavirpa/models/login_response_models.dart';
import 'package:nyobavirpa/models/register_request_models.dart';
import 'package:nyobavirpa/models/register_response_models.dart';
import 'package:nyobavirpa/service/shared_service.dart';

class APIService {
  static var client = http.Client();
  static Future<bool> login(LoginResponseModel model) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.http(Config.apiURL, Config.loginAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode == 200) {
      await SharedService.setLoginDetails(loginResponseJson(response.body));
      return true;
    } else {
      return false;
    }
  }

  static Future<RegisterResponseModel> register(
      RegisterRequestModel model) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.http(Config.apiURL, Config.registerAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );
    return registerResponseModel(response.body);
  }
}
