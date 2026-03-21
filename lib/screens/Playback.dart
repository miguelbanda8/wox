import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:gpspro/widgets/CustomProgressIndicatorWidget.dart';

import 'CommonMethod.dart';

class PlaybackPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  MapType _currentMapType = MapType.normal;
  bool _isPlaying = true;
  var _isPlayingIcon = Icons.play_circle_outline;
  bool _trafficEnabled = false;
  Set<Marker> _markers = Set<Marker>();
  double currentZoom = 14.0;
  StreamController<dynamic>? _postsController;
  Timer? _timer;
  Timer? timerPlayBack;
  static ReportArguments? args;
  List<PlayBackRoute> routeList = [];

  String maxSpeed = "-";
  String totalDistance= "-";
  String moveDuration= "-";
  String stopDuration= "-";
  bool? isLoading;
  double pinPillPosition = 0;
  PinInformation currentlySelectedPin = PinInformation(
      pinPath: '',
      avatarPath: '',
      speed: '',
      status: 'loading....',
      location: LatLng(0, 0),
      updatedTime: 'Loading....',
      name: 'Loading....',
      labelColor: Colors.grey);
  int _sliderValue = 0;
  int _sliderValueMax = 0;
  int playbackTime = 200;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  List<Choice> choices = [];
  List<Choice> menuChoices = [];

  Choice? _selectedChoice; // The app's "state".

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice!.title ==
        ('slow').tr()) {
      playbackTime = 600;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice!.title ==
        ('medium').tr()) {
      playbackTime = 400;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice!.title ==
        ('fast').tr()) {
      playbackTime = 100;
      timerPlayBack!.cancel();
      playRoute();
    }
  }

  @override
  initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  Timer interval(Duration duration, func) {
    Timer function() {
      Timer timer = new Timer(duration, function);
      func(timer);
      return timer;
    }

    return new Timer(duration, function);
  }

  void playRoute() async {
    var iconPath = "images/arrow.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 80);
    interval(new Duration(milliseconds: playbackTime), (timer) {
      if (routeList.length != _sliderValue) {
        _sliderValue++;
      }
      timerPlayBack = timer;
      _markers.removeWhere((m) => m.markerId.value == args!.id.toString());
      if (routeList.length == _sliderValue.toInt()) {
        timerPlayBack!.cancel();
      } else if (routeList.length != _sliderValue.toInt()) {
        moveCamera(routeList[_sliderValue.toInt()]);
        if (routeList[_sliderValue.toInt()] != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(
                  routeList[_sliderValue.toInt()].device_id.toString()),
              position: LatLng(
                  double.parse(
                      routeList[_sliderValue.toInt()].latitude.toString()),
                  double.parse(routeList[_sliderValue.toInt()]
                      .longitude
                      .toString())), // updated position
              rotation: double.parse(routeList[_sliderValue.toInt()].course!),
              icon: BitmapDescriptor.fromBytes(icon!),
            ),
          );
        }
        setState(() {});
      } else {
        timerPlayBack!.cancel();
      }
    });
  }

  void playUsingSlider(int pos) async {
    var iconPath = "images/arrow.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 100);
    _markers.removeWhere((m) => m.markerId.value == args!.id.toString());
    if (routeList.length != pos) {
      moveCamera(routeList[pos]);
     _markers.add(
        Marker(
          markerId:
          MarkerId(routeList[pos].device_id.toString()),
          position: LatLng(
              double.parse(routeList[pos].latitude.toString()),
              double.parse(routeList[pos]
                  .longitude
                  .toString())), // updated position
          rotation: double.parse(routeList[pos].course!),
          icon: BitmapDescriptor.fromBytes(icon!),
        ),
      );
      setState(() {});
    }
  }

  void moveCamera(PlayBackRoute pos) async {
    CameraPosition cPosition = CameraPosition(
      target: LatLng(double.parse(pos.latitude.toString()),
          double.parse(pos.longitude.toString())),
      zoom: currentZoom,
    );

    if (isLoading!) {
      _showProgress(false);
      timerPlayBack!.cancel();
    }
    isLoading = false;
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));
  }

  getReport() {
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (args != null) {
        _timer!.cancel();
        API.getHistory(args!.id.toString(), args!.fromDate, args!.fromTime,
            args!.toDate, args!.toTime)
            .then((value) => {
          totalDistance = value!.distance_sum!,
          maxSpeed= value.top_speed!,
          moveDuration=  value.move_duration!,
          stopDuration =   value.stop_duration!,

          if (value.items!.length != 0)
            {
              value.items!.forEach((element) {
                _postsController!.add(element);
                element['items'].forEach((element) {
                  if (element['latitude'] != null) {
                    PlayBackRoute blackRoute = PlayBackRoute();
                    blackRoute.device_id =
                        element['device_id'].toString();
                    blackRoute.longitude =
                        element['longitude'].toString();
                    blackRoute.latitude =
                        element['latitude'].toString();
                    blackRoute.speed = element['speed'];
                    blackRoute.course = element['course'].toString();
                    blackRoute.raw_time =
                        element['raw_time'].toString();
                    blackRoute.speedType  = "kph";

                    polylineCoordinates.add(LatLng(
                        double.parse(element['latitude'].toString()),
                        double.parse(element['longitude'].toString())));
                    routeList.add(blackRoute);
                  }
                });
                _sliderValueMax = polylineCoordinates.length;
              }),
              playRoute(),
              setState(() {}),
              drawPolyline(),
            }
          else
            {
              if (isLoading!)
                {
                  _showProgress(false),
                  isLoading = false,
                },
              _timer!.cancel(),
              AlertDialogCustom().showAlertDialog(
                  context,
                  ('noData').tr(),
                  ('failed').tr(),
                  ('ok').tr())
            }
        });
      }
    });
  }

  void drawPolyline() async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 6,
        polylineId: id,
        color: Colors.greenAccent,
        points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _playPausePressed() {
    setState(() {
      _isPlaying = _isPlaying == false ? true : false;
      if (_isPlaying) {
        timerPlayBack!.cancel();
      } else {
        playRoute();
      }
      _isPlayingIcon = _isPlaying == false
          ? Icons.pause_circle_outline
          : Icons.play_circle_outline;
    });
  }

  currentMapStatus(CameraPosition position) {
    currentZoom = position.zoom;
  }

  void _selectedReport(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice!.title ==
        ('tripAndSummary').tr()) {
      Navigator.pushNamed(context, "/reportTripView",
          arguments: ReportArguments(args!.id, args!.fromDate,
              args!.fromTime, args!.toDate, args!.toTime, args!.name, 7));
    } else if (_selectedChoice!.title ==
        ('stopReport').tr()) {
      Navigator.pushNamed(context, "/reportStopView",
          arguments: ReportArguments(args!.id, args!.fromDate,
              args!.fromTime, args!.toDate, args!.toTime, args!.name, 7));
    }
  }


  @override
  void dispose() {
    if (timerPlayBack != null) {
      if (timerPlayBack!.isActive) {
        timerPlayBack!.cancel();
      }
    }
    super.dispose();
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    choices = <Choice>[
      Choice(
          title: ('slow').tr(),
          icon: Icons.directions_car),
      Choice(
          title: ('medium').tr(),
          icon: Icons.directions_bike),
      Choice(
          title: ('fast').tr(),
          icon: Icons.directions_boat),
    ];
    menuChoices = <Choice>[
      Choice(
          title: ('tripAndSummary').tr(),
          icon: Icons.directions_car
      ),
      Choice(
          title: ('stopReport').tr(),
          icon: Icons.directions_car
      ),
    ];
    _selectedChoice = choices[0];
    _selectedChoice = choices[0];
    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: _selectedReport,
            icon: Icon(Icons.more_vert,),
            itemBuilder: (BuildContext context) {
              return menuChoices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title!),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          onCameraMove: currentMapStatus,
          trafficEnabled: _trafficEnabled,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
            CustomProgressIndicatorWidget().showProgressDialog(context,
                ('sharedLoading').tr());
            isLoading = true;
          },
          markers: _markers,
          polylines: Set<Polyline>.of(polylines.values),
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
              ],
            ),
          ),
        ),
        playBackControls(),
      ]),
    );
  }

  Widget playBackControls() {
    String fUpdateTime =
    ('sharedLoading').tr();
    String speed = ('sharedLoading').tr();
    if (routeList.length > _sliderValue.toInt()) {
      fUpdateTime = formatTime(routeList[_sliderValue.toInt()].raw_time!);
      speed = convertSpeed(routeList[_sliderValue.toInt()].speed, routeList[_sliderValue.toInt()].speedType!);
    }

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(10),
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
                          padding: EdgeInsets.only(top: 5.0, left: 10.0),
                          child: InkWell(
                            child: Icon(_isPlayingIcon,
                                color: CustomColor.primaryColor, size: 40.0),
                            onTap: () {
                              _playPausePressed();
                            },
                          )),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          padding: EdgeInsets.only(top: 3.0),
                          child: Slider(
                            value: _sliderValue.toDouble(),
                            onChanged: (newSliderValue) {
                              setState(
                                      () => _sliderValue = newSliderValue.toInt());
                              if (timerPlayBack != null) {
                                if (!timerPlayBack!.isActive) {
                                  playUsingSlider(newSliderValue.toInt());
                                }
                              }
                            },
                            min: 0,
                            max: _sliderValueMax.toDouble(),
                          )),
                    ],
                  )),
              new Container(
                margin: EdgeInsets.fromLTRB(5, 0, 0, 5),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Icon(Icons.av_timer,
                          color: CustomColor.primaryColor, size: 20.0),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 3.0),
                      child: Text(('deviceLastUpdate').tr() +
                          ": " +
                          fUpdateTime, style: TextStyle(fontSize: 10),),
                    ),
                    PopupMenuButton<Choice>(
                      onSelected: _select,
                      color: CustomColor.primaryColor,
                      icon: Icon(Icons.timer, color: CustomColor.primaryColor, size: 27,),
                      itemBuilder: (BuildContext context) {
                        return choices.map((Choice choice) {
                          return PopupMenuItem<Choice>(
                            value: choice,
                            child: Text(choice.title!),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    new Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Image.asset("assets/images/speedometer.png", width: 30,),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text(maxSpeed, style: TextStyle(fontSize: 10),),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text("Maximum speed", style: TextStyle(fontSize: 8),),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    new Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Icon(Icons.timeline,
                                color: CustomColor.primaryColor, size: 30.0),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text(totalDistance, style: TextStyle(fontSize: 10),),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text("Distance", style: TextStyle(fontSize: 8),),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Container(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      new Container(
                        margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Image.asset("assets/images/engine.png", width: 30,),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(moveDuration, style: TextStyle(fontSize: 10),),
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text("Driving", style: TextStyle(fontSize: 8),),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      new Container(
                        margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Image.asset("assets/images/steering.png", width: 30,),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(stopDuration, style: TextStyle(fontSize: 10),),
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text("Idle", style: TextStyle(fontSize: 8),),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  )
              )
              // new Container(
              //   margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
              //   child: Row(
              //     children: <Widget>[
              //       Container(
              //         padding: EdgeInsets.only(left: 5.0),
              //         child: Icon(Icons.radio_button_checked,
              //             color: CustomColor.primaryColor, size: 20.0),
              //       ),
              //       Container(
              //         padding: EdgeInsets.only(left: 5.0),
              //         child: Text(AppLocalizations.of(context)
              //                 .translate('positionSpeed') +
              //             ": " +
              //             speed),
              //       ),
              //     ],
              //   ),
              // ),
              // new Container(
              //   margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
              //   child: Row(
              //     children: <Widget>[
              //       Container(
              //         padding: EdgeInsets.only(left: 5.0),
              //         child: Icon(Icons.av_timer,
              //             color: CustomColor.primaryColor, size: 20.0),
              //       ),
              //       Container(
              //         padding: EdgeInsets.only(left: 5.0),
              //         child: Text(AppLocalizations.of(context)
              //                 .translate('deviceLastUpdate') +
              //             ": " +
              //             fUpdateTime),
              //       ),
              //     ],
              //   ),
              // ),
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
