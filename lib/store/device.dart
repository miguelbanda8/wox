import 'package:flutter/material.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStore extends ChangeNotifier {
  List<Device> _devices = [];
  List<dynamic> _devicesList = [];
  List<Device> _devicesListGroup = [];

  List<Event> _events= [];

  int get count => _devices.length;
  List<Device> get devices => _devices;
  List<Event> get events => _events;
  List<dynamic> get devicesList => _devicesList;
  List<Device> get devicesListGroup => _devicesListGroup;
  bool isLoading = true;
  bool isEventLoading = true;
  String _searchString = "";
  bool darkMode = false;

  void getDevices() async{
    _devices = (await API.getDevices())!;
    _devicesListGroup = _devices;
    _devicesList.clear();
    _devices.forEach((element) {
      _devicesList.addAll(element.items!);
    });
    isLoading = false;
    notifyListeners();
  }

  void getEvents() async{
    _events = (await API.getEventList())!;
    isEventLoading = false;
    notifyListeners();
  }

  void changeSearchString(String searchString) {
    devicesList.clear();
    _searchString = searchString;
    devicesList.forEach((device) {
      if (device['name'].toLowerCase().contains(searchString.toLowerCase())) {
        devicesList.add(device);
      }
    });
    notifyListeners();
  }

  void setDarkMode() async{
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // if(prefs.getString(PREF_DARK_MODE) != null){
    //   if(prefs.getString(PREF_DARK_MODE)! == "auto"){
    //     darkMode = _isDark();
    //   }else if(prefs.getString(PREF_DARK_MODE)! == "light"){
    //     darkMode = false;
    //   }else if(prefs.getString(PREF_DARK_MODE)! == "dark"){
    //     darkMode = true;
    //   }
    // }else{
    //   darkMode = _isDark();
    // }

    notifyListeners();
  }

  bool _isDark() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour > 18;
  }
}