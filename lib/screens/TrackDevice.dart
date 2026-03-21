import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/Util.dart';
import 'package:gpspro/widgets/CustomProgressIndicatorWidget.dart';
import 'package:label_marker/label_marker.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' as m;

import 'CommonMethod.dart';

class TrackDevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TrackDeviceState();
}

class _TrackDeviceState extends State<TrackDevicePage> {
  static DeviceArguments? args;
  Set<Marker> _markers = Set<Marker>();
  bool? isLoading;
  MapType _currentMapType = MapType.normal;
  Color _mapTypeColor = CustomColor.primaryColor;
  double currentZoom = 14.0;
  bool _trafficEnabled = false;
  Color _trafficButtonColor = CustomColor.primaryColor;
  late DeviceStore deviceStore;

  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  double _dialogCommandHeight = 150.0;
  double _dialogHeight = 300.0;

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();
  Color _mapTypeBackgroundColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.secondaryColor;
  var device;

  PinInformation currentlySelectedPin = PinInformation(
      pinPath: '',
      avatarPath: '',
      speed: '',
      status: 'loading....',
      location: LatLng(0, 0),
      updatedTime: 'Loading....',
      name: 'Loading....',
      charging: false,
      ignition: "off",
      batteryLevel: 0,
      labelColor: Colors.grey);
  PinInformation? sourcePinInfo;
  PinInformation? destinationPinInfo;
  double pinPillPosition = 0;

  bool pageDestoryed = false;

  int _selectedperiod = 0;
  String address = ("showAddress").tr();
  bool isDarkMode = false;

  var latLng;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> newPolylinesData = [];

  LatLng? oldPin;

  @override
  initState() {
    isDarkMode = Provider.of<DeviceStore>(context, listen: false).darkMode;
    super.initState();

    drawPolyline();
    drawPolyline2();
    sourcePinInfo = PinInformation(
        name: "",
        location: LatLng(0, 0),
        address: '',
        speed: '',
        status: '',
        updatedTime: '',
        charging: false,
        ignition: "off",
        batteryLevel: 0,
        deviceId: 0,
        labelColor: Colors.blueAccent);
  }


  void drawPolyline2() async {
    PolylineId id = PolylineId("polyAnim");
    Polyline polyline = Polyline(
        width: 3,
        polylineId: id,
        color: Colors.blueAccent,
        points: newPolylinesData);
    polylines[id] = polyline;
    setState(() {});
  }


  void drawPolyline() async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 3,
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  String getAddress(lat, lng) {
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
          {address = "Address not found"}
      });
    } else {
      address = "Address not found";
    }
    return address;
  }

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 0,
  );

  void updateMarker(element) async {
    var iconPath;
    var markerIcon;
    bool rotation = false;
    if (element['icon_type'] == "arrow") {
      if (element['online'] == "online") {
        iconPath = "assets/images/arrow-green.png";
      } else if (element['online'] == "ack") {
        iconPath = "assets/images/arrow-ack.png";
      } else if (element['online'] == "engine") {
        iconPath = "assets/images/arrow-ack.png";
      } else if (element['online'] == "offline") {
        iconPath = "assets/images/arrow-red.png";
      }
      rotation = true;

      double devicePixelRatio = MediaQuery
          .of(context)
          .size
          .width / 6;

      try {
        markerIcon = await Util.getBitmapDescriptorFromAssetBytes(
            iconPath, devicePixelRatio.toInt());
      } catch (e) {
        iconPath =
            Uri.parse(SERVER_URL + "/" + element['icon']['path']);
        var dataBytes;
        var request = await http.get(iconPath);
        var bytes = request.bodyBytes;
        dataBytes = bytes;

        rotation = false;

        double devicePixelRatio = MediaQuery
            .of(context)
            .size
            .width / 6;

        markerIcon = await Util.getBitmapDescriptorFromBytes(
            dataBytes, devicePixelRatio.toInt(), context);
      }
    } else {
      iconPath =
          Uri.parse("$SERVER_URL/" + element['icon']['path']);
      var dataBytes;
      var request = await http.get(iconPath);
      var bytes = request.bodyBytes;
      dataBytes = bytes;
      rotation = false;

      double devicePixelRatio = MediaQuery
          .of(context)
          .size
          .width / 6;
      try {
        markerIcon = await Util.getBitmapDescriptorFromBytes(
            dataBytes, devicePixelRatio.toInt(), context);
      } catch (e) {
        markerIcon = await Util.getBitmapDescriptorFromAssetBytes(
            iconPath, devicePixelRatio.toInt());
      }
    }


    CameraPosition cPosition = CameraPosition(
      target: LatLng(double.parse(element['lat'].toString()),
          double.parse(element['lng'].toString())),
      zoom: currentZoom,
    );

    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));

    _markers = Set<Marker>();

    var pinPosition = LatLng(double.parse(element['lat'].toString()),
        double.parse(element['lng'].toString()));

    _markers.removeWhere((m) => m.markerId.value == element['id'].toString());
    if(element['icon']['type'] == "rotating"){
      rotation = true;
    }else{
      rotation = false;
    }
    _markers.add(Marker(
      markerId: MarkerId(element['id'].toString()),
      position: pinPosition,
      rotation: double.parse(element['course'].toString()),
      icon: markerIcon,
    ));

    _markers.addLabelMarker(LabelMarker(
      label: element['name'],
      markerId: MarkerId("label"+element['id'].toString()),
      position: LatLng(double.parse(element['lat'].toString()),
          double.parse(element['lng'].toString())),
    ));

    var battery;
    var batteryGPS, batteryVehicle, gsm, movement;
    String ignition = "-", door = "-", satellites = "-";

    //if (_selectedDeviceId == deviceId) {


    oldPin = LatLng(double.parse(element['lat'].toString()),
        double.parse(element['lng'].toString()));
    polylineCoordinates.add(oldPin!);
    print("Length"+polylineCoordinates.length.toString());
    //Starting the animation
    newPolylinesData.clear();
    if(polylineCoordinates.length > 40){
      polylineCoordinates.removeRange(0, 20);
    }

    currentlySelectedPin = sourcePinInfo!;

    if (_markers != null) {
      if (isLoading!) {
        _showProgress(false);
        isLoading = false;
        setState(() {});
      }
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType =
      _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
      _mapTypeBackgroundColor = _currentMapType == MapType.normal
          ? CustomColor.secondaryColor
          : CustomColor.primaryColor;
      _mapTypeForegroundColor = _currentMapType == MapType.normal
          ? CustomColor.primaryColor
          : CustomColor.secondaryColor;
    });
  }


  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  currentMapStatus(CameraPosition position) {
    currentZoom = position.zoom;
  }

  @override
  void dispose() {
    pageDestoryed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as DeviceArguments;
    deviceStore = Provider.of<DeviceStore>(context);

    return SafeArea(
          child: Scaffold(
              appBar: AppBar(
                title: Text(args!.name,
                    style: TextStyle(color: CustomColor.secondaryColor)),
                iconTheme: IconThemeData(
                  color: CustomColor.secondaryColor, //change your color here
                ),
              ),
              body: slidingPanel()),
    );
  }

  Widget slidingPanel() {
    return SlidingUpPanel(
      parallaxEnabled: true,
      minHeight: MediaQuery.of(context).size.height * 0.20,
      maxHeight: MediaQuery.of(context).orientation == Orientation.portrait ? MediaQuery.of(context).size.height * 0.45 :  MediaQuery.of(context).size.height * 0.70,
      parallaxOffset: .7,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
      panel: bottomPanelView(),
      body: buildMap(),
    );
  }

  Widget bottomPanelView() {
    deviceStore.devices.forEach((element) {
      element.items!.forEach((element) {
        if (element['id'] == args!.id) {
          if (element != null) {
            device = element;
          } else {}
        }
      });
    });
    Color? color;


    var batteryGPS, batteryVehicle, gsm, movement;
    String? status;

    String ignition = "-", door = "-", satellites = "-", odometer="-";
    if (device['icon_color'] != null) {
      if (device['icon_color'] == "green") {
        color = Colors.green;
        status = ("driving").tr();
      } else if (device['icon_color'] == "yellow") {
        color = YELLOW_CUSTOM;
        status = ("stopped").tr();
      } else {
        color = Colors.red;
        status =("parked").tr();
      }
    }

    double width = MediaQuery.of(context).size.width;
    double fontWidth = 1;
    double iconWidth = 30;
    List<Widget> sensors =[];

    sensors.add(
        Container(
            margin: EdgeInsets.all(3),
            padding: EdgeInsets.only(left: 2, right: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 1), // changes position of shadow
                ),
              ],
            ),
            child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset("assets/images/sensors/total-distance.png", width: iconWidth, height: iconWidth,),
                  Text(("totalDistance").tr()+": ",style: TextStyle(
                      fontSize: fontWidth * 10)),
                  Text(device['total_distance'].toString(),
                    style: TextStyle(
                        fontSize: fontWidth * 10),
                  )
                ])
        )
    );

    sensors.add(
        Container(
            margin: EdgeInsets.all(3),
            padding: EdgeInsets.only(left: 2, right: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 1), // changes position of shadow
                ),
              ],
            ),
            child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset("assets/images/sensors/speed.png", width: iconWidth, height: iconWidth,),
                  Text(("speed").tr()+": ",style: TextStyle(
                      fontSize: fontWidth * 10)),
                  Text(device['speed'].toString(),
                    style: TextStyle(
                        fontSize: fontWidth * 10),
                  )
                ])
        )
    );

    try {
      device['sensors'].forEach((sensor) {
        if (sensor['value'] != null) {
          sensors.add(
              Container(
                  margin: EdgeInsets.all(3),
                  padding: EdgeInsets.only(left: 2, right: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
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
    } catch (e) {}

    return Container(
        color: isDarkMode ? Colors.black : Colors.white,
      width: MediaQuery.of(context).size.width * 0.95,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(3)),
          Container(
              color: isDarkMode ? Colors.black : Colors.white,
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Row(children: <Widget>[
                      Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                          child: Icon(Icons.directions_car,
                              color: Colors.white, size: 18.0)),
                      Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.60,
                          child: Text(
                            device['name'],
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ]),
                    new Row(children: <Widget>[
                      Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      Container(
                        padding: EdgeInsets.fromLTRB(8, 1, 8, 1),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        child: Text(
                          status!,
                          style: TextStyle(
                              color: CustomColor.secondaryColor, fontSize: 12),
                        ),
                      ),
                      Padding(padding: new EdgeInsets.fromLTRB(0, 0, 5, 0)),
                    ]),
                  ])),
          Divider(),
          Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: new Column(
              children: [
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                      sensors,
                    )),
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
                child:Column(children: [
                  GestureDetector(
                  onTap: () {
                    address = "Loading....";
                    setState(() {});
                    getAddress(device['lat'], device['lng']);
                  },

                  child: new Row(children: <Widget>[
                    Icon(Icons.location_on_outlined,
                        color: CustomColor.primaryColor, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                    Expanded(
                        child: Text(address,
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis))
                  ]),
                ),
                Row(
                  children: [
                    Icon(Icons.speed, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      device['speed'].toString()+" mph",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      device['time'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      device['stop_duration'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
              padding: EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width * 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: new EdgeInsets.fromLTRB(0, 5, 0, 0)),
                  Container(
                      width: MediaQuery.of(context).size.width * 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                              width: 160,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: CustomColor.primaryColor,
                                  border: Border.all(
                                    color: CustomColor.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(25))
                              ),
                              child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: <Widget>[
                                    GestureDetector(
                                        onTap: () {
                                          showSavedCommandDialog(context);
                                        },
                                        child: Text(('commandTitle').tr(),
                                          style: TextStyle(color: Colors.white),))
                                  ])),
                          Padding(padding: EdgeInsets.all(5)),
                          Container(
                              width: 160,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: Colors.orange,
                                  border: Border.all(
                                      color: Colors.orange
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(25))
                              ),
                              child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: <Widget>[
                                    GestureDetector(
                                        onTap: () {
                                          showReportDialog(
                                              context, ('history'));
                                        },
                                        child: Text(('history').tr(),
                                          style: TextStyle(color: Colors.white),))
                                  ])),
                          //   ],
                          // )
                        ],
                      )),
                ],
              )),
        ],
      ),
    )
        ],));
  }

  Widget buildMap() {
    var val;
    deviceStore.devices.forEach((element) {
      element.items!.forEach((element) {
        if (element['id'] == args!.id) {
          if (element != null) {
            val = element;
            updateMarker(element);
          } else {}
        }
      });
    });
    if (val != null) {
      return Stack(
          children: <Widget>[
            Container(
              child: GoogleMap(
                mapType: _currentMapType,
                initialCameraPosition: _initialRegion,
                onCameraMove: currentMapStatus,
                trafficEnabled: _trafficEnabled,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  CustomProgressIndicatorWidget().showProgressDialog(context,
                      ('sharedLoading').tr());
                  isLoading = true;
                },
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 55, 5, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: _onMapTypeButtonPressed,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: _mapTypeBackgroundColor,
                      foregroundColor: _mapTypeForegroundColor,
                      mini: true,
                      child: const Icon(Icons.map, size: 30.0),
                    ),
                    FloatingActionButton(
                      heroTag: "reload",
                      mini: true,
                      onPressed: () async{
                        CameraPosition cPosition = CameraPosition(
                          target: LatLng(double.parse(device['lat'].toString()),
                              double.parse(device['lng'].toString())),
                          zoom: 17,
                        );

                        final GoogleMapController controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
                      },
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: CustomColor.primaryColor,
                      foregroundColor: CustomColor.secondaryColor,
                      child: const Icon(Icons.refresh, size: 30.0),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 200, 5, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  children: <Widget>[
                    Padding(padding: MediaQuery.of(context).size.aspectRatio > 0.55 ?  EdgeInsets.only(top: 60) : EdgeInsets.only(top: 260),
                        child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(device['speed'].toString(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),),
                                Text("mph", style: TextStyle(color: Colors.black, fontSize: 11),)
                              ],
                            ),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: CustomColor.primaryColor,
                                  width: 5,
                                )
                            ))
                    )
                  ],
                ),
              ),
            ),
          ]);

    } else {
      return Center(
        child: Text("No data"),
      );
    }
  }

  Future<void> _showProgress(bool status) async{
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
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
                        // Fluttertoast.showToast(
                        //     msg: AppLocalizations.of(context)
                        //         .translate("noData"),
                        //     toastLength: Toast.LENGTH_SHORT,
                        //     gravity: ToastGravity.CENTER,
                        //     timeInSecForIosWeb: 1,
                        //     backgroundColor: Colors.black54,
                        //     textColor: Colors.white,
                        //     fontSize: 16.0),
                        // Navigator.pop(context)
                      }
                  }
                else
                  {
                    // Fluttertoast.showToast(
                    //     msg: ("noData"),
                    //     toastLength: Toast.LENGTH_SHORT,
                    //     gravity: ToastGravity.CENTER,
                    //     timeInSecForIosWeb: 1,
                    //     backgroundColor: Colors.black54,
                    //     textColor: Colors.white,
                    //     fontSize: 16.0),
                    // Navigator.pop(context)
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
                                          if (value == ('commandCustom').tr()) {
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
                              _commandSelected == ('commandCustom').tr()
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
                                              ('commandCustom').tr()) {
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
                              _commandSelected == ('commandCustom').tr()
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

    print(fromDate);
    print(toDate);

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
