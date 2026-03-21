class SingleDevice extends Object {
  dynamic? device_id;
  Map<String, dynamic>? engine_hours;
  Map<String, dynamic>? detect_engine;
  Map<String, dynamic>? device_groups;
  Map<String, dynamic>? sensor_groups;
  Map<String, dynamic>? item;
  Map<String, dynamic>? device_fuel_measurements;
  Map<String, dynamic>? device_icons;
  Map<String, dynamic>? sensors;
  Map<String, dynamic>? services;
  Map<String, dynamic>? expiration_date_select;
  List<dynamic>? timezones;
  List<dynamic>? users;

  SingleDevice({this.device_id, this.item});

  SingleDevice.fromJson(Map<String, dynamic> json) {
    device_id = json["id"];
    item = json["item"];
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
