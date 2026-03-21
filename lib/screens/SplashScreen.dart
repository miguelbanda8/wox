import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gpspro/model/Login.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  SharedPreferences? prefs;
  String _notificationToken = "";
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  int id =0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    checkPreference();
    initFirebase();
  }

  void checkPreference() async {
    await [
      Permission.location,
      Permission.notification,
    ].request();
    prefs = await SharedPreferences.getInstance();
    if (prefs!.get('email') != null) {
      checkLogin();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging
        .getToken()
        .then((value) => {print(value), _notificationToken = value!});

    await messaging.getToken().then((value) => {_notificationToken = value!});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      localPushNotification(message.notification!.title, message.notification!.body);
      Alert(
        context: context,
        type: AlertType.warning,
        title: message.notification!.title,
        desc:  message.notification!.body,
        buttons: [
          DialogButton(
            child: Text(
              ('ok').tr(),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
            width: 120,
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
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {}
    });
  }

  Future<void> localPushNotification(title, body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        icon: "ic_launcher",
        ticker: 'ticker');
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        id++, title, body, notificationDetails,

        payload: 'item x');
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkLogin() {
    Future.delayed(const Duration(milliseconds: 5000), () {
      API.login(prefs!.get('email'), prefs!.get('password'))
          .then((response) {
        if (response != null) {
          if (response.statusCode == 200) {
            prefs!.setString("user", response.body);
            final user =
                Login.fromJson(jsonDecode(response.body.replaceAll("ï»¿", "")));
            prefs!.setString('user_api_hash', user.user_api_hash!);
            updateToken();
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  }

  void updateToken() {
    API.getUserData()
        .then((value) => {API.activateFCM(_notificationToken)});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Center(
            child: new Container(
              height: 400,
              padding: EdgeInsets.all(100),
              child: new Column(children: <Widget>[
                new Image.asset(
                  'images/logo.png',
                  fit: BoxFit.contain,
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              ]),
            ),
          )
        ],
      ),
    );
  }
}
