import 'dart:io';
import 'package:eClassify/data/repositories/marquee/marquee_message_repository.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ManageMarqueeMessageType { add, edit }

abstract class ManageMarqueeMessageState {}

class ManageMarqueeMessageInitial extends ManageMarqueeMessageState {}

class ManageMarqueeMessageInProgress extends ManageMarqueeMessageState {}

class ManageMarqueeMessageSuccess extends ManageMarqueeMessageState {
  final ManageMarqueeMessageType type;
  final MarqueeMessageModel model;

  ManageMarqueeMessageSuccess(this.model, this.type);
}

class ManageMarqueeMessageFail extends ManageMarqueeMessageState {
  final dynamic error;

  ManageMarqueeMessageFail(this.error);
}

class ManageMarqueeMessageCubit extends Cubit<ManageMarqueeMessageState> {
  ManageMarqueeMessageCubit() : super(ManageMarqueeMessageInitial());
  final MarqueeMessageRepository _marqueeMessageRepository = MarqueeMessageRepository();

  void manage(ManageMarqueeMessageType type, Map<String, dynamic> data, File? image) async {
    try {
      emit(ManageMarqueeMessageInProgress());

      if (type == ManageMarqueeMessageType.add) {
        MarqueeMessageModel marqueeMessageModel = await _marqueeMessageRepository.createMarqueeMessage(data, image);
        emit(ManageMarqueeMessageSuccess(marqueeMessageModel, type));
      } else if (type == ManageMarqueeMessageType.edit) {
        MarqueeMessageModel marqueeMessageModel = await _marqueeMessageRepository.editMarqueeMessage(data, image);
        emit(ManageMarqueeMessageSuccess(marqueeMessageModel, type));
      }
    } catch (e) {
      emit(ManageMarqueeMessageFail(e));
    }
  }
}