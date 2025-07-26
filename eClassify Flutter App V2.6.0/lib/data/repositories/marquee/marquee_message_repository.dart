import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/utils/api.dart';
import 'package:path/path.dart' as path;

class MarqueeMessageRepository {


  // Marquee Message Methods

  Future<DataOutput<MarqueeMessageModel>> fetchAllMarqueeMessages({
    int? page,
    int? itemId,
    String? country,
    String? state,
    String? city,
    double? latitude,
    double? longitude,
    double? radius,
    int? areaId,
    String? sortBy,
    String? postedSince,
  }) async {
    try {
      Map<String, dynamic> parameters = {
        if (page != null) 'page': page,
        if (itemId != null) 'item_id': itemId,
        if (country != null && country.isNotEmpty) 'country': country,
        if (state != null && state.isNotEmpty) 'state': state,
        if (city != null && city.isNotEmpty) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (areaId != null) 'area_id': areaId,
        if (sortBy != null) 'sort_by': sortBy,
        if (postedSince != null) 'posted_since': postedSince,
      };

      Map<String, dynamic> response = await Api.get(
        url: Api.getAllMarqueeMessagesApi,
        queryParameters: parameters,
      );

      List<MarqueeMessageModel> messageList = (response['data']['data'] as List)
          .map((element) => MarqueeMessageModel.fromJson(element))
          .toList();

      return DataOutput(
        total: response['data']['total'] ?? 0,
        modelList: messageList,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<MarqueeMessageModel> createMarqueeMessage(
      Map<String, dynamic> messageDetails,
      File? image,
      ) async {
    try {
      Map<String, dynamic> parameters = {};
      parameters.addAll(messageDetails);

      if (image != null) {
        MultipartFile imageFile = await MultipartFile.fromFile(
          image.path,
          filename: path.basename(image.path),
        );
        parameters['image'] = imageFile;
      }

      Map<String, dynamic> response = await Api.post(
        url: Api.addMarqueeMessageApi,
        parameter: parameters,
      );

      return MarqueeMessageModel.fromJson(response['data'][0]);
    } catch (e) {
      rethrow;
    }
  }

  Future<MarqueeMessageModel> editMarqueeMessage(
      Map<String, dynamic> messageDetails,
      File? image,
      ) async {
    try {
      Map<String, dynamic> parameters = {};
      parameters.addAll(messageDetails);

      if (image != null) {
        MultipartFile imageFile = await MultipartFile.fromFile(
          image.path,
          filename: path.basename(image.path),
        );
        parameters['image'] = imageFile;
      }

      Map<String, dynamic> response = await Api.post(
        url: Api.updateMarqueeMessageApi,
        parameter: parameters,
      );

      return MarqueeMessageModel.fromJson(response['data'][0]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMarqueeMessage(int id) async {
    await Api.post(
      url: Api.deleteMarqueeMessageApi,
      parameter: {Api.id: id},
    );
  }

  // Not Required as of now
  Future<Map> changeMyMarqueeMessageStatus(
      {required int messageId, required String isActive, int? userId}) async {
    Map response = await Api.post(url: Api.updateMarqueeMessageStatusApi, parameter: {
      'is_active': isActive,
      'id': messageId,
      if (userId != null) Api.soldTo: userId
    });
    return response;
  }



  Future<DataOutput<MarqueeMessageModel>> fetchMyMarqueeMessages({int? page, String? status}) async {
    try {
      Map<String, dynamic> parameters = {Api.page: page};
      if (status != null && status.isNotEmpty) {
        parameters['status'] = status;
      }

      Map<String, dynamic> response = await Api.get(
        url: Api.getMyMarqueeMessagesApi,
        queryParameters: parameters,
      );

      List<MarqueeMessageModel> messageList = (response['data']['data'] as List)
          .map((element) => MarqueeMessageModel.fromJson(element))
          .toList();

      return DataOutput(
        total: response['data']['total'] ?? 0,
        modelList: messageList,
      );
    } catch (e) {
      rethrow;
    }
  }
}