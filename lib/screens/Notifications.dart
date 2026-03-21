import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gpspro/model/Event.dart';
import 'package:gpspro/model/NotificationType.dart';
import 'package:gpspro/screens/RecentEvents.dart';
import 'package:gpspro/store/device.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:provider/provider.dart';

class NotificationTypePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _NotificationTypeState();
}

class _NotificationTypeState extends State<NotificationTypePage> {
  StreamController<int>? _postsController;
  bool isLoading = true;
  late DeviceStore eventStore;

  @override
  void initState() {
    _postsController = new StreamController();
    getNotificationList();
    super.initState();
  }

  void getNotificationList() {
    setState(() {
      eventStore = Provider.of<DeviceStore>(context);
    });
    // APIService.getNotificationTypes().then((value) => {
    //       notificationTypeList.addAll(value),
    //       value.forEach((element) {
    //         _postsController.add(element);
    //       })
    //     });
    // notificationTypeList.sort((a, b) {
    //   return a.type.toLowerCase().compareTo(b.type.toLowerCase());
    // });
  }

  @override
  Widget build(BuildContext context) {
    eventStore = Provider.of<DeviceStore>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(('notification'),
              style: TextStyle(color: CustomColor.secondaryColor)),
        ),
        body:  loadNotificationType());
  }

  Widget loadNotificationType() {
    return StreamBuilder<int>(
        stream: _postsController!.stream,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasData) {
            return loadNotifyTypes();
          } else if (isLoading) {
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

  Widget loadNotifyTypes() {
    if (!eventStore.isEventLoading) {
      if (eventStore.events.isNotEmpty){
        return ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: eventStore.events.length,
            itemBuilder: (context, index) {
              final eventItem = eventStore.events[index];
              return  InkWell(
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

                              // Container(
                              //     width: MediaQuery.of(context).size.width *
                              //         0.60,
                              //     child: new Text(eventItem.message,
                              //         style: TextStyle(fontSize: 10))),
                            ],
                          ),
                          subtitle: new Text(eventItem.message!,
                              style: TextStyle(fontSize: 12.0)),
                        )
                      ],
                    ),
                  )
              );
            });
      }else{
        return Center(
          child: Text(('noData')),
        );
      }
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
