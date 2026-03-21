import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/screens/AssignFenceScreen.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAlertsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _AddAlertsPageState();
}

class _AddAlertsPageState extends State<AddAlertsPage> {
  Timer? _timer;
  SharedPreferences? prefs;
  User? user;
  bool isLoading = false;
  List<dynamic> devicesList = [];
  late DeviceStore deviceStore;

  List<String> selectedDevices = [];
  List<String> types = [];
  String selectedType = "Types";
  TextEditingController _nameCtl = TextEditingController();
  TextEditingController _typeCtl = TextEditingController();
  int _zoneSelected = 0;

  void typeList(){
    types = <String>[
      "Overspeed",
      "Stop Duration",
      "Offline Duration",
      "Ignition Duration",
      "Idle Duration",
      "Geofence In",
      "Geofence Out",
      "Geofence In/Out",
      "Start of movement",
      "SOS",
      "Fuel(Fill/Theft)",
      "Driver change unauthorized"
    ];
  }


  @override
  initState() {
    super.initState();
    getUser();
    getFences();
    typeList();
  }

  void getFences() async {
    API.getGeoFences().then((value) => {
      if (value != null)
        {
          fenceList.addAll(value),
          setState(() {}),
        }
      else
        {
          isLoading = false,
          setState(() {}),
        },
    });
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    String userJson = prefs!.getString("user")!;

    final parsed = json.decode(userJson);
    user = User.fromJson(parsed);
    setState(() {});
  }

  void addAlert() {
    _showProgress(true);
    List devices = [];
    devices.add(selectedDevices);
    String request;
    if (selectedType == "types" || selectedType == "Start of movement"
        || selectedType == "SOS" || selectedType == "Fuel(Fill/Theft)"
        || selectedType == "Driver change unauthorized"){
      request = "&name=" +
          _nameCtl.text +
          "&type=" +
          selectedType.toLowerCase() +
          "&" +
          devices[0].join("&");
    }else{
      if(selectedType == "Geofence In") {
        request = "&name=" +
            _nameCtl.text +
            "&type=geofence_in&"
                "&zone=0"+
            "&"+selectedFenceList.join("&") +"&"+
            devices[0].join("&");
      }else if(selectedType == "Geofence Out") {
        request = "&name=" +
            _nameCtl.text +
            "&type=geofence_out&"+
            "&zone=0" +
            "&" + selectedFenceList.join("&") +"&"+
            devices[0].join("&");
      }else if(selectedType == "Geofence In/Out") {
        request = "&name=" +
            _nameCtl.text +
            "&type=geofence_inout&"+
            "&zone=0" +
            "&" + selectedFenceList.join("&")  +"&"+
            devices[0].join("&");
      }else{
        request = "&name=" +
            _nameCtl.text +
            "&type=" +
            selectedType.toLowerCase() +
            "&" + selectedType.toLowerCase() + "=" +
            _typeCtl.text +
            "&" +
            devices[0].join("&");
      }
    }
    print(request);
    API.addAlert(request).then((value) => {
      if (value.statusCode == 200)
        {
          _showProgress(false),
          Fluttertoast.showToast(
              msg: "Alert Created",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop(),
        }
      else
        {
          _showProgress(false),
        }
    });
  }

  Widget deviceCard(device, BuildContext context, setState){
    return Container(
      child: Row(
        children: [
          Checkbox(value: selectedDevices.contains("devices[]="+device["id"].toString()), onChanged: (val){
            setState(() {
              if(val!) {
                selectedDevices.add("devices[]="+device["id"].toString());
              }else{
                selectedDevices.remove("devices[]="+device["id"].toString());
              }
            });
          }),
          Text(device["name"])
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void showFenceDialog(BuildContext context) {
    fenceList.clear();
    selectedFenceList.clear();
    bool loading = true;
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          if(fenceList.isEmpty) {
            API.getGeoFences().then((value) =>
            {
              if (value != null)
                {
                  fenceList.addAll(value),
                  loading = false,
                  setState(() {}),
                }
              else
                {
                  loading = false,
                  setState(() {}),
                },
            });
          }
          return AssignFenceScreen(context, setState, loading);
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
            appBar: AppBar(
              title: Text(("alerts"),
                  style: TextStyle(color: CustomColor.secondaryColor)),
              iconTheme: IconThemeData(
                color: CustomColor.secondaryColor, //change your color here
              ),
            ),
            body: loadView()
    );
  }

  Widget loadView(){
    deviceStore = Provider.of<DeviceStore>(context);
    devicesList = deviceStore.devicesList;
    // if(devicesList.isEmpty) {
    //   model.devices!.forEach((key, value) {
    //     devicesList.addAll(value.items!);
    //   });
    // }
    return Container(
        child:Column(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              child: TextField(
                controller: _nameCtl,
                decoration: InputDecoration(
                    hintText: "Alert Name"
                ),
              ),
            ),
            Container( padding: EdgeInsets.only(left: 10), alignment:Alignment.centerLeft, child: Text("Type"),),
            Container(
                padding: EdgeInsets.only(top: 5,bottom: 5, left: 10),
                width: 500,child:DropdownButton<String>(
              hint: Text(selectedType != "Types"
                  ? selectedType
                  : "Types"),
              items: types.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            )),
            selectedType == "Geofence In" || selectedType == "Geofence Out" || selectedType == "Geofence In/Out" ?
            InkWell(
                onTap: (){
                  showFenceDialog(context);
                },
                child: Column(children: [
                  Container(
                      width: MediaQuery.of(context).size.width,child:Card(
                    child: Padding(padding:EdgeInsets.all(5),child:Text("GeoFences")),
                  )),
                ],)
            ) : Container(),
            selectedType != "types" ? selectedType != "Start of movement" ? selectedType != "SOS" ? selectedType != "Fuel(Fill/Theft)" ? selectedType != "Driver change unauthorized" ?  selectedType != "Geofence In" ? selectedType != "Geofence Out" ? selectedType != "Geofence In/Out"
                ? Container(
                padding: EdgeInsets.only(top: 5,bottom: 10, left: 10),
                child: TextField(
                  controller: _typeCtl,
                  decoration: InputDecoration(
                      hintText: "Value"
                  ),
                )
            ) : Container() : Container() : Container() : Container() : Container(): Container(): Container(): Container(),
            Container( padding: EdgeInsets.only(left: 10), alignment:Alignment.centerLeft, child: Text("Devices"),),
            Expanded(child:ListView.builder(
                itemCount: devicesList.length,
                itemBuilder: (context, index) {
                  final device = devicesList[index];
                  return deviceCard(device, context,setState);
                })),
            FloatingActionButton.extended(
              onPressed: () {
                addAlert();
              },
              label: Text("Save"),
            ),
            Padding(padding: EdgeInsets.only(bottom: 5))
          ],
        ));
  }

  Future<void> _showProgress(bool status) async{
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(('sharedLoading').tr())),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }
}
