import 'package:eClassify/data/model/item/item_model.dart';

class MarqueeMessageModel {
  int? id;
  int? userId;
  int? itemId;
  String? message;
  bool? isActive;
  int? displayOrder;
  DateTime? startDate;
  DateTime? endDate;
  String? country;
  String? state;
  String? city;
  int? areaId;
  double? latitude;
  double? longitude;
  double? radius;
  String? image;
  ItemModel? item;
  DateTime? createdAt;
  DateTime? updatedAt;

  MarqueeMessageModel({
    this.id,
    this.userId,
    this.itemId,
    this.message,
    this.isActive,
    this.displayOrder,
    this.startDate,
    this.endDate,
    this.country,
    this.state,
    this.city,
    this.areaId,
    this.latitude,
    this.longitude,
    this.radius,
    this.image,
    this.item,
    this.createdAt,
    this.updatedAt,
  });

  MarqueeMessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    userId = json['user_id'] as int?;
    itemId = json['item_id'] as int?;
    message = json['message'] as String?;
    isActive = json['is_active'] == 1 || json['is_active'] == true;
    displayOrder = json['display_order'] as int?;
    startDate = json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null;
    endDate = json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null;
    country = json['country'] as String?;
    state = json['state'] as String?;
    city = json['city'] as String?;
    areaId = json['area'] is Map ? json['area']['id'] as int? : json['area_id'] as int?;
    latitude = json['latitude'] != null
        ? (json['latitude'] is int ? (json['latitude'] as int).toDouble() : json['latitude'] as double?)
        : null;
    longitude = json['longitude'] != null
        ? (json['longitude'] is int ? (json['longitude'] as int).toDouble() : json['longitude'] as double?)
        : null;
    radius = json['radius'] != null
        ? (json['radius'] is int ? (json['radius'] as int).toDouble() : json['radius'] as double?)
        : null;
    image = json['image'] as String?;
    item = json['item'] != null ? ItemModel.fromJson(json['item'] as Map<String, dynamic>) : null;
    createdAt = json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null;
    updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['item_id'] = itemId;
    data['message'] = message;
    data['is_active'] = isActive == true ? 1 : 0;
    data['display_order'] = displayOrder;
    data['start_date'] = startDate?.toIso8601String();
    data['end_date'] = endDate?.toIso8601String();
    data['country'] = country;
    data['state'] = state;
    data['city'] = city;
    data['area_id'] = areaId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['radius'] = radius;
    data['image'] = image;
    data['item'] = item?.toJson();
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt?.toIso8601String();
    return data;
  }
}