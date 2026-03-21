import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class Util{

 static String convertSpeed(var speed, String type) {
   return "${speed.toInt()} $type";
 }

  static String formatTime(String time) {
    DateTime lastUpdate = DateTime.parse(time);
    return DateFormat('dd-MM-yyyy hh:mm:ss').format(lastUpdate.toLocal());
  }

 static String formatOnlyTime(String date) {
   DateFormat inputFormat = DateFormat("MM-dd-yyyy HH:mm:ss");
   DateTime lastUpdate = inputFormat.parse(date);
   return DateFormat('HH:mm').format(lastUpdate.toLocal());
 }

 static String historyTabTime(String time) {
   DateTime lastUpdate = DateTime.parse(time);
   return DateFormat('dd-MMM').format(lastUpdate.toLocal());
 }

 static String formatInvalidDate(String date) {
   DateFormat inputFormat = DateFormat("dd-MM-yyyy HH:mm:ss");
   DateTime lastUpdate = inputFormat.parse(date);
   return DateFormat('yyyy-MM-dd').format(lastUpdate.toLocal());
 }

 static String formatInvalidTime(String date) {
   DateFormat inputFormat = DateFormat("MM-dd-yyyy HH:mm:ss");
   DateTime lastUpdate = inputFormat.parse(date);
   return DateFormat('HH:mm:ss').format(lastUpdate.toLocal());
 }

 static String convertDistance(double distance) {
   double calcDistance = distance / 1000;
   return "${calcDistance.toStringAsFixed(2)} Km";
 }


 static String convertDistancePlain(double distance) {
   double calcDistance = distance / 1000;
   return calcDistance.toStringAsFixed(2);
 }

  static String convertDuration(int duration) {
    double hours = duration / 3600000;
    double minutes = duration % 3600000 / 60000;
    return "${hours.toInt()} hr ${minutes.toInt()} min";
  }

 static String convertDurationPlain(int duration) {
   double hours = duration / 3600000;
   double minutes = duration % 3600000 / 60000;
   return hours.toInt().toString();
 }


 static Future<Uint8List?> getBytesFromAsset(String path, int width) async {
   if (path.isNotEmpty) {
     ByteData data = await rootBundle.load(path);
     ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
         targetWidth: width);
     ui.FrameInfo fi = await codec.getNextFrame();
     return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
         .buffer
         .asUint8List();
   } else {
     return null;
   }
 }

 static Future<BitmapDescriptor> getBitmapDescriptorFromAssetBytes(String path, int width) async {
   final Uint8List? imageData = await getBytesFromAsset(path, width);
   return BitmapDescriptor.fromBytes(imageData!);
 }

static Future<BitmapDescriptor> getBitmapDescriptorFromBytes(
     var path, int width, context) async {
   final Uint8List? image = await getBytesFromBytes(path, width);
   var decodedImage = await decodeImageFromList(image!);
   if(decodedImage.clone().height < 70){
     double devicePixelRatio =  MediaQuery.of(context).size.width / 2.5;
     Uint8List? imageData = await getBytesFromBytes(path, devicePixelRatio.toInt());
     return BitmapDescriptor.fromBytes(imageData!);
   }else{
     Uint8List? imageData = await getBytesFromBytes(path, width);
     return BitmapDescriptor.fromBytes(imageData!);
   }
 }

 static Future<Uint8List?> getBytesFromBytes(var data, int width) async {
   if (data != null) {
     ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
         targetWidth: width);
     ui.FrameInfo fi = await codec.getNextFrame();
     return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
     !.buffer
         .asUint8List();
   } else {
     return null;
   }
 }

static String formatReportDate(DateTime date) {
   return DateFormat('dd-MM-yyyy').format(date.toLocal());
 }

static String formatReportTime(TimeOfDay timeOfDay) {
   return "${timeOfDay.hour}:${timeOfDay.minute}";
 }

 static String formatDateReport(String date) {
   DateTime lastUpdate = DateTime.parse(date);
   String month, day;
   if (lastUpdate.month < 10) {
     month = "0" + lastUpdate.month.toString();
   } else {
     month = lastUpdate.month.toString();
   }

   if (lastUpdate.day < 10) {
     day = "0" + lastUpdate.day.toString();
   } else {
     day = lastUpdate.day.toString();
   }

   return lastUpdate.year.toString()+"-"+month+"-"+day;
 }

static String formatTimeReport(String date) {
   DateTime lastUpdate = DateTime.parse(date);
   String hour, minute;
   if (lastUpdate.month < 10) {
     hour = "0" + lastUpdate.month.toString();
   } else {
     minute = lastUpdate.month.toString();
   }

   if (lastUpdate.hour < 10) {
     hour = "0" + lastUpdate.hour.toString();
   } else {
     hour = lastUpdate.hour.toString();
   }

   if (lastUpdate.minute < 10) {
     minute = "0" + lastUpdate.minute.toString();
   } else {
     minute = lastUpdate.minute.toString();
   }
   return hour+":"+minute+":00";
 }

 static LatLngBounds boundsFromLatLngList(Set<Marker> list) {
   assert(list.isNotEmpty);
   double? x0, x1, y0, y1;
   list.forEach((value) {
     if (x0 == null) {
       x0 = x1 = value.position.latitude;
       y0 = y1 = value.position.longitude;
     } else {
       if (value.position.latitude > x1!) x1 = value.position.latitude;
       if (value.position.latitude < x0!) x0 = value.position.latitude;
       if (value.position.longitude > y1!) y1 = value.position.longitude;
       if (value.position.longitude < y0!) y0 = value.position.longitude;
     }
   });
   return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
 }

 static String getAddress(lat, lng) {
   String address = ('loading').tr();
   if (lat != null) {
     API.getGeocoder(lat, lng).then((value) => {
       if (value != null)
         {
           address = value,
         }
       else
         {
           address = ('addressNoFound').tr()
         }
     });
   } else {
     address = ('addressNoFound').tr();
   }

   return address;
 }
}