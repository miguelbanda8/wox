import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/ui/custom_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart' as m;

import 'GeofenceList.dart';

class GeofenceAddPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _GeofenceAddPageState();
}

class _GeofenceAddPageState extends State<GeofenceAddPage> {
  static FenceArguments? args;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  Color _trafficButtonColor = CustomColor.primaryColor;
  Set<Marker> _markers = Set<Marker>();
  Set<Circle> _circles = Set<Circle>();
  double _valRadius = 100;
  double _valRadiusMax = 10000;
  bool addFenceVisible = false;
  bool deleteFenceVisible = false;
  bool addClicked = false;
  final TextEditingController _fenceName = new TextEditingController();
  LatLng? _position;
  SharedPreferences? prefs;
  User? user;
  int? deleteFenceId;
  bool isLoading = false;

  Marker? newFenceMarker;

  @override
  initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    String userJson = prefs!.getString("user")!;

    final parsed = json.decode(userJson);
    user = User.fromJson(parsed);
    setState(() {});
  }

  Future<BitmapDescriptor> _myPainterToBitmap(String label, String icon) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    CustomIcon myPainter = CustomIcon(label, icon);

    final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 30, color: Colors.black),
        ),
        textDirection: m.TextDirection.ltr);
    textPainter.layout();

    myPainter.paint(canvas,
        Size(textPainter.size.width + 30, textPainter.size.height + 25));
    final ui.Image image = await recorder.endRecording().toImage(
        textPainter.size.width.toInt() + 30,
        textPainter.size.height.toInt() + 25 + 50);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    Uint8List data = byteData!.buffer.asUint8List();
    setState(() {});
    return BitmapDescriptor.fromBytes(data);
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    mapController!.animateCamera(CameraUpdate.zoomTo(4));
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _trafficEnabledPressed() {
    setState(() {
      _trafficEnabled = _trafficEnabled == false ? true : false;
      _trafficButtonColor =
          _trafficEnabled == false ? CustomColor.primaryColor : Colors.green;
    });
  }

  void addFenceMarker() {
    if (addClicked) {
      setState(() {
        _myPainterToBitmap(
                ('newFence'), "marker")
            .then((BitmapDescriptor bitmapDescriptor) {
          _markers.add(Marker(
            markerId: MarkerId("marker"),
            position: _position!,
            icon: bitmapDescriptor,
            anchor: Offset(0.5, 1),
            draggable: true,
            onDragEnd: (value) {},
          ));
          updateNewCircle(_valRadius);
          addFenceVisible = true;
          mapController!.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _position!, zoom: 15)));
        });
      });
    }
  }

  void updateNewCircle(radius) {
    _circles = Set<Circle>();
    setState(() {
      _circles.add(Circle(
          circleId: CircleId("circle"),
          fillColor: Color(0x40189ad3),
          strokeColor: Color(0),
          strokeWidth: 2,
          center: _position!,
          radius: radius));
    });
  }

  void submitFence() {
    _showProgress(true);

    Map<String, String> geoPoint = <String, String>{
      'lat': _circles.first.center.latitude.toString(),
      'lng': _circles.first.center.longitude.toString()
    };

    Map<String, String> requestBody = <String, String>{
      'name': _fenceName.text,
      'polygon_color': "#c191c4",
      'polygon': '',
      'type': 'circle',
      'center': json.encode(geoPoint),
      'radius': _valRadius.toString(),
    };

    API.addGeofence(requestBody).then((value) => {
          Fluttertoast.showToast(
              msg: ("fenceAddedSuccessfully").tr(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          _showProgress(false)
        });
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 3,
  );

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as FenceArguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name!,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          onTap: (pos) {
            _position = pos;
            addClicked = true;
            addFenceMarker();
          },
          trafficEnabled: _trafficEnabled,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
            isLoading = true;
          },
          markers: _markers,
          circles: _circles,
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _onMapTypeButtonPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: CustomColor.primaryColor,
                  child: const Icon(Icons.map, size: 30.0),
                  mini: true,
                ),
                FloatingActionButton(
                  heroTag: "traffic",
                  onPressed: _trafficEnabledPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: _trafficButtonColor,
                  mini: true,
                  child: const Icon(Icons.traffic, size: 30.0),
                ),
              ],
            ),
          ),
        ),
        addFenceVisible ? addFenceControls() : new Container()
      ]),
    );
  }

  Widget addFenceControls() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    blurRadius: 20,
                    offset: Offset.zero,
                    color: Colors.grey.withOpacity(0.5))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Row(
                    children: <Widget>[
                      Container(
                          width: MediaQuery.of(context).size.width * 0.90,
                          padding: EdgeInsets.all(5.0),
                          child: TextField(
                            controller: _fenceName,
                            decoration: new InputDecoration(
                                labelText: ('fenceName')),
                          )),
                    ],
                  )),
              new Container(
                  width: MediaQuery.of(context).size.width * 0.97,
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    children: <Widget>[
                      Text(('radius')),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.65,
                          child: Slider(
                            value: _valRadius,
                            onChanged: (newSliderValue) {
                              setState(() {
                                _valRadius = newSliderValue;
                                updateNewCircle(_valRadius);
                              });
                            },
                            min: 100,
                            max: _valRadiusMax,
                          )),
                      Text(
                        _valRadius.toStringAsFixed(0),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )),
              new Container(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                          width: MediaQuery.of(context).size.width * 0.86,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_fenceName.text.isNotEmpty) {
                                submitFence();
                              } else {
                                Fluttertoast.showToast(
                                    msg: ("enterFenceName").tr(),
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.green,
                                    textColor: Colors.white,
                                    fontSize: 16.0);
                              }
                            },
                            child: Text(('addGeofence').tr()),
                          )),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
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

class Choice {
  const Choice({this.title, this.icon});

  final String? title;
  final IconData? icon;
}
