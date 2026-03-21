import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gpspro/model/Login.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/screens/Home.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  SharedPreferences? prefs;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();

  bool _obscurePassword = true;
  String _notificationToken = "";
  bool isLoading = false;

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  int id = 0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initFirebase();
    checkPreference();
  }

  Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.getToken().then((value) {
      if (value != null) {
        _notificationToken = value;
        print("FCM Token: $_notificationToken");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      localPushNotification(
        message.notification?.title ?? "",
        message.notification?.body ?? "",
      );
      Alert(
        context: context,
        type: AlertType.warning,
        title: message.notification?.title,
        desc: message.notification?.body,
        buttons: [
          DialogButton(
            child: Text(('ok').tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ).show();
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> localPushNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      icon: "ic_launcher",
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id++,
      title,
      body,
      notificationDetails,
      payload: 'item x',
    );
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs!.getString('email') != null) {
      _emailController.text = prefs!.getString('email')!;
      _passwordController.text = prefs!.getString('password') ?? "";
    }
    setState(() {});
  }

  void updateToken() {
    API.getUserData().then((_) {
      API.activateFCM(_notificationToken);
    });
  }

  void loginPressed(BuildContext context) async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final response = await API.login(_emailController.text, _passwordController.text);
      setState(() => isLoading = false);

      if (response != null && response.statusCode == 200) {
        // ✅ Login exitoso
        Provider.of<DeviceStore>(context, listen: false).getDevices();
        final user = Login.fromJson(jsonDecode(response.body.replaceAll("ï»¿", "")));
        updateToken();
        prefs.setString(PREF_API_HASH, user.user_api_hash ?? "");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else if (response?.statusCode == 401) {
        _showError(context, "Usuario o contraseña incorrectos.");
      } else if (response?.statusCode == 500) {
        _showError(context, "Error en el servidor. Inténtalo más tarde.");
      } else {
        _showError(context,
            "No se pudo iniciar sesión. Código: ${response?.statusCode ?? 'desconocido'}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError(context, "No hay conexión a internet. Revisa tu red.");
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Image.asset(
                      "images/logo.png",
                      width: 250,
                      height: 250,
                    ),
                    const SizedBox(height: 5),

                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: ('username').tr(),
                        border: const UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: ('userPassword').tr(),
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => loginPressed(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          ('loginTitle').tr(),
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Powered by
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Powered by SoftwarExpress",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
