import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/screens/RecentEvents.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/util/Util.dart';

import 'CommonMethod.dart';

class NotificationMapPage extends StatefulWidget {
  @override
  _NotificationMapPageState createState() => _NotificationMapPageState();
}

class _NotificationMapPageState extends State<NotificationMapPage> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  StreamController<int>? _postsController;
  MapType _currentMapType = MapType.normal;
  static ReportEventArgument? args;
  Set<Marker> _markers = Set<Marker>();
  Timer? _timer;
  // PositionModel position;
  Event? event;

  @override
  void initState() {
    _postsController = new StreamController();
    getPosition();
    super.initState();
  }

  void getPosition() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        _timer!.cancel();
        event = args!.event;
        addMarkers(args!.event);
      }
      ;
      // APIService.getEventById(args.eventId.toString()).then((event) => {
      //       APIService.getPositionById(
      //               event.deviceId.toString(), event.positionId.toString())
      //           .then((value) => {addMarkers(value.single, event)})
      //     });
    });
  }

  void addMarkers(Event e) async {
    _postsController!.add(1);
    CameraPosition cPosition = CameraPosition(
      target: LatLng(double.parse(e.latitude.toString()), double.parse(e.longitude.toString())),
      zoom: 16,
    );
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));
    var iconPath;
    // if (event.type == "alarm") {
    iconPath = "images/alarm_event.png";
    // } else {
    //   iconPath = "images/normal_event.png";
    // }
    final Uint8List? markerIcon = await getBytesFromAsset(iconPath, 70);
    _markers = Set<Marker>();
    _markers.add(Marker(
      markerId: MarkerId(event!.id.toString()),
      position:  LatLng(double.parse(e.latitude.toString()), double.parse(e.longitude.toString())),
      icon: BitmapDescriptor.fromBytes(markerIcon!),
    ));
    setState(() {});
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 0,
  );

  String address = ("showAddress").tr();

  @override
  void dispose() {
    if (_timer!.isActive) {
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportEventArgument;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(args!.event.device_name!,
                  style: TextStyle(color: CustomColor.secondaryColor)),
              iconTheme: IconThemeData(
                color: CustomColor.secondaryColor, //change your color here
              ),
            ),
            body: streamLoad()));
  }

  Widget streamLoad() {
    return StreamBuilder<int>(
        stream: _postsController!.stream,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasData) {
            return loadMap();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Center(
              child: Text(('noData')),
            );
          }
        });
  }

  Widget loadMap() {
    return Stack(
      children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
          },
          markers: _markers,
          onTap: (LatLng latLng) {},
        ),
        bottomWindow()
      ],
    );
  }

  Widget bottomWindow() {
    String result;

    return Positioned(
        bottom: 0,
        right: 0,
        left: 0,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                //margin: EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(10, 0, 10, 30),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          blurRadius: 20,
                          offset: Offset.zero,
                          color: Colors.grey.withOpacity(0.5))
                    ]),
                child: Column(
                  children: <Widget>[
                    // position.address != null
                    //     ? Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //         children: <Widget>[
                    //           Container(
                    //             padding: EdgeInsets.only(left: 5.0),
                    //             child: Icon(Icons.location_on_outlined,
                    //                 color: CustomColor.primaryColor,
                    //                 size: 20.0),
                    //           ),
                    //           Expanded(
                    //             child: Column(children: [
                    //               Padding(
                    //                   padding: EdgeInsets.only(
                    //                       top: 10.0, left: 5.0, right: 0),
                    //                   child: Text(
                    //                     utf8.decode(
                    //                         utf8.encode(position.address)),
                    //                     maxLines: 2,
                    //                     overflow: TextOverflow.ellipsis,
                    //                   )),
                    //             ]),
                    //           )
                    //         ],
                    //       )
                    //     : new Container(),

                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 3.0),
                                  child: Icon(Icons.event_note,
                                      color: CustomColor.primaryColor,
                                      size: 20.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(event!.message!)),
                      ],
                    ),
                    GestureDetector(
                        onTap: () {
                          address = "Loading....";
                          setState(() {});
                          Util.getAddress(args!.event.latitude, args!.event.longitude);
                        },
                        child: new Row(children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Icon(Icons.location_on_outlined,
                                  color: CustomColor.primaryColor, size: 22.0)),
                          Padding(padding: new EdgeInsets.fromLTRB(5, 0, 0, 0)),
                          Expanded(
                              child: Text(address,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.blue),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis))
                        ])),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: <Widget>[
                    //     Container(
                    //       padding: EdgeInsets.only(left: 5.0),
                    //       child: Icon(Icons.comment,
                    //           color: CustomColor.primaryColor, size: 25.0),
                    //     ),
                    //     Expanded(
                    //       child: Column(children: [
                    //         Padding(
                    //             padding: EdgeInsets.only(
                    //                 top: 10.0, left: 5.0, right: 0),
                    //             child: Text(
                    //               result,
                    //               maxLines: 7,
                    //               overflow: TextOverflow.ellipsis,
                    //             )),
                    //       ]),
                    //     )
                    //   ],
                    // ),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 3.0),
                                  child: Icon(Icons.speed,
                                      color: CustomColor.primaryColor,
                                      size: 20.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(event!.speed.toString() + " mph")),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Icon(Icons.access_time_outlined,
                                      color: CustomColor.primaryColor,
                                      size: 15.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: 5.0, left: 5.0, right: 10.0),
                            child: Text(
                              event!.time!,
                              style: TextStyle(fontSize: 11),
                            )),
                      ],
                    ),
                  ],
                ))));
  }
}
