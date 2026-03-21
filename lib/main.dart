import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:gpspro/firebase_options.dart';
import 'package:gpspro/routes.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/store/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wakelock/wakelock.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  Wakelock.enable();
  runApp(Phoenix(child:EasyLocalization(
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('pt', ''),
      ],
      startLocale: const Locale('es', ''),
      path: 'assets/lang',
      fallbackLocale: Locale('es', ''),
      child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DeviceStore()),
            ChangeNotifierProvider(create: (_) => UserStore())
          ],
          child:MyApp()))));
}

SharedPreferences? prefs;
String langCode = "es";

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _MyAppPageState();
}

class _MyAppPageState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    checkPreference();
  }

  Future<String> checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs!.getString("language") == null) {
      langCode = "es";
      prefs!.setString("language", "es");
    } else {
      langCode = prefs!.getString("language")!;
    }
    context.setLocale(Locale(langCode, ''));
    setState(() {});
    return langCode;
  }



  GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Provider.of<DeviceStore>(context, listen: false).setDarkMode();
    bool _isDarkMode =  false;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: CustomColor.primaryColor,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);


    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: CustomColor.primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false
      ),
      initialRoute: '/',
      routes: routes,
    );
  }
}
