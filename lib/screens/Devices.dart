import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/SingleDevice.dart';
import 'package:gpspro/model/bottomMenu.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/MenuItem.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' as m;

import '../model/Device.dart';

class DevicePage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => new _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  TextEditingController controller = new TextEditingController();
  List<dynamic> devicesList = [];
  List<dynamic> _searchResult = [];
  Locale? myLocale;

  String selectedIndex = "all";

  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  int _selectedperiod = 0;
  double _dialogHeight = 300.0;
  double _dialogCommandHeight = 150.0;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  List<BottomMenu> bottomMenu = [];
  final TextEditingController _name = new TextEditingController();
  SingleDevice? sd;
  String address = ('showAddress').tr();
  Map<String, String> addressMap = HashMap();
  late DeviceStore deviceStore;
  int tabIndex = 0;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    fillBottomList();
    isDarkMode = Provider.of<DeviceStore>(context, listen: false).darkMode;
  }

  void setLocale(locale) async {
    await Jiffy.locale(locale);
  }


  void fillBottomList() {
    bottomMenu.add(new BottomMenu(
        title: "liveTracking",
        img: "icons/tracking.png",
        tapPath: "/trackDevice"));
    bottomMenu.add(new BottomMenu(
        title: "info", img: "icons/car.png", tapPath: "/deviceInfo"));
    bottomMenu.add(new BottomMenu(
        title: "playback", img: "icons/route.png", tapPath: "playback"));
    bottomMenu.add(new BottomMenu(
        title: "alarmGeofence",
        img: "icons/fence.png",
        tapPath: "/geofenceList"));
    bottomMenu.add(new BottomMenu(
        title: "report", img: "icons/report.png", tapPath: "report"));
    bottomMenu.add(new BottomMenu(
        title: "savedCommand", img: "icons/command.png", tapPath: "command"));
    bottomMenu.add(new BottomMenu(
        title: "editDevice", img: "icons/edit.png", tapPath: "editDevice"));
  }

  void editDeviceDialog(BuildContext context, dynamic device) {


    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: 180,
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[

                              new Text(("reportDeviceName").tr(), style: TextStyle(fontWeight: FontWeight.bold),),
                              new Container(
                                child: new TextField(
                                  controller: _name,
                                  decoration: new InputDecoration(
                                      labelText:
                                      ('sharedName').tr()),
                                ),
                              ),

                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red, // background
                                      foregroundColor: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(('cancel').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      updateDevice(device["id"]);
                                    },
                                    child: Text(
                                      ('ok').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void getEditDeviceData(deviceId){
    showProgress(true, context);
    Map<String, String> requestBody = <String, String>{
      'device_id': deviceId.toString()
    };
    API.editDeviceData(requestBody).then((value) => {
      showProgress(false, context),
      sd =SingleDevice.fromJson(json.decode(value.body.replaceAll("ï»¿", ""))),
      _name.text = sd!.item!["name"],
      editDeviceDialog(context, sd!.item)
    });
  }

  void updateDevice(deviceId){
    showProgress(true, context);
    Map<String, String> requestBody = <String, String>{
      'name': _name.text,
      'fuel_measurement_id': sd!.item!["fuel_measurement_id"].toString(),
      'device_id': deviceId.toString()
    };
    API.editDevice(requestBody).then((value) => {
      showProgress(false, context),
      sd =SingleDevice.fromJson(json.decode(value.body.replaceAll("ï»¿", ""))),
      Navigator.pop(context),
      editDeviceDialog(context, value),
    });
  }


  deviceListFilter(String filterVal) async {
    _searchResult.clear();

    if (filterVal == "all") {
      setState(() {});
      return;
    }


    devicesList.forEach((device) {
      if (device['icon_color'].contains(filterVal)) {
        if (device['icon_color'] == filterVal) {
          _searchResult.add(device);
        }
      }
    });

    setState(() {});
  }


  onSearchTextChanged(String text) async {
    _searchResult.clear();

    if (text
        .toLowerCase()
        .isEmpty) {
      setState(() {});
      return;
    }

    devicesList.forEach((device) {
      if (device['name'].toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(device);
      }
    });
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    deviceStore = Provider.of<DeviceStore>(context);
    devicesList = deviceStore.devicesList;
    myLocale = Localizations.localeOf(context);

    setLocale(myLocale!.languageCode);


    return Scaffold(
        body: new Column(
            children: <Widget>[
              new Container(
                child: new Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: new Card(
                    child: new ListTile(
                      leading: new Icon(Icons.search),
                      title: new TextField(
                        controller: controller,
                        decoration: new InputDecoration(
                            hintText: (
                                'search').tr(),
                            border: InputBorder.none),
                        onChanged: onSearchTextChanged,
                      ),
                      trailing: new IconButton(
                        icon: new Icon(Icons.cancel),
                        onPressed: () {
                          controller.clear();
                          onSearchTextChanged('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.all(3)),
              Center(child:customTabs())
            ]));
  }

  Widget customTabs(){
    return ListView(
      primary: true,
      shrinkWrap: true,
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height / 1.23,
          child: Column(
            children: <Widget>[
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  initialIndex: tabIndex,
                  child: new Scaffold(
                    appBar: PreferredSize(
                      preferredSize:
                      Size.fromHeight(40.0), // here the desired height
                      child: new AppBar(
                        elevation: 0.0,
                        centerTitle: true,
                        flexibleSpace: SafeArea(
                          child: Stack(
                            children: <Widget>[
                              Container(
                                color: isDarkMode ? Colors.black : Colors.white,
                                child:  TabBar(
                                  isScrollable: false,
                                  labelColor:  isDarkMode ? Colors.black : Colors.white,
                                  padding: EdgeInsets.zero,
                                  indicatorPadding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.all(5),
                                  onTap: (val){
                                    tabIndex = val;
                                    if(val == 0){
                                      deviceListFilter("all");
                                      selectedIndex = "all";
                                    }
                                    if(val == 1){
                                      deviceListFilter("green");
                                      selectedIndex = "green";
                                    }
                                    if(val == 2){
                                      deviceListFilter("yellow");
                                      selectedIndex = "orange";
                                    }
                                    if(val == 3){
                                      deviceListFilter("red");
                                      selectedIndex = "black";
                                    }
                                    // deviceListFilter(val);
                                  },
                                  labelStyle: TextStyle(
                                      fontFamily: "Sofia", fontSize: 12.0),
                                  unselectedLabelColor: Colors.white70,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  tabs: [
                                    new Tab(
                                      child: Container(
                                          padding: EdgeInsets.only(left: 20, right: 20, top: 7),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Colors.grey,
                                            boxShadow: [
                                              BoxShadow(color: Colors.grey, spreadRadius: 1),
                                            ],
                                          ),
                                          child:Column(children: [
                                            Text(("all").tr()),
                                          ],)),
                                    ),
                                    new Tab(
                                      child: Container(
                                          padding: EdgeInsets.only(left: 20, right: 20, top: 7),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Colors.green,
                                            boxShadow: [
                                              BoxShadow(color: Colors.green, spreadRadius: 1),
                                            ],
                                          ),
                                          child:Column(children: [
                                            Text(("running").tr()),
                                          ],)),
                                    ),
                                    new Tab(
                                      child: Container(
                                          padding: EdgeInsets.only(left: 20, right: 20, top: 7),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: YELLOW_CUSTOM,
                                            boxShadow: [
                                              BoxShadow(color: Colors.yellow, spreadRadius: 1),
                                            ],
                                          ),
                                          child:Column(children: [
                                            Text(("idle").tr()),
                                          ],)),
                                    ),
                                    new Tab(
                                      child: Container(
                                          padding: EdgeInsets.only(left: 20, right: 20, top: 7),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Colors.red,
                                            boxShadow: [
                                              BoxShadow(color: Colors.red, spreadRadius: 1),
                                            ],
                                          ),
                                          child:Column(children: [
                                            Text(("stopped").tr(), overflow: TextOverflow.ellipsis,),
                                          ],)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        automaticallyImplyLeading: false,
                      ),
                    ),

                    body: new TabBarView(
                      children: [
                        _searchResult.length != 0 || controller.text.isNotEmpty
                            ?  ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, index) {
                            try {
                              final device = _searchResult[index];
                              if (device != null) {
                                return deviceCard(device, context);
                              } else {
                                return Container();
                              }
                            }catch(e){
                              return Container();
                            }
                          },
                        )  : selectedIndex == "all" ? ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index];
                            return deviceCard(device, context);
                          },
                        ): new ListView.builder(
                            itemCount: 0,
                            itemBuilder: (context, index) {
                              return Text(("noDeviceFound").tr());
                            }),


                        _searchResult.length != 0 || controller.text.isNotEmpty
                            ?  ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, index) {
                            try {
                              final device = _searchResult[index];
                              if (device != null) {
                                return deviceCard(device, context);
                              } else {
                                return Container();
                              }
                            }catch(e){
                              return Container();
                            }
                          },
                        )  : selectedIndex == "all" ? ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index];
                            return deviceCard(device, context);
                          },
                        ): new ListView.builder(
                            itemCount: 0,
                            itemBuilder: (context, index) {
                              return Text(("noDeviceFound").tr());
                            }),


                        _searchResult.length != 0 || controller.text.isNotEmpty
                            ?  ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, index) {
                            try {
                              final device = _searchResult[index];
                              if (device != null) {
                                return deviceCard(device, context);
                              } else {
                                return Container();
                              }
                            }catch(e){
                              return Container();
                            }
                          },
                        )  : selectedIndex == "all" ? ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index];
                            return deviceCard(device, context);
                          },
                        ): new ListView.builder(
                            itemCount: 0,
                            itemBuilder: (context, index) {
                              return Text(("noDeviceFound").tr());
                            }),


                        _searchResult.length != 0 || controller.text.isNotEmpty
                            ?  ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, index) {
                            try {
                              final device = _searchResult[index];
                              if (device != null) {
                                return deviceCard(device, context);
                              } else {
                                return Container();
                              }
                            }catch(e){
                              return Container();
                            }
                          },
                        )  : selectedIndex == "all" ? ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index];
                            return deviceCard(device, context);
                          },
                        ): new ListView.builder(
                            itemCount: 0,
                            itemBuilder: (context, index) {
                              return Text(("noDeviceFound").tr());
                            }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget deviceCard(device, BuildContext context) {
    Color color;

    var battery = "0";
    String ignition, door, gps=('disconnected').tr();


    if (device['sensors'] != null) {
      device['sensors'].forEach((sensor) {
        if (sensor['type'] == "battery") {
          if (sensor['val'] != null) {
            battery = sensor['val'].toString();
          }
        }
        if (sensor['type'] == "acc") {
          ignition = sensor['value'];
        }
        if (sensor['type'] == "door") {
          door = sensor['value'];
        }
        if (sensor['type'] == "satellites") {
          if(sensor['value'] != "0") {
            gps = sensor['value'];
          }
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.only(
          top: 10.0, left: 5.0, right: 5.0, bottom: 0),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          onSheetShowContents(context, device);
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 120, left: 20, right: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0)),
                  color: isDarkMode ? Colors.black : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                    )
                  ]
              ),
              child:
              Padding(padding: EdgeInsets.all(5),
                  child: Column(children: [
                    sensorView(device, parseColor(device['icon_color'])),
                    Divider(height: 1,),
                    Container(
                        padding: EdgeInsets.only(left: 2, top: 2),
                        child:Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gps_fixed,color: gps != ('disconnected').tr() ? Colors.green : Colors.red, size: 15,),
                                Padding(padding: EdgeInsets.only(left: 5)),
                                Text("GPS", style: TextStyle(color: Colors.grey, fontSize: 10),),
                                Padding(padding: EdgeInsets.only(left: 5)),
                                Text(gps, style: TextStyle(color: Colors.grey, fontSize: 10),)
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    //Text("sec", style: TextStyle(color: Colors.black, fontSize: 10),),
                                    Padding(padding: EdgeInsets.only(left: 5)),
                                    Text(device["time"], style: TextStyle(color: Colors.grey, fontSize: 10),)
                                  ],
                                )
                              ],
                            )
                          ],
                        ))
                  ],)
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                    )
                  ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 120.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                        color: parseColor(device['icon_color']),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            bottomLeft: Radius.circular(10.0))),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15,25,15,10),
                        child: CircleAvatar(
                            radius: 25,
                            backgroundColor: parseColor(device['icon_color']),
                            child:Icon(
                              Icons.drive_eta,
                              color: Colors.white,
                              size: 30.0,
                            )),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device["name"],
                                style: TextStyle(
                                    fontFamily: "Sans",
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5),
                              ),
                            ],),
                          Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Text(device["time"],
                                style: TextStyle(
                                    fontFamily: "Sans",
                                    color: Colors.black,
                                    fontSize: 12.5),
                              )),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0, right: 15.0),
                            child: addressLoad(double.parse(device["lat"].toString()).toString(), double.parse(device["lng"].toString()).toString()),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height / 8,
                      child:Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(device['speed'].toString()+ " mph",
                            style: TextStyle(
                                fontFamily: "Sans",
                                color: parseColor(device['icon_color']),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5),
                          ),
                        ],
                      ))
                ],
              ),
            ),
          ],
        ) ,
      ),
    );
  }

  Widget sensorView(dynamic device, Color color) {
    double width = MediaQuery
        .of(context)
        .size
        .width;
    double fontWidth = 1;
    double iconWidth = 20;
    List<Widget> sensors = [];

    try {


      if (device['sensors'].isNotEmpty) {
        device['sensors'].forEach((sensor) {
          if (sensor['value'] != null) {
            sensors.add(
                Container(
                    margin: EdgeInsets.all(3),
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child:Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset("assets/images/sensors/"+sensor['type']+".png", width: iconWidth, height: iconWidth,),
                          Text(sensor["name"]+": ",style: TextStyle(
                              fontSize: fontWidth * 10)),
                          Text(sensor['value'],
                            style: TextStyle(
                                fontSize: fontWidth * 10),
                          )
                        ]))
            );
          }
        });
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sensors
        );
      }else {
        sensors.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              "assets/images/sensors/engine-off.png",
              width: iconWidth, height: iconWidth,
            ),
            Icon(Icons.vpn_key, color: Colors.grey, size: 20,),
            Icon(Icons.battery_charging_full_sharp, color: Colors.grey,size: 20,),
            Icon(Icons.wifi, color: Colors.grey,size: 20,),
            Icon(Icons.battery_4_bar_rounded, color: Colors.grey,size: 20,),
          ],
        ));
        return Container(
            padding: EdgeInsets.all(5),
            width: MediaQuery
                .of(context)
                .size
                .width * 100,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:sensors
            ));
      }
    }catch(e) {
      sensors.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/images/sensors/engine-off.png",
            width: iconWidth, height: iconWidth,
          ),
          Icon(Icons.vpn_key, color: Colors.grey, size: 20,),
          Icon(Icons.battery_charging_full_sharp, color: Colors.grey,size: 20,),
          Icon(Icons.wifi, color: Colors.grey,size: 20,),
          Icon(Icons.battery_4_bar_rounded, color: Colors.grey,size: 20,),
        ],
      ));
      return Container(
          padding: EdgeInsets.all(5),
          width: MediaQuery
              .of(context)
              .size
              .width * 100,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:sensors
          ));
    }
  }

  void onSheetShowContents(BuildContext context, dynamic device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.40,
            decoration: new BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(15.0),
                topRight: const Radius.circular(15.0),
              ),
            ),
            child: bottomSheetContent(device),
          ),
    );
  }

  Widget bottomSheetContent(dynamic device) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.all(5)),
          Center(
            child: Container(
              width: 100,
              padding: EdgeInsets.fromLTRB(0, 7, 0, 0),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Text(
                device['name'],
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              )),
          Divider(),
          //Flexible(child: Padding(padding:EdgeInsets.only(left:5, right: 5), child:bottomButton(device)))
          Flexible(child: GridView.count(
            crossAxisCount: 4,
            padding: EdgeInsets.only(top: 5, left: 5, right: 5),
            children: <Widget>[
              MenuItem(
                icon: Icons.gps_not_fixed,
                title: ('liveTracking').tr(),
                onTap: () {
                  Navigator.pushNamed(context, "/trackDevice",
                      arguments:
                      DeviceArguments(device['id'], device['name'], device));
                },
              ),
              MenuItem(
                icon: Icons.info,
                title: ('info').tr(),
                onTap: () {
                  Navigator.pushNamed(context, "/deviceInfo",
                      arguments:
                      DeviceArguments(device['id'],device['name'], device));
                },
              ),
              MenuItem(
                icon: Icons.settings,
                title: ('playback').tr(),
                onTap: () {
                  showReportDialog(context, "playback", device);
                },
              ),
              MenuItem(
                icon: Icons.share_location_outlined,
                title: ('alarmGeofence').tr(),
                onTap: () {
                  Navigator.pushNamed(context, "/geofenceList",
                      arguments: ReportArguments(device['id'], "", "", "", "", "", 0));
                },
              ),
              MenuItem(
                icon: Icons.file_copy,
                title: ('reports').tr(),
                onTap: () {
                  showReportDialog(context, ('report').tr(), device);
                },
              ),
            ],
          )),
        ],
      ),
    );
  }

  void showReportDialog(BuildContext context, String heading, dynamic device) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Container(
            height: _dialogHeight,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 0,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod =
                                        int.parse(value.toString());
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportToday').tr(),
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 1,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod =
                                        int.parse(value.toString());
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportYesterday').tr(),
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 2,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod =
                                        int.parse(value.toString());
                                    _dialogHeight = 300.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportThisWeek').tr(),
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 3,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _dialogHeight = 400.0;
                                    _selectedperiod =
                                        int.parse(value.toString());
                                  });
                                },
                              ),
                              new Text(
                                ('reportCustom').tr(),
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          _selectedperiod == 3
                              ? new Container(
                              child: new Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:CustomColor.primaryColor,
                                        ),
                                        onPressed: () => _selectFromDate(
                                            context, setState),
                                        child: Text(
                                            formatReportDate(
                                                _selectedFromDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:CustomColor.primaryColor,
                                        ),
                                        onPressed: () => _selectFromTime(
                                            context, setState),
                                        child: Text(
                                            formatReportTime(
                                                _selectedFromTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:CustomColor.primaryColor,
                                        ),
                                        onPressed: () =>
                                            _selectToDate(context, setState),
                                        child: Text(
                                            formatReportDate(_selectedToDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:CustomColor.primaryColor,
                                        ),
                                        onPressed: () =>
                                            _selectToTime(context, setState),
                                        child: Text(
                                            formatReportTime(_selectedToTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                              : new Container(),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:Colors.red
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(('cancel').tr(),
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:CustomColor.primaryColor,
                                ),
                                onPressed: () {
                                  showReport(heading, device);
                                },
                                child: Text(
                                  ('ok').tr(),
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Widget addressLoad(String lat, lng){
    return FutureBuilder<String>(
        future: API.getGeocoder(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Container( height: 40,child:Text(snapshot.data!.replaceAll('"', ''), style: TextStyle(
                color: Colors.black,
                fontSize: 11),));
          } else {
            return CircularProgressIndicator();
          }
        }
    );
  }

  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedFromDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedFromDate)
      setState(() {
        _selectedFromDate = picked;
      });
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedToDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedToDate)
      setState(() {
        _selectedToDate = picked;
      });
  }

  Future<void> _selectFromTime(
      BuildContext context, StateSetter setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedFromTime)
      setState(() {
        _selectedFromTime = picked;
      });
  }

  Future<void> _selectToTime(BuildContext context, setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedToTime)
      setState(() {
        _selectedToTime = picked;
      });
  }

  void showCommandDialog(BuildContext context, dynamic device) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              API.getSendCommands(device['id'].toString()).then((value) => {
                if (value != null)
                  {
                    list = json.decode(value.body)["commands"],
                    if (_commands.length == 0)
                      {
                        list.forEach((element) {
                          _commands.add(element["title"]);
                          _commandsValue.add(element["id"]);
                        }),
                        setState(() {}),
                      }
                  },
              });

              return Container(
                height: _dialogCommandHeight,
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr()),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _commands.length > 0
                                        ? new DropdownButton<String>(
                                      hint: new Text(('select_command').tr()),
                                      value: _commands[_selectedCommand],
                                      items: _commands.map((String value) {
                                        return new DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text(
                                            (value) !=
                                                null
                                                ?(value)
                                                : value,
                                            style: TextStyle(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        print(value);
                                        setState(() {
                                          if (value ==
                                              ("customCommand").tr()) {
                                            _dialogCommandHeight = 200.0;
                                          } else {
                                            _dialogCommandHeight = 150.0;
                                          }
                                          _commandSelected = value!;
                                          _selectedCommand =
                                              _commands.indexOf(value);
                                          print(_selectedCommand);
                                        });
                                      },
                                    )
                                        : new CircularProgressIndicator(),
                                  ]),
                              _commandSelected == ("customCommand").tr()
                                  ? new Container(
                                child: new TextField(
                                  controller: _customCommand,
                                  decoration: new InputDecoration(
                                      labelText:('commandCustom').tr()),
                                ),
                              )
                                  : new Container(),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:Colors.red
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(('cancel').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:CustomColor.primaryColor,
                                    ),
                                    onPressed: () {
                                      sendCommand(device);
                                    },
                                    child: Text(
                                      ('ok').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void showSavedCommandDialog(BuildContext context, dynamic device) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              API.getSavedCommands(device['id'].toString()).then((value) => {
                if (value != null)
                  {
                    list = json.decode(value.body),
                    if (_commands.length == 0)
                      {
                        list.forEach((element) {
                          _commands.add(element["title"]);
                          _commandsValue.add(element["type"]);
                        }),
                        setState(() {}),
                      }
                    else
                      {

                      }
                  }
                else
                  {

                  }
              });

              return Container(
                height: _dialogCommandHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr()),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _commands.length > 0
                                        ? new DropdownButton<String>(
                                      hint: new Text(('select_command').tr()),
                                      value: _commands[_selectedCommand],
                                      items: _commands.map((String value) {
                                        return new DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text(
                                            (value) !=
                                                null
                                                ?(value)
                                                : value,
                                            style: TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          print(value);
                                          if (value ==
                                              ("customCommand").tr()) {
                                            _dialogCommandHeight = 200.0;
                                          } else {
                                            _dialogCommandHeight = 150.0;
                                          }
                                          _commandSelected = value!;
                                          _selectedCommand =
                                              _commands.indexOf(value);
                                        });
                                      },
                                    )
                                        : new CircularProgressIndicator(),
                                  ]),
                              _commandSelected == ("customCommand").tr()
                                  ? new Container(
                                child: new TextField(
                                  controller: _customCommand,
                                  decoration: new InputDecoration(
                                      labelText: ('commandCustom').tr()),
                                ),
                              )
                                  : new Container(),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:Colors.red
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(('cancel').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:Colors.red
                                    ),
                                    onPressed: () {
                                      sendCommand(device);
                                    },
                                    child: Text(
                                      ('ok').tr(),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendCommand(dynamic device) {
    Map<String, String> requestBody;
    if (_commandSelected == ("customCommand").tr()) {
      requestBody = <String, String>{
        'id': "",
        'device_id': device['id'].toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id':  device['id'].toString(),
        'type': _commandsValue[_selectedCommand]
      };
    }

    print(requestBody.toString());

    API.sendCommands(requestBody).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent').tr(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
      else
        {
          Fluttertoast.showToast(
              msg: ('errorMsg').tr(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
    });
  }

  void showReport(String heading, dynamic device) {
    String fromDate;
    String toDate;
    String fromTime;
    String toTime;

    DateTime current = DateTime.now();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    if (current.day < 10) {
      day = "0" + current.day.toString();
    } else {
      day = current.day.toString();
    }

    if (_selectedperiod == 0) {
      String today;

      int dayCon = current.day + 1;
      if (current.day < 10) {
        today = "0" + dayCon.toString();
      } else {
        today = dayCon.toString();
      }

      var date = DateTime.parse("${current.year}-"
          "$month-"
          "$today "
          "00:00:00");
      fromDate = formatDateReport(DateTime.now().toString());
      toDate = formatDateReport(date.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
    } else if (_selectedperiod == 1) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day < 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
    } else if (_selectedperiod == 2) {
      String sevenDay, currentDayString;
      int dayCon = current.day - current.weekday;
      int currentDay = current.day;
      if (dayCon < 10) {
        sevenDay = "0" + dayCon.abs().toString();
      } else {
        sevenDay = dayCon.toString();
      }
      if (currentDay < 10) {
        currentDayString = "0" + currentDay.toString();
      } else {
        currentDayString = currentDay.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$sevenDay "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$currentDayString "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
    } else {
      String startMonth, endMoth;
      if (_selectedFromDate.month < 10) {
        startMonth = "0" + _selectedFromDate.month.toString();
      } else {
        startMonth = _selectedFromDate.month.toString();
      }

      if (_selectedToDate.month < 10) {
        endMoth = "0" + _selectedToDate.month.toString();
      } else {
        endMoth = _selectedToDate.month.toString();
      }

      String startHour, endHour;
      if (_selectedFromTime.hour < 10) {
        startHour = "0" + _selectedFromTime.hour.toString();
      } else {
        startHour = _selectedFromTime.hour.toString();
      }

      String startMin, endMin;
      if (_selectedFromTime.minute < 10) {
        startMin = "0" + _selectedFromTime.minute.toString();
      } else {
        startMin = _selectedFromTime.minute.toString();
      }

      if (_selectedFromTime.minute < 10) {
        endMin = "0" + _selectedToTime.minute.toString();
      } else {
        endMin = _selectedToTime.minute.toString();
      }

      if (_selectedToTime.hour < 10) {
        endHour = "0" + _selectedToTime.hour.toString();
      } else {
        endHour = _selectedToTime.hour.toString();
      }

      String startDay, endDay;
      if (_selectedFromDate.day < 10) {
        if (_selectedFromDate.day == 10) {
          startDay = _selectedFromDate.day.toString();
        } else {
          startDay = "0" + _selectedFromDate.day.toString();
        }
      } else {
        startDay = _selectedFromDate.day.toString();
      }

      if (_selectedToDate.day < 10) {
        if (_selectedToDate.day == 10) {
          endDay = _selectedToDate.day.toString();
        } else {
          endDay = "0" + _selectedToDate.day.toString();
        }
      } else {
        endDay = _selectedToDate.day.toString();
      }

      var start = DateTime.parse("${_selectedFromDate.year}-"
          "$startMonth-"
          "$startDay "
          "$startHour:"
          "$startMin:"
          "00");

      var end = DateTime.parse("${_selectedToDate.year}-"
          "$endMoth-"
          "$endDay "
          "$endHour:"
          "$endMin:"
          "00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = formatTimeReport(start.toString());
      toTime = formatTimeReport(end.toString());
    }

    print(fromDate);
    print(toDate);

    Navigator.pop(context);
    if (heading == ('report').tr()) {
      Navigator.pushNamed(context, "/reportList",
          arguments: ReportArguments(device['id'], fromDate, fromTime,
              toDate, toTime, device['name'], 0));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments: ReportArguments(device['id'], fromDate, fromTime,
              toDate, toTime, device['name'], 0));
    }
  }

}
