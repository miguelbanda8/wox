import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/SensorData.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart' as m;

import '../store/device.dart';

class DeviceInfo extends StatefulWidget {
  @override
  _DeviceInfoState createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  static DeviceArguments? args;

  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  int _selectedperiod = 0;
  double _dialogHeight = 300.0;
  double _dialogCommandHeight = 150.0;
  Timer? _timer;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  Device? device;
  var latLng;
  String address = "-";
  SharedPreferences? prefs;

  String totalDistance = "-";
  String maxSpeed = "-";
  String drivingHours = "-";
  String fuel = "-";

  List<SensorData> sensorValues = [];
  List<charts.Series>? seriesList;

  bool isLoading = true;

  List<LinearFuel> data = [];
  bool isDarkMode = false;


  String? fromDate;
  String? toDate;
  String? fromTime;
  String? toTime;


  @override
  void initState() {
    isDarkMode = Provider.of<DeviceStore>(context, listen: false).darkMode;
    checkPreference();
    super.initState();
  }

  List<charts.Series<LinearFuel, DateTime>> _createRandomData() {
    return [
      new charts.Series<LinearFuel, DateTime>(
        id: 'Fuel',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearFuel fuel, _) => fuel.time!,
        measureFn: (LinearFuel fuel, _) => fuel.val,
        data: data,
      )
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
   // address = ("sharedShowAddress");
    totalDistance =  ("sharedLoading").tr();
    maxSpeed =  ("sharedLoading").tr();
    drivingHours =  ("sharedLoading").tr();
    fuel = ("sharedLoading").tr();
    if(prefs!.get("totalDistance"+"-"+args!.id.toString()) != null) {
      totalDistance = prefs!.getString("totalDistance"+"-"+args!.id.toString())!;
      maxSpeed = prefs!.getString("maxSpeed"+"-"+args!.id.toString())!;
      drivingHours = prefs!.getString("drivingHours"+"-"+args!.id.toString())!;
      fuel = prefs!.getString("fuel"+"-"+args!.id.toString())!;
    }
    setState(() {

    });
    getTrip();
  }

  void getTrip(){

    DateTime current = DateTime.now();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    int dayCon = current.day - 1;
    if (current.day < 10) {
      day = "0" + dayCon.toString();
    } else {
      day = dayCon.toString();
    }
    var start = DateTime.parse("${current.year}-"
        "$month-"
        "$day "
        "00:00:00");

    var end = DateTime.parse("${current.year}-"
        "$month-"
        "$day "
        "24:00:00");

    fromDate = formatDateReport(start.toString());
    toDate = formatDateReport(end.toString());
    fromTime = formatTimeReport(start.toString());
    toTime = formatTimeReport(end.toString());


    API.getHistory(
        args!.id.toString(), fromDate!, fromTime!, toDate!, toTime!)
        .then((value) => {
      totalDistance = value!.distance_sum!,
      maxSpeed= value.top_speed!,
      drivingHours=  value.move_duration!,
      if(value.fuel_consumption != null){
        fuel = value.fuel_consumption!,
      }else{
        fuel = "0",
      },

      print("------------------"+totalDistance),

      prefs!.setString("totalDistance"+"-"+args!.id.toString(), totalDistance),
      prefs!.setString("maxSpeed"+"-"+args!.id.toString(), maxSpeed),
      prefs!.setString("drivingHours"+"-"+args!.id.toString(), drivingHours),
      prefs!.setString("fuel"+"-"+args!.id.toString(), fuel),

      setState(() {

      })
    });

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as DeviceArguments;

    return Scaffold(
          appBar: AppBar(
            title: Text(args!.name,
                style: TextStyle(color: CustomColor.secondaryColor)),
            iconTheme: IconThemeData(
              color: CustomColor.secondaryColor, //change your color here
            ),
          ),
          body: SingleChildScrollView(child: loadDevice()),
        );
  }

  Widget loadDevice() {
    //Device d = viewModel.devices[args.id];
    String iconPath;

    if (args!.device['icon_color'] != null) {
      if (args!.device['icon_color'] == "green") {
        iconPath = "images/marker_arrow_online.png";
      } else if (args!.device['icon_color'] == "yellow") {
        iconPath = "images/marker_arrow_static.png";
      } else {
        iconPath = "images/marker_arrow_offline.png";
      }
    } else {
      iconPath = "images/marker_arrow_static.png";
    }

    String status;
    return new Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(10),
        ),
        Container(
            padding: EdgeInsets.only(right: 15.0, left: 15.0, bottom: 15),child:tripDistance()),
        Container(
            padding: EdgeInsets.only(right: 15.0, left: 15.0),child: positionDetails()),
        Container(child: sensorInfo()),
        const Padding(
          padding: EdgeInsets.all(10),
        ),
        Container(
            color: CustomColor.primaryColor,
            child: bottomButton())
      ],
    );
  }


  String getAddress(lat, lng) {
    setState(() {});
    if (lat != null) {
      API.getGeocoder(lat, lng).then((value) => {
        if (value != null)
          {
            latLng = LatLng(
                double.parse(lat.toString()), double.parse(lng.toString())),
            address = value,
            setState(() {}),
          }
        else
          {address = "Address not found", setState(() {})}
      });
    } else {
      address = "Address not found";
    }
    return address;
  }


  Widget positionDetails() {
    if (args!.device != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey, spreadRadius: 1, blurRadius: 1.0),
          ],
        ),
        child: Column(children: <Widget>[
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(top: 3.0, left: 5.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 3.0),
                            child: Text(("positionAddress").tr()),
                          ),
                        ],
                      )),
                  Container(
                    width:MediaQuery.of(context).size.width * 0.5,
                      padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                      child:
                      GestureDetector(
                        onTap: () {
                          address = "Loading....";
                          setState(() {});
                          getAddress(args!.device['lat'], args!.device['lng']);
                        },
                        child: new Row(children: <Widget>[
                          Expanded(
                              child: Text(address != null ? address : "-",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis))
                        ]),
                      ))
                ],
              )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(top: 3.0, left: 5.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 3.0),
                              child: Text("positionFixTime").tr())
                        ],
                      )),
                  Container(
                    width:MediaQuery.of(context).size.width * 0.6,
                      padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                      child: Text(args!.device['time'],
                        textAlign: TextAlign.end, style: TextStyle(overflow:TextOverflow.ellipsis),),)
                ],
              )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(top: 3.0, left: 5.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 3.0),
                              child: Text("stopDuration").tr()
                          )
                        ],
                      )),
                  Container(
                      padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                      child: Text(args!.device['stop_duration']),)
                ],
              )),
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(top: 3.0, left: 5.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 3.0),
                              child: Text("sharedDrivers").tr()
                          )
                        ],
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                    child: Text(args!.device['driver']),)
                ],
              )),
          SizedBox(height: 5.0),
        ]),
      );
    } else {
      return Container();
    }
  }

  Widget tripDistance(){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey, spreadRadius: 1, blurRadius: 1.0),
        ],
      ),
      child: new Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                child: Text(('previousDaySummary').tr(), textAlign: TextAlign.start,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),)),
            Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(top: 3.0, left: 10.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.only(left: 3.0),
                                child: Text(('travelledDistance'.tr()))),
                          ],
                        )),
                    Container(
                      padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                      child: Text(totalDistance),
                    )
                  ],
                )),
            SizedBox(height: 5.0),
            Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(top: 3.0, left: 10.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.only(left: 3.0),
                                child: Text(('maxSpeed').tr())),
                          ],
                        )),
                    Container(
                      padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                      child: Text(maxSpeed),
                    )
                  ],
                )),
            SizedBox(height: 5.0),
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(top: 3.0, left: 10.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 3.0),
                              child: Text(('fuel').tr())),
                        ],
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                    child: Text(fuel != null ? fuel : "-"),
                  )
                ],
              )),
          SizedBox(height: 5.0),
          ]),
        ),
    );
  }

  Widget bottomButton() {
    return Container(
        padding: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width * 100,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: (){
                  showReportDialog(context, ('playback'));
                },
                child:Column(
                    children: [
                      Container(
                        child: Icon(Icons.repeat_outlined, color: Colors.white,),
                      ),
                      Text(("history").tr(), style: TextStyle(color: Colors.white),)
                    ]
                ),
              ),
              Container(
                  height: 50,
                  child: VerticalDivider(thickness: 1, color: Colors.grey)),
              GestureDetector(
                onTap: (){
                  showSavedCommandDialog(context);
                },
                child:Column(
                    children: [
                      Container(
                        child: Icon(Icons.send, color: Colors.white,),
                      ),
                      Text(("commandTitle").tr(), style: TextStyle(color: Colors.white),)
                    ]
                ),
              ),
              Container(
                  height: 50,
                  child: VerticalDivider(thickness: 1, color: Colors.grey)),
              GestureDetector(
                onTap: (){
                  showReportDialog(context, ('report'));
                },
                child:
                Column(
                  children: [
                    Container(
                      child: Icon(Icons.analytics, color: Colors.white,),
                    ),
                    Text(('report').tr(), style: TextStyle(color: Colors.white),)
                  ],
                ),
              )
            ]));
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
                if (value!.body != null)
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
                                              "Custom Command") {
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
                              _commandSelected == "Custom Command"
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
                                      backgroundColor:CustomColor.primaryColor,
                                    ),
                                    onPressed: () {
                                      sendSystemCommand(device);
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

  Widget sensorInfo() {

    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;

    List<Widget> sensors =[];
    double iconWidth = 30;

    int fuel = 0;

    if (args!.device['sensors'] != []) {
      try {
          args!.device['sensors'].forEach((sensor) {
              if (sensor['value'] != null) {
                sensors.add(
                    Container(
                        width: width / 4,
                        height: width * 0.2,
                        child:Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: <Widget>[
                              Image.asset("assets/images/sensors/"+sensor['type']+".png", width: iconWidth, height: iconWidth,),
                              Text(sensor["name"],style: TextStyle(
                                  fontSize: fontWidth * 20)),
                              Text(sensor['value'],
                                style: TextStyle(
                                    fontSize: fontWidth * 20),
                              )
                            ]))
                );
              }

              if (sensor['type'] == "fuel_tank") {
                fuel = sensor['val'];
              }
          });
      } catch (e) {}

      //
      // String maintenance = ("nextMaintenance")+":",
      //     tires =  ("changeOfTires")+":";
      // if(args!.device['services'] != null) {
      //   args!.device['services'].forEach((element) {
      //     if (element['name'] == "Maintenance") {
      //       maintenance = element['name'] + " " + element['value'];
      //     } else if (element['name'] == "Tires") {
      //       tires = element['name'] + " " + element['value'];
      //     }
      //   });
      // }

      
      return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child:Text(
                    ('sensors').tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: sensors,

                  )),
              Center(
                child:  ElevatedButton(
                  style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.pushNamed(context, "/reportFuel",
                        arguments: ReportArguments(args!.id, fromDate!,
                            fromTime!, toDate!, toTime!, args!.name, 10));
                  },
                  child: Text(
                      ('fuelReport').tr(),
                      style: TextStyle(fontSize: 16)),
                ),
              ),

            ],
          ));
    } else {
      return new Container();
    }
  }

  void showSavedCommandDialog(BuildContext context) {
    _commands.clear();
    _commandsValue.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              API.getSavedCommands(args!.id.toString()).then((value) => {
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
                                          child: Container(
                                              width: MediaQuery.of(context).size.width / 2,
                                              child:new Text(
                                           (value) !=
                                                null
                                                ?(value)
                                                : value,
                                            style: TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          )),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value ==
                                              "Custom Command") {
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
                              _commandSelected == "Custom Command"
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
                                      backgroundColor:CustomColor.primaryColor,
                                    ),
                                    onPressed: () {
                                      sendCommand();
                                    },
                                    child: Text(
                                      ('ok'),
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

  void sendCommand() {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': args!.id.toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id': args!.id.toString(),
        'type': _commandsValue[_selectedCommand]
      };
    }


    API.sendCommands(requestBody).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent'),
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
              msg: ('errorMsg'),
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

  void sendSystemCommand(dynamic device) {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
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
              msg: ('command_sent'),
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
              msg: ('errorMsg'),
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

  void showReportDialog(BuildContext context, String heading) {
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
                                  showReport(heading);
                                },
                                child: Text(
                                  ('ok'),
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

  void showReport(String heading) {
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
      if (dayCon < 10) {
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


    Navigator.pop(context);
    if (heading == ('report')) {
      Navigator.pushNamed(context, "/reportList",
          arguments: ReportArguments(args!.device['id'], fromDate, fromTime,
              toDate, toTime, args!.name, 0));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments: ReportArguments(args!.device['id'], fromDate, fromTime,
              toDate, toTime, args!.name, 0));
    }
  }
}

/// Sample linear data type.
class LinearFuel {
  DateTime? time;
  int? val;

  LinearFuel({this.time, this.val});
}
