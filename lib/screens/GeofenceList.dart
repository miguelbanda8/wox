import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/model/GeofenceModel.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GeofenceListPageState();
}

class _GeofenceListPageState extends State<GeofenceListPage> {
  static ReportArguments? args;
  bool isLoading = false;
  List<Geofence> fenceList = [];
  SharedPreferences? prefs;
  User? user;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    prefs = await SharedPreferences.getInstance();
    String? userJson = prefs!.getString("user");
    if (userJson != null) {
      user = User.fromJson(json.decode(userJson));
    }
    await getFences();
    setState(() {});
  }

  Future<void> getFences() async {
    setState(() => isLoading = true);
    if (args != null) {
      final response = await API.getGeoFences();
      fenceList = response ?? [];
    }
    setState(() => isLoading = false);
  }

  void deleteFence(int id) async {
    setState(() => isLoading = true);
    try {
      final response = await API.destroyGeofence(id);
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        fenceList.removeWhere((f) => f.id == id);
        Fluttertoast.showToast(
          msg: "fenceDeleted",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        String message = body["message"] ?? "Error desconocido";
        Fluttertoast.showToast(
          msg: message,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(
        msg: "Error de conexión: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void deleteFenceConfirm(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Fence').tr(),
        content: Text('Are you sure?').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No').tr(),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteFence(id);
            },
            child: Text('Yes').tr(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    args ??= ModalRoute.of(context)?.settings.arguments as ReportArguments?;

    return Scaffold(
      appBar: AppBar(
        title: Text(args?.name ?? '', style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(color: CustomColor.secondaryColor),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: getFences),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              if (args != null) {
                Navigator.pushNamed(
                  context,
                  "/geofenceAdd",
                  arguments: FenceArguments(
                    fenceModel: Geofence(),
                    deviceId: args!.id,
                    name: args!.name,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: getFences,
            child: fenceList.isEmpty
                ? ListView(
              children: [
                SizedBox(height: 50),
                Center(child: Text('No fences found').tr()),
              ],
            )
                : ListView.builder(
              itemCount: fenceList.length,
              itemBuilder: (context, index) {
                final fence = fenceList[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      fence.name ?? 'Unnamed Fence',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      "ID: ${fence.id}", // Solo mostramos ID porque no hay lat/lng
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteFenceConfirm(fence.id!),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        "/geofence",
                        arguments: FenceArguments(
                          fenceModel: fence,
                          deviceId: args!.id,
                          name: args!.name,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class FenceArguments {
  Geofence? fenceModel;
  int? deviceId;
  String? name;

  FenceArguments({this.fenceModel, this.deviceId, this.name});
}
