import 'dart:async';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gpspro/screens/RecentEvents.dart';
import 'package:gpspro/screens/Devices.dart';
import 'package:gpspro/screens/MapHome.dart';
import 'package:gpspro/screens/Settings.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'About.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 2;
  bool first = true;
  SharedPreferences? prefs;
  String? email;
  String? password;
  String _notificationToken = "";
  late DeviceStore deviceStore;
  int id =0;
  late Timer _timer;
  bool loaded = false;
  bool isDarkMode = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateData() {
    Provider.of<DeviceStore>(context, listen: false).getDevices();
    Provider.of<DeviceStore>(context, listen: false).getEvents();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      Provider.of<DeviceStore>(context, listen: false).getDevices();
      getEvents();
    });
    Future.delayed(Duration(seconds: 3)).then((value) => {
      setState(() {
        loaded = true;
      })
    });
  }

  void getEvents() {
    API.getEventList().then((value) => {
      if (value != null)
        {
          Provider.of<DeviceStore>(context, listen: false).getEvents()
        },
    });
  }

  @override
  initState() {
    checkPreference();
    super.initState();
    isDarkMode = Provider.of<DeviceStore>(context, listen: false).darkMode;
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    email = await prefs!.getString('email')!;
    password = await prefs!.getString('password')!;
    updateData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Future<bool> _onWillPop() async{
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(("areYouSure").tr()),
          content: Text(("doYouWantToExit").tr()),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(("no").tr()),
            ),
            ElevatedButton(
              onPressed: () => {SystemNavigator.pop()},
              /*Navigator.of(context).pop(true)*/
              child: Text(("yes").tr()),
            ),
          ],
        ),
      );
    }

    return SafeArea(
          child: WillPopScope(
            onWillPop: _onWillPop,
    child: Scaffold(
            extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            DevicePage(),
            RecentEventsPage(),
            MapPage(),
            SettingsPage(),
            AboutPage()
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          color: CustomColor.primaryColor,
          index: _selectedIndex,
          height: 50,
          backgroundColor: Colors.transparent,
          items: [
            Icon(Icons.directions_car_rounded,
                size: 25, color: CustomColor.secondaryColor),
            Icon(Icons.notifications,
                size: 25, color: CustomColor.secondaryColor),
            Icon(
              Icons.map,
              size: 25,
              color: CustomColor.secondaryColor,
            ),
            Icon(Icons.settings, size: 25, color: CustomColor.secondaryColor),
            Icon(Icons.info, size: 25, color: CustomColor.secondaryColor),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.info),
            //     label: ("about")),
          ],
          animationDuration: Duration(milliseconds: 300),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            //Handle button tap
          },
        ),
        // floatingActionButtonLocation:
        //     FloatingActionButtonLocation.miniCenterDocked,
        // floatingActionButton: _buildFab(
        //     context), // This trailing comma makes auto-formatting nicer for build methods.
      )),
    );
  }
}
