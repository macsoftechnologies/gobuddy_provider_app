// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dio/dio.dart';

class Repository {
  static final Dio dio = Dio();

  static Options headerParameters() {
    Options options = Options(
      contentType: Headers.jsonContentType,
      headers: {},
    );
    dio.interceptors.add(LogInterceptor());
    return options;
  }

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Charset': 'utf-8',
    };
  }

  initializeInterceptors() {
    dio.interceptors.add(LogInterceptor());
  }

  static getErrorResponse() {
    return {
      "status": {
        "type": "Error",
        "message": "Server Errors",
        "code": 200,
        "error": "true",
      },
    };
  }

  // ignore: non_constant_identifier_names
  static Future<dynamic> postApiService(dynamic endpoint, dynamic inputData) async {
    var formData = FormData.fromMap(inputData);
    try {
      Response response = await dio.post(
        endpoint, // Replace with your API endpoint
        data: formData,
      );
      print('Response: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response data: ${e.response!.data}');
        print('Error response headers: ${e.response!.headers}');
        return e;
      } else {
        print('Error sending request: $e');
        return e;
      }
    }
  }

  static Future<String> NpostApiService(
  String endpoint,
  Map<String, dynamic> inputData,
) async {
  final formData = FormData.fromMap(inputData);

  try {
    final response = await dio.post(
      endpoint,
      data: formData,
    );

    print('Response: ${response.data}');
    return response.data.toString(); // ✅ always String
  }
  on DioException catch (e) {
    if (e.response != null) {
      print('Error response data: ${e.response!.data}');
      print('Error response headers: ${e.response!.headers}');
    } else {
      print('Error sending request: ${e.message}');
    }

    throw e; // ✅ THROW, don’t return
  }
}



    static Future<dynamic> postApiRawService(dynamic endpoint, dynamic inputData) async {
    try {
      Response response = await dio.post(
        endpoint,
        data: json.encode(inputData),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

      print('Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response data: ${e.response!.data}');
        print('Error response headers: ${e.response!.headers}');
        return e.toString();
      } else {
        print('Error sending request: $e');
        return e.toString();
      }
    }
  }



  // ignore: non_constant_identifier_names
  static Future<dynamic> postApiServiceWithJson(dynamic endpoint, dynamic inputData) async {
    
    try {
      Response response = await dio.post(
        endpoint, // Replace with your API endpoint
        data: inputData,
      );
      print('Response: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response data: ${e.response!.data}');
        print('Error response headers: ${e.response!.headers}');
        return e;
      } else {
        print('Error sending request: $e');
        return e;
      }
    }
  }

  static Future<dynamic> postimagesApiService(dynamic endpoint, dynamic formData) async {
  
    try {
      Response response = await dio.post(
        endpoint, // Replace with your API endpoint
        data: formData,
      );
      print('Response: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response data: ${e.response!.data}');
        print('Error response headers: ${e.response!.headers}');
        return e;
      } else {
        print('Error sending request: $e');
        return e;
      }
    }
  }
  static Future<dynamic> getApiService(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      Response response = await dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: getHeaders()),
      );

      print('GET Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('GET Error response data: ${e.response!.data}');
        print('GET Error response headers: ${e.response!.headers}');
        return e.response!.data; // return error data
      } else {
        print('Error sending GET request: ${e.message}');
        return getErrorResponse();
      }
    }
  }



}

