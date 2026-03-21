import 'dart:convert';

import 'package:gpspro/Config.dart';
import 'package:gpspro/model/Alert.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/model/PositionHistory.dart';
import 'package:gpspro/model/RouteReport.dart';
import 'package:gpspro/model/User.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class API {
  static String? serverURL;
  static String? socketURL;

  static Map<String, String> headers = {};

  static Future<http.Response?> login(email, password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] = "application/json; charset=utf-8";
    try {
      print(prefs.get('url').toString());
      serverURL = SERVER_URL;
      print(serverURL);
      final response = await http.post(
          Uri.parse(serverURL! +
              "/api/login?email=" +
              email +
              "&password=" +
              Uri.encodeComponent(password)),
          headers: headers);

      if (response.statusCode == 200) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<Device>?> getDevices() async {
    try {
      print("==> getDevices: Iniciando la función");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      print("==> getDevices: SharedPreferences obtenidas");

      String? userHash = prefs.getString('user_api_hash');
      String? language = prefs.getString('language');
      print("==> getDevices: user_api_hash=$userHash, language=$language");

      if (userHash == null || language == null) {
        print("==> getDevices: user_api_hash o language es null, retornando null");
        return null;
      }

      final url = serverURL! + "/api/get_devices?user_api_hash=" + userHash + "&lang=" + language;
      print("==> getDevices: URL=$url");

      final response = await http.get(Uri.parse(url));
      print("==> getDevices: Response recibida con status code ${response.statusCode}");

      if (response.statusCode == 200) {
        String body = response.body.replaceAll("ï»¿", "");
        print("==> getDevices: Body recibido: $body");

        Iterable list = json.decode(body);
        print("==> getDevices: JSON decodificado, elementos=${list.length}");

        List<Device> devices = list.map((model) => Device.fromJson(model)).toList();
        print("==> getDevices: Lista de dispositivos creada con ${devices.length} elementos");

        return devices;
      } else {
        print("==> getDevices: Status code != 200, retornando null");
        return null;
      }
    } catch (e, stack) {
      print("==> getDevices: ERROR: $e");
      print(stack);
      return null;
    }
  }


  static Future<PositionHistory?> getHistory(String deviceID, String fromDate,
      String fromTime, String toDate, String toTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/get_history?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang="+prefs.getString('language')! +
        "&from_date=" +
        fromDate +
        "&from_time=" +
        fromTime +
        "&to_date=" +
        toDate +
        "&to_time=" +
        toTime +
        "&device_id=" +
        deviceID));
    print(response.request);
    if (response.statusCode == 200) {
      return PositionHistory.fromJson(
          json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<RouteReport?> getReport(String deviceID, String fromDate,
      String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang="+prefs.getString('language')! +
        "&date_from=" +
        fromDate +
        "&devices[]=" +
        deviceID +
        "&date_to=" +
        toDate +
        "&format=pdf" +
        "&type=" +
        type.toString()+
        "&show_addresses=true"+
        "&daily=0&weekly=0&monthly=0"));
    if (response.statusCode == 200) {
      return RouteReport.fromJson(
          json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<RouteReport?> getReportGeofence(String deviceID, String fromDate,
      String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang="+prefs.getString('language')! +
        "&date_from=" +
        fromDate +
        "&devices[]=" +
        deviceID +
        "&geofences[]=0"+
        "&date_to=" +
        toDate +
        "&format=pdf" +
        "&type=" +
        type.toString()+
        "&show_addresses=true"+
        "&daily=0&weekly=0&monthly=0"));
    print(response.body);
    if (response.statusCode == 200) {
      return RouteReport.fromJson(
          json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }


  static Future<RouteReport?> getReportHtml(String deviceID, String fromDate,
      String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/generate_report?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang="+prefs.getString('language')! +
        "&date_from=" +
        fromDate +
        "&devices[]=" +
        deviceID +
        "&date_to=" +
        toDate +
        "&format=html" +
        "&type=" +
        type.toString()+
        "&show_addresses=true"+
        "&daily=0&weekly=0&monthly=0"));
    print(response.body);
    if (response.statusCode == 200) {
      return RouteReport.fromJson(
          json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<User?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.get(
      Uri.parse(
        serverURL! +
            "/api/get_user_data?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang=" +
            prefs.getString('language')!,
      ),
    );

    // 👇 Imprimir detalles de la respuesta en consola
    print("➡️ URL: ${response.request?.url}");
    print("⬅️ StatusCode: ${response.statusCode}");
    print("⬅️ Body: ${response.body}");

    if (response.statusCode == 200) {
      return User.fromJson(
        json.decode(response.body.replaceAll("ï»¿", "")),
      );
    } else {
      return null;
    }
  }


  static Future<User?> getGeofences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/get_user_data?user_api_hash=" +
        prefs.getString('user_api_hash')!+
        "&lang="+prefs.getString('language')!));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body.replaceAll("ï»¿", "")));
    } else {
      return null;
    }
  }

  static Future<http.Response?> getSendCommands(String id) async {
    try {
      print("🟢 Iniciando getSendCommands para id: $id");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userApiHash = prefs.getString('user_api_hash') ?? '';
      String language = prefs.getString('language') ?? 'en';

      String url = serverURL! +
          "/api/send_command_data?user_api_hash=$userApiHash&lang=$language";

      print("🌐 URL generada: $url");

      final response = await http.get(Uri.parse(url));

      print("📩 Respuesta recibida con status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ getSendCommands exitoso");
        return response;
      } else {
        print("⚠️ getSendCommands falló con status code: ${response.statusCode}");
        return null;
      }
    } catch (e, stackTrace) {
      print("❌ Error en getSendCommands: $e");
      print(stackTrace);
      return null;
    }
  }


  static Future<http.Response> sendCommands(dynamic body) async {
    try {
      print("🟢 Iniciando sendCommands con body: $body");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userApiHash = prefs.getString('user_api_hash') ?? '';
      String language = prefs.getString('language') ?? 'en';

      headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";

      String url = serverURL! + "/api/send_gprs_command?user_api_hash=$userApiHash&lang=$language";
      print("🌐 URL generada: $url");
      print("📤 Headers: $headers");

      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );

      print("📩 Respuesta recibida con status code: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ sendCommands exitoso");
      } else {
        print("⚠️ sendCommands falló con status code: ${response.statusCode}");
      }

      return response;
    } catch (e, stackTrace) {
      print("❌ Error en sendCommands: $e");
      print(stackTrace);
      rethrow; // re-lanza el error para manejarlo en el caller si se desea
    }
  }


  static Future<List<Geofence>?> getGeoFences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";

    String url = serverURL! +
        "/api/get_geofences?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang=" +
        prefs.getString('language')!;

    print("🔹 URL: $url");

    final response = await http.get(Uri.parse(url), headers: headers);

    print("🔹 Status Code: ${response.statusCode}");
    print("🔹 Body: ${response.body}");

    if (response.statusCode == 200) {
      var decoded = json.decode(response.body.replaceAll("ï»¿", ""));
      print("🔹 JSON decodificado: $decoded");

      // 🔹 Validar existencia de items y geofences
      if (decoded['items'] != null && decoded['items']['geofences'] != null) {
        Iterable list = decoded['items']['geofences'];
        print("🔹 Lista geofences: $list");

        if (list.isNotEmpty) {
          var geofences = list
              .map((model) => Geofence.fromJson(Map<String, dynamic>.from(model)))
              .toList();
          print("✅ Geofences parseados: $geofences");
          return geofences;
        } else {
          print("⚠️ La lista de geofences está vacía.");
          return [];
        }
      } else {
        print("⚠️ No se encontraron geofences en el response.");
        return [];
      }
    } else {
      print("❌ Error al obtener geofences. Código: ${response.statusCode}");
      return null;
    }
  }



  static Future<http.Response> addGeofence(fence) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/add_geofence?user_api_hash=" +
            prefs.getString('user_api_hash')!+"&lang="+prefs.getString('language')!),
        body: fence,
        headers: headers);
    return response;
  }

  static Future<http.Response> destroyGeofence(int id) async {
    final prefs = await SharedPreferences.getInstance();

    // Construimos la URL de manera segura
    final uri = Uri.parse(serverURL!).replace(
      path: "/api/destroy_geofence",
      queryParameters: {
        "user_api_hash": prefs.getString('user_api_hash') ?? "",
        "lang": prefs.getString('language') ?? "en",
        "geofence_id": id.toString(),
      },
    );

    // Llamada GET al endpoint
    final response = await http.get(uri, headers: headers);

    // Debug: imprime la request
    print(response.request);

    return response;
  }


  static Future<http.Response> addAlert(String request) async {
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/add_alert?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&lang="+prefs.getString('language')! +
            request),
        headers: headers);
    print(response.request);
    print(response.body);
    return response;
  }

  static Future<StreamedResponse> deletePermission(deviceId, fenceId) async {
    http.Request rq =
    http.Request('DELETE', Uri.parse(serverURL! + "/api/permissions"))
      ..headers;
    rq.headers.addAll(<String, String>{
      "Accept": "application/json",
      "Content-type": "application/json; charset=utf-8",
      "cookie": headers['cookie']!
    });
    rq.body = jsonEncode({"deviceId": deviceId, "geofenceId": fenceId});

    return http.Client().send(rq);
  }

  static Future<List<Alert>?> getAlertList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/get_alerts?user_api_hash=" +
            prefs.getString('user_api_hash')!+"&lang="+prefs.getString('language')!),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list =
      json.decode(response.body.replaceAll("ï»¿", ""))['items']['alerts'];
      if (list.isNotEmpty) {
        return list.map((model) => Alert.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<http.Response?> getSavedCommands(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(serverURL! +
        "/api/get_device_commands?user_api_hash=" +
        prefs.getString('user_api_hash')! +
        "&lang="+prefs.getString('language')! +
        "&device_id=$id"));
    if (response.statusCode == 200) {
      return response;
    } else {
      return null;
    }
  }

  static Future<List<Event>?> getEventList() async {
    print("📡 get Events");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";

    final url = Uri.parse(
      serverURL! +
          "/api/get_events?user_api_hash=" +
          prefs.getString('user_api_hash')! +
          "&lang=" +
          prefs.getString('language')!,
    );

    print("➡️ Request URL: $url");
    print("➡️ Request Headers: $headers");

    final response = await http.get(url, headers: headers);

    print("⬅️ Response Status: ${response.statusCode}");
    print("⬅️ Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Iterable list =
      json.decode(response.body.replaceAll("ï»¿", ""))['items']['data'];
      if (list.isNotEmpty) {
        return list.map((model) => Event.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }


  static Future<String> getGeocoder(lat, lng) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/geo_address?lat=$lat&lon=$lng&user_api_hash=" +
            prefs.getString('user_api_hash')!),
        headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "";
    }
  }

  static Future<http.Response> activateAlert(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/change_active_alert?user_api_hash=" +
            prefs.getString('user_api_hash')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<http.Response> changePassword(String newPassword, String retypePassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (serverURL == null) serverURL = SERVER_URL; // aseguramos que no sea null

    headers['Content-Type'] = "application/json; charset=UTF-8";

    try {
      final response = await http
          .post(
        Uri.parse("$serverURL/api/change_password?user_api_hash=${prefs.getString('user_api_hash')!}"),
        headers: headers,
        body: jsonEncode({
          "password": newPassword,
          "password_confirmation": retypePassword,
        }),
      )
          .timeout(const Duration(seconds: 10)); // timeout de 10s

      return response;
    } catch (e) {
      // Creamos un response falso con código 500 para manejarlo en UI
      return http.Response('{"message":"$e"}', 500);
    }
  }





  static Future<http.Response> activateFCM(token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/fcm_token?user_api_hash=" +
            prefs.getString('user_api_hash')! +
            "&token=" +
            token),
        headers: headers);
    return response;
  }

  static Future<http.Response> activateDevice(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/change_active_device?user_api_hash=" +
            prefs.getString('user_api_hash')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<http.Response> editDeviceData(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/edit_device_data?user_api_hash=" +
            prefs.getString('user_api_hash')!+
            "&lang="+prefs.getString('language')!),
        body: val,
        headers: headers);
    return response;
  }

  static Future<http.Response> editDevice(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(serverURL! +
            "/api/edit_device?user_api_hash=" +
            prefs.getString('user_api_hash')!+
            "&lang="+prefs.getString('language')!),
        body: val,
        headers: headers);
    return response;
  }


  static Future<http.Response> generateShare(
      String name, // 👈 nuevo parámetro obligatorio
      String? email, // 👈 opcional
      String deviceId,
      DateTime endDate,
      int deleteAfterExpiration, // 👈 dinámico
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userApiHash = prefs.getString("user_api_hash")!;

    headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";

    // 🔹 Formatear fecha de fin (yyyy-MM-dd HH:mm:ss)
    final expDateStr =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} "
        "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}:${endDate.second.toString().padLeft(2, '0')}";

    // 🔹 Armar body base
    final body = {
      "user_api_hash": userApiHash,
      "active": "1",
      "name": name, // 👈 usamos el nombre recibido
      "expiration_by": "time",
      "expiration_date": expDateStr,
      "delete_after_expiration": deleteAfterExpiration.toString(),
      "devices[]": deviceId,
    };

    // 🔹 Solo agregamos email si el usuario lo ingresó
    if (email != null && email.isNotEmpty) {
      body["send_email"] = "1";
      body["email"] = email;
    }

    final response = await http.post(
      Uri.parse("${serverURL!}/api/sharing"),
      headers: headers,
      body: body,
    );

    print("➡️ Request: ${response.request}");
    print("⬅️ Response: ${response.body}");
    return response;
  }


  static Future<String> getGeocoderAddress(lat, lng) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
    "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse("${serverURL!}/api/geo_address?lat=$lat&lon=$lng&user_api_hash=${prefs.getString("user_api_hash")!}"),
        headers: headers);
    return response.body;
  }
}