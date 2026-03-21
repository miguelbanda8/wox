import 'dart:ui';

import 'package:flutter/material.dart';

class Device extends Object {
  dynamic? id;
  String? title;
  List<dynamic>? items;

  Device({this.id, this.title, this.items});

  Device.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    title = json["title"];
    items = json["items"];
  }
}

class DeviceItem extends Object {
  int? id;
  int? alarm;
  String? name;
  String? online;
  String? time;
  int? timestamp;
  int? acktimestamp;
  double? lat;
  double? lng;
  double? course;
  double? speed;
  double? altitude;
  String? icon_type;
  String? icon_color;
  Map<String, dynamic>? icon_colors;
  Map<String, dynamic>? icon;
  String? power;
  String? address;
  String? protocol;
  String? driver;
  Map<String, dynamic>? driver_data;
  List<dynamic>? sensors;
  List<dynamic>? services;
  List<dynamic>? tail;

  DeviceItem(
      {this.id,
      this.alarm,
      this.name,
      this.online,
      this.time,
      this.timestamp,
      this.acktimestamp,
      this.lat,
      this.lng,
      this.course,
      this.speed,
      this.altitude,
      this.icon_type,
      this.icon_color,
      this.icon,
      this.power,
      this.address,
      this.protocol,
      this.driver,
      this.driver_data,
      this.sensors,
      this.services,
      this.tail});
}

Color parseColor(String colorName) {
  switch (colorName.toLowerCase()) {
    case "red":
      return Color(0xFFFF0000); // rojo puro
    case "blue":
      return Color(0xFF0000FF); // azul puro
    case "green":
      return Color(0xFF047904); // verde puro
    case "yellow":
      return Color(0xFFFFCC00); // amarillo puro
    case "orange":
      return Color(0xFFFFA500); // naranja
    case "black":
      return Color(0xFF000000); // negro
    default:
      return Color(0xFF808080); // fallback
  }
}

