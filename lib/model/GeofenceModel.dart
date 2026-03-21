import 'dart:convert';

class Geofence {
  int? id;
  int? userId;
  int? groupId;
  int? active;
  String? name;
  List<dynamic>? coordinates; // Ahora es lista
  String? polygonColor;
  String? createdAt;
  String? updatedAt;
  String? type;
  double? radius;
  Map<String, dynamic>? center; // Ahora es Map

  Geofence({
    this.id,
    this.userId,
    this.groupId,
    this.active,
    this.name,
    this.coordinates,
    this.polygonColor,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.radius,
    this.center,
  });

  Geofence.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    userId = json["user_id"];
    groupId = json["group_id"];
    active = json["active"];
    name = json["name"];

    // 👇 parsear coordinates porque viene como string con JSON dentro
    if (json["coordinates"] != null) {
      coordinates = jsonDecode(json["coordinates"]);
    }

    polygonColor = json["polygon_color"];
    createdAt = json["created_at"];
    updatedAt = json["updated_at"];
    type = json["type"];

    if (json["radius"] != null) {
      radius = (json["radius"] as num).toDouble();
    }

    // 👇 center puede venir null o como objeto
    if (json["center"] != null) {
      center = Map<String, dynamic>.from(json["center"]);
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "group_id": groupId,
    "active": active,
    "name": name,
    "coordinates": coordinates,
    "polygon_color": polygonColor,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "type": type,
    "radius": radius,
    "center": center,
  };
}
