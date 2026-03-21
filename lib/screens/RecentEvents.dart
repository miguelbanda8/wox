import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:jiffy/jiffy.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentEventsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => new _RecentEventsPageState();
}

class _RecentEventsPageState extends State<RecentEventsPage> {
  User? user;
  SharedPreferences? prefs;
  List<Event> eventList = [];
  Map<int, dynamic> devices = new HashMap();
  var deviceId = [];
  bool isLoading = true;
  bool isEventLoading = true;
  Locale? myLocale;
  late DeviceStore deviceStore;

  int online = 0, offline = 0, unknown = 0;

  @override
  initState() {
    super.initState();
  }

  void setLocale(locale) async {
    await Jiffy.locale(locale);
  }

  @override
  Widget build(BuildContext context) {
    myLocale = Localizations.localeOf(context);
    deviceStore = Provider.of<DeviceStore>(context);

    setLocale(myLocale!.languageCode);

    return Scaffold(
              appBar: AppBar(
                title: Text(
                    ('recentEvents').tr(),
                    style: TextStyle(color: CustomColor.secondaryColor)),
              ),
              body: Scaffold(
                body: Column(
                  children: <Widget>[Expanded(child: loadEvents())],
                ),
              ),
            );
  }

  Widget loadEvents() {
    if (deviceStore.events.isNotEmpty) {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: deviceStore.events.length,
          itemBuilder: (context, index) {
            final eventItem = deviceStore.events[index];
            return new InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/notificationMap",
                      arguments: ReportEventArgument(eventItem));
                },
                child: Card(
                  elevation: 3.0,
                  child: Column(
                    children: <Widget>[
                      new ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Expanded(
                                child: Text(eventItem.device_name!,
                                    style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold),
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)),
                            Icon(Icons.notifications, color: Colors.grey,),
                            Padding(padding: EdgeInsets.fromLTRB(0, 0, 30, 0)),
                            Container(
                              width: 70,
                              child:   new Text(
                                  eventItem.time != null ? eventItem.time! : "",
                                  style: TextStyle(fontSize: 12.0, color: CustomColor.primaryColor)),
                            )
                          ],
                        ),
                        subtitle: new Text(eventItem.message!,
                            style: TextStyle(fontSize: 12.0)),
                      )
                    ],
                  ),
                ));
          });
    } else {
      return new Container(child: Center(child: Text(('noEvents').tr()),),);
    }
  }

  Widget chart() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            online.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            ("online"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.green,
        ),
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            unknown.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            ("unknown"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.yellow,
        ),
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            offline.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            ("offline"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.red,
        ),
      ],
    );
  }
}

class Task {
  String task;
  int taskvalue;
  Color colorval;

  Task(this.task, this.taskvalue, this.colorval);
}

class ReportEventArgument {
  final Event event;
  ReportEventArgument(this.event);
}

