import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/main.dart';
import 'package:gpspro/model/Device.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/model/Place.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/Util.dart';
import 'package:label_marker/label_marker.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' as m;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

import 'Geofence.dart';


class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _controller = Completer();
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  TextEditingController _searchController = new TextEditingController();
  PanelController _pc = new PanelController();

  GoogleMapController? mapController;
  Set<Marker> _markers = Set<Marker>();
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  Color _trafficButtonColor = CustomColor.primaryColor;
  Color _mapTypeColor = CustomColor.primaryColor;
  int _selectedDeviceId = 0;
  bool deviceSelected = false;
  LatLng? _location;
  var device;
  double _dialogHeight = 300.0;
  int _selectedperiod = 0;
  TextEditingController _shareEmail = new TextEditingController();

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  TimeOfDay _selectedFromTime = TimeOfDay.now();
  TimeOfDay _selectedToTime = TimeOfDay.now();

  Color _mapTypeBackgroundColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.secondaryColor;

  String address = "Loading...";
  bool isDarkMode = false;

  var latLng;
  double currentZoom = 13;
  List<dynamic> devicesList = [];
  List<dynamic> _searchResult = [];
  String selectedIndex = "all";
  Timer? _timer;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  bool first = true;
  bool streetView = false;
  double slidingPanelHeight = 0;

  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  String _commandSelected = "";
  double _dialogCommandHeight = 150.0;
  final TextEditingController _customCommand = new TextEditingController();

  bool isTextEnabled = true;
  Set<Circle> _circles = Set<Circle>();
  Set<Polygon> _polygons = {};
  List<Geofence> fenceList = [];
  late DeviceStore deviceStore;
  late ClusterManager _manager;

  bool isFollow = true;
  final GlobalKey globalKey = GlobalKey();
  int expiryTime = 10;

  @override
  initState() {
    super.initState();
    isDarkMode = Provider.of<DeviceStore>(context, listen: false).darkMode;
  }

  List<Place> items = [];

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _pc.close();
    setState(() {
      _location = LatLng(position.latitude, position.longitude);
    });
  }

  void addMarker() async{
    _markers = Set<Marker>();
    LatLngBounds? bound;
    if (!deviceStore.isLoading) {
      deviceStore.devices.forEach((value) {
        if (value.items!.isNotEmpty) {
          if(!value.items!.contains("time")) {
            value.items!.forEach((element) async {
              if (element["device_data"]["active"].toString() == "1") {
                var iconPath;
                var markerIcon;
                bool rotation = false;

                Color? color;

                if (element['online'] == "online") {
                  color = Colors.green;
                } else if (element['online'] == "ack") {
                  color = Colors.yellow;
                } else if (element['online'] == "engine") {
                  color = Colors.yellow;
                  ;
                } else if (element['online'] == "offline") {
                  color = Colors.red;
                }

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
                  rotation = false;

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
                var pinPosition = LatLng(double.parse(element['lat'].toString()),
                    double.parse(element['lng'].toString()));

                _markers.removeWhere((m) =>
                m.markerId.value == element['id'].toString());


                _markers.removeWhere((m) =>
                m.markerId.value == "label"+element['id'].toString());

                if (element['lat'] != 0) {
                  _markers.add(Marker(
                    markerId: MarkerId(element['id'].toString()),
                    position: pinPosition,
                    // updated position
                    // rotation: rotation ? double.parse(
                    //     element['course'].toString()) : 0,
                    // rotation: double.parse(
                    //     element['course'].toString()),
                    icon: markerIcon,
                    onTap: () {
                      mapController!.getZoomLevel().then((value) =>
                      {
                        if (value < 14)
                          {
                            currentZoom = 16,
                          }
                      });

                      CameraPosition cPosition = CameraPosition(
                        target: LatLng(double.parse(element['lat'].toString()),
                            double.parse(element['lng'].toString())),
                        zoom: currentZoom,
                      );
                      mapController!
                          .moveCamera(CameraUpdate.newCameraPosition(cPosition));
                      address = "Loading...";
                      setState(() {
                        _selectedDeviceId = element['id'];
                        slidingPanelHeight = 230;
                        // device = cluster.items.first.device;

                        //fixme
                        polylines.clear();
                        polylineCoordinates.clear();
                        if (device != null && device['tail'] != null) {
                          print("🔹 tail: ${device['tail']}");
                          for (var tail in device['tail']) {
                            polylineCoordinates.add(LatLng(
                              double.parse(tail['lat'].toString()),
                              double.parse(tail['lng'].toString()),
                            ));
                          }
                        }
                        drawPolyline();
                        if (device != null && device['lat'] != null && device['lng'] != null) {
                          polylineCoordinates.add(LatLng(
                            double.parse(device['lat'].toString()),
                            double.parse(device['lng'].toString()),
                          ));
                        }
                        //fixme
                      });
                    },
                  ));

                  _markers.addLabelMarker(LabelMarker(
                    label: element['name'],
                    markerId: MarkerId("label"+element['id'].toString()),
                    position: LatLng(double.parse(element['lat'].toString()),
                        double.parse(element['lng'].toString())),
                  ));

                }
              }
            });
          }
        }
      });
      _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
        if (bound != null) {
          CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound!, 50);
          if (this.mapController != null) {
            this.mapController!.animateCamera(u2).then((void v) {
              check(u2, this.mapController!);
            });
            _timer!.cancel();
            setState(() {});
          }
        }
      });
    }
  }

  void drawPolyline() async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 4,
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  void getFences() async {
    API.getGeoFences().then((value) {
      if (value != null && value.isNotEmpty) {
        value.forEach((element) {
          // 🔹 Caso círculo
          if (element.type == "circle" && element.center != null && element.radius != null) {
            print("circle point: element.center=${element.center}");
            _updateCircle(
              element.id,
              element.center!['lat'],
              element.center!['lng'],
              element.radius,
              element.polygonColor,
            );
          }

          // 🔹 Caso polígono
          if (element.type == "polygon" && element.coordinates != null) {
            print("Polygon element.id=${element.id}, coordinates=${element.coordinates}");
            _updatePolygon(
              element.id!,
              element.coordinates,
              element.polygonColor,
            );
          }
        });
      }

      setState(() {});
    });
  }



  void _updateCircle(dynamic id, dynamic lat, dynamic lng, dynamic radius,String? polygonColor) {
    if (lat == null || lng == null || radius == null) return;

    double latValue = double.tryParse(lat.toString()) ?? 0.0;
    double lngValue = double.tryParse(lng.toString()) ?? 0.0;
    double radiusValue = double.tryParse(radius.toString()) ?? 0.0;

    CameraPosition cPosition = CameraPosition(
      target: LatLng(latValue, lngValue),
      zoom: 14,
    );

    setState(() {
      _circles.add(Circle(
        circleId: CircleId(id.toString()),
        fillColor: hexToColor(polygonColor ?? "#000000", opacity: 0.25),
        strokeColor: hexToColor(polygonColor ?? "#000000"),
        strokeWidth: 2,
        center: LatLng(latValue, lngValue),
        radius: radiusValue,
      ));
    });
  }

  void _updatePolygon(int id, List<dynamic>? coordinates, String? polygonColor) {
    if (coordinates == null || coordinates.isEmpty) return;

    List<LatLng> polygonLatLng = coordinates.map((point) {
      double lat = double.tryParse(point['lat'].toString()) ?? 0.0;
      double lng = double.tryParse(point['lng'].toString()) ?? 0.0;
      return LatLng(lat, lng);
    }).toList();

    if (polygonLatLng.isEmpty) return;

    Polygon polygon = Polygon(
      polygonId: PolygonId(id.toString()),
      points: polygonLatLng,
      fillColor: hexToColor(polygonColor ?? "#000000", opacity: 0.25),
      strokeColor: hexToColor(polygonColor ?? "#000000"),
      strokeWidth: 2,
    );

    setState(() {
      _polygons.add(polygon);
    });

    mapController?.animateCamera(CameraUpdate.newLatLng(polygonLatLng.first));
  }






  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void updateMarker(List<Device> dev) async {
    dev.forEach((value) {
      if (value.items!.isNotEmpty) {
        if(!value.items!.contains("time")) {
          value.items!.forEach((element) async {
            if(element["device_data"]["active"].toString() == "0") {
              _markers.removeWhere((m) =>
              m.markerId.value == element['id'].toString());
              _markers.removeWhere(
                      (m) => m.markerId.value == "t_" + element['id'].toString());

            }

            if (element["device_data"]["active"].toString() == "1") {
              var iconPath;
              var markerIcon;
              bool rotation = false;

              Color? color;

              setState(() {
                if(_selectedDeviceId == element['id']){
                  device = element;
                  if(isFollow) {
                    /*CameraPosition cPosition = CameraPosition(
                      target: LatLng(double.parse(device['lat'].toString()),
                          double.parse(device['lng'].toString())),
                      zoom: currentZoom,
                    );
                    mapController!.moveCamera(
                        CameraUpdate.newCameraPosition(cPosition));*/
                    LatLng newTarget = LatLng(
                      double.parse(device['lat'].toString()),
                      double.parse(device['lng'].toString()),
                    );

                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(newTarget),
                    );
                  }
                }
              });
              if (element['online'] == "online") {
                color = Colors.green;
              } else if (element['online'] == "ack") {
                color = Colors.yellow;
              } else if (element['online'] == "engine") {
                color = Colors.yellow;
              } else if (element['online'] == "offline") {
                color = Colors.red;
              }

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

                  markerIcon = await Util.getBitmapDescriptorFromBytes(
                      dataBytes, devicePixelRatio.toInt(), context);
                }
              } else {
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
                try {
                  markerIcon = await Util.getBitmapDescriptorFromBytes(
                      dataBytes, devicePixelRatio.toInt(), context);
                } catch (e) {
                  markerIcon = await Util.getBitmapDescriptorFromAssetBytes(
                      iconPath, devicePixelRatio.toInt());
                }
              }
              _markers.removeWhere((m) =>
              m.markerId.value == element['id'].toString());


              _markers.removeWhere((m) =>
              m.markerId.value == "label"+element['id'].toString());
              var pinPosition = LatLng(double.parse(element['lat'].toString()),
                  double.parse(element['lng'].toString()));
              if (element['lat'] != 0) {

                _markers.add(Marker(
                  markerId: MarkerId(element['id'].toString()),
                  position: pinPosition,
                  // updated position
                  rotation: element['icon_type'] != "icon"
                      ? double.parse(element['course'].toString())
                      : 0.0,
                  // rotation: double.parse(
                  //     element['course'].toString()),
                  icon: markerIcon,
                  anchor: Offset(0.5,0.25),
                  onTap: () {
                    device = element;
                    mapController!.getZoomLevel().then((value) =>
                    {
                      if (value < 14)
                        {
                          currentZoom = 16,
                        }
                    });

                    CameraPosition cPosition = CameraPosition(
                      target: LatLng(double.parse(element['lat'].toString()),
                          double.parse(element['lng'].toString())),
                      zoom: currentZoom,
                    );
                    mapController!
                        .moveCamera(CameraUpdate.newCameraPosition(cPosition));
                    address = "Loading...";
                    setState(() {
                      _selectedDeviceId = element['id'];
                      slidingPanelHeight = 230;
                      // device = cluster.items.first.device;
                      //fixme
                      polylines.clear();
                      polylineCoordinates.clear();
                      if (device != null && device['tail'] != null) {
                        print("🔹 tail: ${device['tail']}");
                        for (var tail in device['tail']) {
                          polylineCoordinates.add(LatLng(
                            double.parse(tail['lat'].toString()),
                            double.parse(tail['lng'].toString()),
                          ));
                        }
                      }
                      drawPolyline();
                      device = element;
                      if (device != null && device['lat'] != null && device['lng'] != null) {
                        polylineCoordinates.add(LatLng(
                          double.parse(device['lat'].toString()),
                          double.parse(device['lng'].toString()),
                        ));
                      }
                      //fixme
                    });
                  },
                ));

                _markers.addLabelMarker(LabelMarker(
                  label: element['name'],
                  markerId: MarkerId("label"+element['id'].toString()),
                  position: LatLng(double.parse(element['lat'].toString()),
                      double.parse(element['lng'].toString())),
                ));

                if (_selectedDeviceId == element['id']) {
                    device = element;
                    if (device != null && device['lat'] != null && device['lng'] != null) {
                        polylineCoordinates.add(LatLng(
                          double.parse(device['lat'].toString()),
                          double.parse(device['lng'].toString()),
                        ));
                    }
                }
              }
            }
          });
        }
      }
    });
  }


  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType =
      _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
      _mapTypeColor = _currentMapType == MapType.normal
          ? CustomColor.primaryColor
          : Colors.green;
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _reloadMap() {
    device = null;
    _selectedDeviceId = 0;
    setState(() {});
    slidingPanelHeight = 0;
    LatLngBounds bound = boundsFromLatLngList(_markers);

    polylines.clear();
    polylineCoordinates.clear();
    setState(() {});
    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 100);
    this.mapController!.animateCamera(u2).then((void v) {
      check(u2, this.mapController!);
    });

    _pc.close();
    Fluttertoast.showToast(
        msg: ("showingAllDevices").tr(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _streetView() {
    deviceStore.devices.forEach((value) {
      value.items!.forEach((element) {
        if (_selectedDeviceId == element['id']) {
          launch("https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=" +
              element['lat'].toString() +
              "," +
              element['lng'].toString()+"&heading=0&pitch=0&fov=80");
        }
      });
    });
  }

  void moveToMarker(device) {
    if(device["device_data"]["active"].toString() == "1") {
      var iconPath = device['icon']['path'];
      if (device['lat'] != null) {
        CameraPosition cPosition = CameraPosition(
          target: LatLng(double.parse(device['lat'].toString()),
              double.parse(device['lng'].toString())),
          zoom: currentZoom,
        );
        mapController!.moveCamera(CameraUpdate.newCameraPosition(cPosition));
        _selectedDeviceId = device['id'];
        onSearchTextChanged(_searchController.text);
        setState(() {
          slidingPanelHeight = 230;
          _selectedDeviceId = device['id'];
          streetView = true;
          polylines.clear();
          polylineCoordinates.clear();
          //fixme
          polylines.clear();
          polylineCoordinates.clear();
          if (device != null && device['tail'] != null) {
            print("🔹 tail: ${device['tail']}");
            for (var tail in device['tail']) {
              polylineCoordinates.add(LatLng(
                double.parse(tail['lat'].toString()),
                double.parse(tail['lng'].toString()),
              ));
            }
          }
          drawPolyline();
          if (device != null && device['lat'] != null && device['lng'] != null) {
            polylineCoordinates.add(LatLng(
              double.parse(device['lat'].toString()),
              double.parse(device['lng'].toString()),
            ));
          }
          //fixme
        });
        Navigator.pop(context);
      }
    }
  }

  void refreshData() {
    API.getDevices().then((value) => {
      onSearchTextChanged(_searchController.text),
      _showProgress(false)
    });
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(-15.793889, -47.882778),
    zoom: 0,
  );

  onSearchTextChanged(String text) async {
    _searchResult.clear();

    if (text.toLowerCase().isEmpty) {
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

  void addAnchor(dynamic d) {
    _circles = Set<Circle>();
    setState(() {
      _circles.add(Circle(
          circleId: CircleId(d['name']+"_fence_lock"),
          fillColor: Color(0x40e53035),
          strokeColor: Color(0),
          strokeWidth: 2,
          center: LatLng(double.parse(d['lat'].toString()), double.parse(d['lng'].toString())),
          radius: 500));
    });
    submitFence(d);
  }

  void submitFence(dynamic d) {
    Map<String, String> geoPoint = <String, String>{
      'lat': _circles.first.center.latitude.toString(),
      'lng': _circles.first.center.longitude.toString()
    };

    Map<String, String> requestBody = <String, String>{
      'name': d['name']+"_fence_lock",
      'polygon_color': "#c191c4",
      'polygon': '',
      'type': 'circle',
      'center': json.encode(geoPoint),
      'radius': "500",
    };
    prefs!.setBool(d['id'].toString()+"_fence_lock", true);

    API.addGeofence(requestBody).then((value) => {
      setState(() {

      }),
      Fluttertoast.showToast(
          msg: "Anchor Added",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0),
    });
  }


  void removeMarker(val, device) async{
    _showProgress(true);
    if(val) {
      Map<String, String> requestBody = <String, String>{
        'id': device["id"].toString(),
        'active': "1"
      };
      API.activateDevice(requestBody).then((value) => {
        refreshData(),
      });
    }else{
      Map<String, String> requestBody = <String, String>{
        'id': device["id"].toString(),
        'active': "0"
      };
      API.activateDevice(requestBody).then((value) => {
        refreshData(),
        _markers.removeWhere((m) =>
        m.markerId.value ==  device["id"].toString()),

        _markers.removeWhere(
                (m) => m.markerId.value == "t_" + device['id'].toString()),
        setState(() {

        })
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    deviceStore = Provider.of<DeviceStore>(context);
    devicesList = deviceStore.devicesList;
    return  Scaffold(
        key: _drawerKey,
        drawer: SizedBox(width: 250, child: navDrawer()),
        appBar: AppBar(
          title: Text(device != null ? device["name"] : ("map").tr(),
              style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor, //change your color here
          ),
          leading: _selectedDeviceId > 0
              ? new IconButton(
            icon: new Icon(Icons.arrow_back_ios),
            onPressed: () => {_reloadMap()},
          )
              : new Container(),
        ),
        body:!deviceStore.isLoading ? slidingPanel() : const Center(child: CircularProgressIndicator()));
  }

  Widget navDrawer() {
    return Drawer(
        child: new Column(children: <Widget>[
          new Container(
            child: new Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: new Card(
                child: new ListTile(
                  leading: new Icon(Icons.search),
                  title: new TextField(
                    controller: _searchController,
                    decoration: new InputDecoration(
                        hintText: ('Buscar'),
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 12)),
                    onChanged: onSearchTextChanged,
                  ),
                  trailing: new IconButton(
                    icon: new Icon(Icons.cancel),
                    onPressed: () {
                      _searchController.clear();
                      onSearchTextChanged('');
                    },
                  ),
                ),
              ),
            ),
          ),
          new Expanded(
              child:_searchResult.length != 0 || _searchController.text.isNotEmpty
                  ? new ListView.builder(
                itemCount: _searchResult.length,
                itemBuilder: (context, index) {
                  final device = _searchResult[index];
                  return deviceCard(device, context);
                },
              )
                  : selectedIndex == "all"
                  ? new ListView.builder(
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return deviceCard(device, context);
                  })
                  : new ListView.builder(
                  itemCount: 0,
                  itemBuilder: (context, index) {
                    return Text(("noDeviceFound").tr());
                  })
          )
        ]));
  }

  Widget deviceCard(device, BuildContext context) {
    Color? color;

    if (device['icon_color'] != null) {
      if (device['icon_color'] == "green") {
        color = Colors.green;
      } else if (device['icon_color'] == "yellow") {
        color = Colors.yellow;
      } else {
        color = Colors.red;
      }
    } else {
      color = Colors.yellow;
    }

    return
      GestureDetector(
        onTap: () => {moveToMarker(device)},
        child:Card(
            elevation: 2.0,
            child: Padding(
              padding: new EdgeInsets.all(1.0),

              child:Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Checkbox(value: device["device_data"]["active"].toString()  == "1" ? true : false, onChanged: (val){
                        removeMarker(val, device);
                      }),
                      Container(
                        width: MediaQuery.of(context).size.width / 3,
                        child: Text(
                          device['name'],
                          softWrap: true, // Permite saltos de línea
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Negrita
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(8, 1, 8, 1),
                        decoration: BoxDecoration(
                          color: parseColor(device['icon_color']),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Text(
                          //convertSpeed(double.parse(device['speed'].toString()), " mph"),
                          (device['speed']?.toStringAsFixed(0) ?? "0")+" kph",
                          style: TextStyle(color: CustomColor.secondaryColor, fontSize: 10),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: new EdgeInsets.fromLTRB(15,0,0,0),
                    child:
                    Text(
                      device['time'],
                      textAlign: TextAlign.start,
                      style: TextStyle(fontSize: 11),
                    ),
                  )
                ],
              ),
            )
        ),
      );
  }

  Widget slidingPanel() {
    if (first) {
      addMarker();
      first = false;
    }else{
      if(deviceStore.devices.isNotEmpty){
        updateMarker(deviceStore.devices);
      }
    }
    return SlidingUpPanel(
      minHeight: slidingPanelHeight,
      parallaxEnabled: true,
      controller: _pc,
      maxHeight: MediaQuery.of(context).size.height * 0.55,
      parallaxOffset: .7,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
      panel: _selectedDeviceId != 0 ? bottomPanelView() : new Container(),
      body: buildMap(),
    );
  }

  Widget bottomPanelView() {

    String status;
    double width = MediaQuery.of(context).size.width;
    double fontWidth = MediaQuery.of(context).size.aspectRatio;
    double iconWidth = 30;
    List<Widget> sensors =[];

    // Factores de escala
    double iconSize = 30; // tamaño de los iconos
    double textSize = 14; // tamaño del texto del nombre
    double valueSize = 14; // tamaño del valor
    double verticalPadding = 6; // padding vertical del container

// Total Distance
    sensors.add(
      Container(
        margin: EdgeInsets.all(3),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              "assets/images/sensors/total-distance.png",
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ("totalDistance").tr(),
                  style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                ),
                Text(
                  device['total_distance'].toString(),
                  style: TextStyle(fontSize: valueSize),
                ),
              ],
            ),
          ],
        ),
      ),
    );

// Speed
    sensors.add(
      Container(
        margin: EdgeInsets.all(3),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              "assets/images/sensors/speed.png",
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ("speed").tr(),
                  style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                ),
                Text(
                  device['speed'].toString(),
                  style: TextStyle(fontSize: valueSize),
                ),
              ],
            ),
          ],
        ),
      ),
    );

// Sensores dinámicos
    try {
      device['sensors'].forEach((sensor) {
        if (sensor['value'] != null) {
          sensors.add(
            Container(
              margin: EdgeInsets.all(3),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: verticalPadding),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    "assets/images/sensors/${sensor['type']}.png",
                    width: iconSize,
                    height: iconSize,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${sensor["name"]}",
                        style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        sensor['value'].toString(),
                        style: TextStyle(fontSize: valueSize),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error cargando sensores: $e");
    }





    return Container(
      width: MediaQuery.of(context).size.width /1.5,
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(3)),
          Center(
            child: Container(
              width: 100,
              padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
              decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
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
                            color: parseColor(device['icon_color']),
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                          child: Icon(Icons.directions_car,
                              color: Colors.white, size: 18.0)),
                      Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Text(
                            device['name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ]),
                    new Row(children: <Widget>[
                      Padding(
                          padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      InkWell(
                        child: Icon(Icons.info,
                            color: CustomColor.primaryColor,
                            size: 30.0),
                        onTap: () {
                          Navigator.pushNamed(context, "/deviceInfo",
                              arguments: DeviceArguments(
                                  device['id'], device['name'], device));
                        },
                      ),
                      Padding(
                          padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      InkWell(
                        child: Icon(Icons.directions,
                            color: CustomColor.primaryColor,
                            size: 30.0),
                        onTap: () async {
                          String origin = device["lat"].toString() +
                              "," +
                              device["lng"]
                                  .toString(); // lat,long like 123.34,68.56

                          var url = '';
                          var urlAppleMaps = '';
                          if (Platform.isAndroid) {
                            String query = Uri.encodeComponent(origin);
                            url =
                            "https://www.google.com/maps/search/?api=1&query=$query";
                            await launch(url);
                          } else {
                            urlAppleMaps =
                            'https://maps.apple.com/?q=$origin';
                            url =
                            "comgooglemaps://?saddr=&daddr=$origin&directionsmode=driving";
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else if (await canLaunch(
                                  urlAppleMaps)) {
                                await launch(urlAppleMaps);
                              } else {
                                throw 'Could not launch $url';
                              }
                              throw 'Could not launch $url';
                            }
                          }
                        },
                      ),
                      Padding(
                          padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      InkWell(
                        child: Icon(Icons.play_circle_outline,
                            color: CustomColor.primaryColor,
                            size: 30.0),
                        onTap: () {
                          showReportDialog(context, ('playback'));
                        },
                      ),
                      Padding(
                          padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                      InkWell(
                        child: prefs != null ? prefs!.getBool(device['id'].toString()+"_fence_lock") != null ? prefs!.getBool(device['id'].toString()+"_fence_lock")! ? Icon(Icons.anchor,
                            color: CustomColor.primaryColor,
                            size: 30.0) :  Icon(Icons.anchor,
                            color: Colors.red,
                            size: 30.0) :  Icon(Icons.anchor,
                            color: Colors.red,
                            size: 30.0) : Icon(Icons.anchor,
                            color: Colors.red,
                            size: 30.0),
                        onTap: () {
                          if (prefs!.getBool(device['id'].toString() + "_fence_lock") == true) {
                            Fluttertoast.showToast(
                              msg: ("Anchor Added already").tr(),
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          } else {
                            addAnchor(device);
                          }

                        },
                      ),
                    ])
                  ])),
          Divider(),
          Container(
              padding: EdgeInsets.all(10),
              color: isDarkMode ? Colors.black : Colors.white,
              width: MediaQuery.of(context).size.width * 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: sensors,
                      )),
                ],
              )),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // menos separación
              children: [
                // 🔹 Playback / History
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.blueAccent, // nuevo color
                    ),
                    onPressed: () {
                      showReportDialog(context, ('playback'));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ("history").tr(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Command
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.deepOrangeAccent, // nuevo color
                    ),
                    onPressed: () {
                      showSavedCommandDialog(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ("commandTitle").tr(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Report
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.red, // nuevo color
                    ),
                    onPressed: () {
                      showReportDialog(context, ('report'));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ("report").tr(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 0),
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
            child: new Column(
              children: [
                new Row(children: <Widget>[
                  Icon(Icons.location_on_outlined,
                      color: CustomColor.primaryColor, size: 18.0),
                  Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                  Expanded(
                      child: addressLoad(device['lat'].toString(), device['lng'].toString())),
                ]),
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
                    Icon(Icons.speed, color: Colors.grey, size: 18.0),
                    Padding(padding: new EdgeInsets.fromLTRB(6, 0, 0, 0)),
                    Text(
                      //device['speed'].toString()+" mph",
                      (device['speed']?.toStringAsFixed(0) ?? "0")+" kph",
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
        ],
      ),
    );
  }


  Widget addressLoad(String lat, lng){
    return FutureBuilder<String>(
        future: API.getGeocoderAddress(lat, lng),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!.replaceAll('"', ''), style: TextStyle(
                color: Colors.black,
                fontFamily: "Popins",
                fontSize: 11),);
          } else {
            return Container(child: Text("..."),);
          }
        }
    );
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
              API.getSavedCommands(device["id"].toString()).then((value) => {
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

  void sendCommand() {
    Map<String, String> requestBody;
    if (_commandSelected == "Custom Command") {
      requestBody = <String, String>{
        'id': "",
        'device_id': device["id"].toString(),
        'type': _commandsValue[_selectedCommand],
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id': device["id"].toString(),
        'type': _commandsValue[_selectedCommand]
      };
    }



    API.sendCommands(requestBody).then((res) {
      if (res.statusCode == 200) {
        Fluttertoast.showToast(
          msg: ('command_sent').tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.of(context).pop();
      } else {
        String errorMsg = "Error desconocido";
        try {
          final body = json.decode(res.body);
          if (body != null && body['message'] != null) {
            errorMsg = body['message'];
          }
        } catch (e) {
          print("Error parseando el body: $e");
        }

        Fluttertoast.showToast(
          msg: errorMsg,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.of(context).pop();
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


  Widget buildMap() {
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
        ),
        Stack(
            children: [
              GoogleMap(
                mapType: _currentMapType,
                initialCameraPosition: _initialRegion,
                trafficEnabled: _trafficEnabled,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  mapController = controller;
                  _onMapCreated();
                  getFences();
                },
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
                circles: _circles,
                polygons: _polygons,
                polylines: Set<Polyline>.of(polylines.values),
                onTap: (LatLng latLng) {
                  setState(() {
                    _pc.close();
                    slidingPanelHeight = 0;
                    streetView = false;
                  });
                },
              )]),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 7, 0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  heroTag: "layers",
                  mini: true,
                  onPressed: _onMapTypeButtonPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: _mapTypeBackgroundColor,
                  foregroundColor: _mapTypeForegroundColor,
                  child: const Icon(Icons.layers, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "reloadMap",
                  mini: true,
                  onPressed: _reloadMap,
                  backgroundColor: CustomColor.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.secondaryColor,
                  child: const Icon(Icons.refresh, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "myLocation",
                  mini: true,
                  onPressed: () async{
                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    _pc.close();
                    setState(() {
                      _location = LatLng(position.latitude, position.longitude);
                    });

                    CameraPosition cPosition = CameraPosition(
                      target: LatLng(double.parse(position.latitude.toString()),
                          double.parse(position.longitude.toString())),
                      zoom: 18,
                    );
                    mapController!
                        .moveCamera(CameraUpdate.newCameraPosition(cPosition));
                  },
                  backgroundColor:  CustomColor.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor:CustomColor.secondaryColor,
                  child: const Icon(Icons.gps_fixed, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "centerMap",
                  mini: true,
                  onPressed: () {
                    setState(() {
                      isFollow = !isFollow;
                    });

                    if (isFollow) {
                      Fluttertoast.showToast(
                        msg: "Seguimiento habilitado", // puedes cambiar a ("Follow enabled").tr()
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: "Seguimiento deshabilitado", // o ("Follow disabled").tr()
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  },
                  backgroundColor: CustomColor.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.secondaryColor,
                  child: const Icon(Icons.center_focus_strong, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "playback",
                  mini: true,
                  onPressed: (){
                    if(_selectedDeviceId == 0){
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("selectAnyDevice").tr()),
                      );
                    }else{
                      showReportDialog(context, ('playback'));
                    }
                  },
                  backgroundColor:  CustomColor.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor:CustomColor.secondaryColor,
                  child: const Icon(Icons.play_circle, size: 25.0),
                ),
                FloatingActionButton(
                  heroTag: "share",
                  mini: true,
                  onPressed: () {
                    if (_selectedDeviceId == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("selectAnyDevice").tr()),
                      );
                    } else {
                      showShareDialog(context, device);
                    }
                  },
                  backgroundColor: CustomColor.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: CustomColor.secondaryColor,
                  child: const Icon(Icons.share, size: 25.0),
                ),
              ],
            ),
          ),
        ),
        Stack(
          children: [
            Positioned(
              left: 5,
              top: 10,
              child: FloatingActionButton(
                heroTag: "openDrawer",
                mini: true,
                onPressed: () {
                  _drawerKey.currentState!.openDrawer();
                  setState(() {});
                },
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: CustomColor.primaryColor,
                foregroundColor: CustomColor.secondaryColor,
                child: const Icon(Icons.menu, size: 25.0),
              ),
            ),
          ],
        )
      ],
    );
  }

  void showShareDialog(BuildContext context, dynamic device) {
    DateTime? endDate;
    bool deleteAfterExpiration = false;

    // Generar nombre aleatorio inicial basado en fecha y hora
    DateTime now = DateTime.now();
    String initialName = "Link" +
        now.day.toString().padLeft(2, '0') +
        now.month.toString().padLeft(2, '0') +
        now.year.toString() +
        now.hour.toString().padLeft(2, '0') +
        now.minute.toString().padLeft(2, '0');

    TextEditingController _shareName = TextEditingController(text: initialName);

    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 500,
            width: 320,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Compartir dispositivo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Nombre del sharing (inicializado con valor aleatorio)
                TextField(
                  controller: _shareName,
                  decoration: const InputDecoration(
                    labelText: "Nombre del enlace",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Fecha de fin
                ListTile(
                  title: Text(
                    endDate == null
                        ? "Selecciona fecha/hora de fin"
                        : "Fin: ${endDate.toString().substring(0, 16)}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        DateTime selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        // Validar que sea superior a la fecha actual
                        if (selectedDateTime.isBefore(DateTime.now())) {
                          Fluttertoast.showToast(
                            msg: "La fecha/hora debe ser futura",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                          return;
                        }

                        setState(() {
                          endDate = selectedDateTime;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Email (opcional)
                TextField(
                  controller: _shareEmail,
                  decoration: const InputDecoration(
                    labelText: "Email (opcional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Checkbox delete_after_expiration
                CheckboxListTile(
                  title: Text("Eliminar enlace al vencer"),
                  value: deleteAfterExpiration,
                  onChanged: (bool? value) {
                    setState(() {
                      deleteAfterExpiration = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        ('cancel').tr(),
                        style: const TextStyle(fontSize: 18.0, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (endDate == null) {
                          Fluttertoast.showToast(
                            msg: "Debes elegir fecha de fin",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.black54,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          return;
                        }
                        if (_shareName.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Debes ingresar un nombre para el enlace",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.black54,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          return;
                        }

                        shareLink(
                          device,
                          name: _shareName.text,
                          email: _shareEmail.text.isEmpty ? null : _shareEmail.text,
                          endDate: endDate!,
                          deleteAfterExpiration: deleteAfterExpiration ? 1 : 0,
                        );
                      },
                      child: Text(
                        ('ok').tr(),
                        style: const TextStyle(fontSize: 18.0, color: Colors.white),
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

    showDialog(context: context, builder: (BuildContext context) => simpleDialog);
  }

  void shareLink(
      dynamic device, {
        String? email,
        required String name,
        required DateTime endDate,
        required int deleteAfterExpiration,
      }) {
    API.generateShare(
      name,
      email,
      device["id"].toString(),
      endDate,
      deleteAfterExpiration,
    ).then((value) {
      print("⬅️ API Response: ${value.body}");

      if (value.statusCode == 200) {
        final responseData = jsonDecode(value.body);
        final hash = responseData["data"]["hash"];
        final link = SERVER_URL+"/sharing/$hash";

        // Popup estilizado
        showDialog(
          context: context,
          builder: (BuildContext context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.blueGrey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enlace generado",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    link,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botones en vertical y extendidos
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.copy),
                        label: Text("Copiar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          Fluttertoast.showToast(
                            msg: "Link copiado al portapapeles",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.black54,
                            textColor: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.open_in_new),
                        label: Text("Abrir"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (await canLaunchUrl(Uri.parse(link))) {
                            await launchUrl(Uri.parse(link),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        child: Text("Cerrar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

      } else {
        Fluttertoast.showToast(
          msg: "Error al generar el enlace",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
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
          arguments: ReportArguments(device["id"], fromDate, fromTime, toDate,
              toTime, device["name"], 0));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments: ReportArguments(device["id"], fromDate, fromTime, toDate,
              toTime, device["name"], 0));
    }
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
