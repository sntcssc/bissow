import 'package:eClassify/data/repositories/marquee/marquee_message_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteMarqueeMessageState {}

class DeleteMarqueeMessageInitial extends DeleteMarqueeMessageState {}

class DeleteMarqueeMessageInProgress extends DeleteMarqueeMessageState {}

class DeleteMarqueeMessageSuccess extends DeleteMarqueeMessageState {}

class DeleteMarqueeMessageFailure extends DeleteMarqueeMessageState {
  final String errorMessage;

  DeleteMarqueeMessageFailure(this.errorMessage);
}

class DeleteMarqueeMessageCubit extends Cubit<DeleteMarqueeMessageState> {
  final MarqueeMessageRepository _marqueeMessageRepository = MarqueeMessageRepository();

  DeleteMarqueeMessageCubit() : super(DeleteMarqueeMessageInitial());

  Future<void> deleteMarqueeMessage(int id) async {
    try {
      emit(DeleteMarqueeMessageInProgress());
      await _marqueeMessageRepository.deleteMarqueeMessage(id);
      emit(DeleteMarqueeMessageSuccess());
    } catch (e) {
      emit(DeleteMarqueeMessageFailure(e.toString()));
    }
  }
}