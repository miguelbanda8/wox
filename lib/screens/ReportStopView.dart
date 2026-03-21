import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/arguments/StopArguments.dart';
import 'package:gpspro/model/PlayBackRoute.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';


class ReportStopViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportStopViewPageState();
}

class _ReportStopViewPageState extends State<ReportStopViewPage> {
  ReportArguments? args;
  StreamController<int>? _postsController;
  Timer? _timer;
  bool isLoading = true;

  List<PlayBackRoute> routeList = [];

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }


  getReport() {
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (args != null) {
        _timer!.cancel();
        API.getHistory(args!.id.toString(), args!.fromDate, args!.fromTime,
            args!.toDate, args!.toTime)
            .then((value) => {

          value!.items!.forEach((el) {
            print(el['time']);
            if(el['time'] != null && el['engine_work'] == 0) {
              PlayBackRoute rt = PlayBackRoute();
              rt.time = el['time'];
              rt.show = el['show'];
              rt.left = el['left'];
              rt.distance = el['distance'];
              rt.engine_hours = el['engine_hours'];
              rt.fuel_consumption = el['fuel_consumption'];
              rt.top_speed = el['top_speed'];
              rt.average_speed = el['average_speed'];

              var element = el['items'].first;
                if (element['latitude'] != null) {
                  rt.device_id =
                      element['device_id'].toString();
                  rt.longitude =
                      element['longitude'].toString();
                  rt.latitude =
                      element['latitude'].toString();
                  rt.speed = element['speed'];
                  rt.course = element['course'].toString();
                  rt.raw_time =
                      element['raw_time'].toString();
                  rt.speedType = "kph";
                }
              routeList.add(rt);
            }
          }),

          _postsController!.add(1),
          setState(() {

          })
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)?.settings.arguments as ReportArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: StreamBuilder<int>(
          stream: _postsController!.stream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  Padding(padding: EdgeInsets.only(top: 5), child: loadReport(),),
                ],
              );
            } else if (isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: Text(('noData').tr()),
              );
            }
          }),
    );
  }

  Widget loadReport() {
    return ListView.builder(
      itemCount: routeList.length,
      itemBuilder: (context, index) {
        final trip = routeList[index];
        return GestureDetector(
          onTap: (){
            Navigator.pushNamed(context, "/stopMap",
                arguments: StopArguments(int.parse(trip.device_id!), args!.name, trip));
          },
          child: reportRow(trip),
        );
      },
    );
  }

  Widget reportRow(PlayBackRoute t) {
    return Card(
        child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        ("reportStartTime").tr(),
                        style: TextStyle(color: Colors.green)),
                    Text(("reportEndTime").tr(),
                        style: TextStyle(color: Colors.red))
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        child: Text(
                          t.show!,
                          style: TextStyle(fontSize: 11),
                        )),
                    Expanded(
                        child: Text(
                          t.left!,
                          style: TextStyle(fontSize: 11),
                        )),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        child: Text(("reportDuration").tr() +
                              ": " +
                              t.time!,
                          style: TextStyle(fontSize: 11),
                        )),
                    Expanded(
                        child: Text(("reportSpentFuel").tr() +
                              ": " +
                              t.fuel_consumption.toString(),
                          style: TextStyle(fontSize: 11),
                        )),
                  ],
                ),
              ],
            )));
  }

}
