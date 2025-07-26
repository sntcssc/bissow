import 'dart:developer';

import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/data/repositories/marquee/marquee_message_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchMyMarqueeMessagesState {}

class FetchMyMarqueeMessagesInitial extends FetchMyMarqueeMessagesState {}

class FetchMyMarqueeMessagesInProgress extends FetchMyMarqueeMessagesState {}

class FetchMyMarqueeMessagesSuccess extends FetchMyMarqueeMessagesState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<MarqueeMessageModel> messages;

  FetchMyMarqueeMessagesSuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.messages,
  });

  FetchMyMarqueeMessagesSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<MarqueeMessageModel>? messages,
  }) {
    return FetchMyMarqueeMessagesSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      messages: messages ?? this.messages,
    );
  }

  @override
  String toString() {
    return 'FetchMyMarqueeMessagesSuccess{messages: $messages}';
  }
}

class FetchMyMarqueeMessagesFailed extends FetchMyMarqueeMessagesState {
  final dynamic error;

  FetchMyMarqueeMessagesFailed(this.error);
}

class FetchMyMarqueeMessagesCubit extends Cubit<FetchMyMarqueeMessagesState> {
  FetchMyMarqueeMessagesCubit() : super(FetchMyMarqueeMessagesInitial());
  final MarqueeMessageRepository _marqueeMessageRepository = MarqueeMessageRepository();

  void fetchMyMarqueeMessages({String? status}) async {
    try {
      emit(FetchMyMarqueeMessagesInProgress());
      DataOutput<MarqueeMessageModel> result = await _marqueeMessageRepository.fetchMyMarqueeMessages(page: 1, status: status);
      emit(FetchMyMarqueeMessagesSuccess(
        hasError: false,
        isLoadingMore: false,
        page: 1,
        messages: result.modelList,
        total: result.total,
      ));
    } catch (e) {
      emit(FetchMyMarqueeMessagesFailed(e.toString()));
    }
  }

  void addMarqueeMessage(MarqueeMessageModel message) {
    if (state is FetchMyMarqueeMessagesSuccess) {
      List<MarqueeMessageModel> messages = (state as FetchMyMarqueeMessagesSuccess).messages;
      messages.insert(0, message);
      emit((state as FetchMyMarqueeMessagesSuccess).copyWith(messages: messages));
    }
  }

  void deleteMarqueeMessage(MarqueeMessageModel model) {
    if (state is FetchMyMarqueeMessagesSuccess) {
      List<MarqueeMessageModel> messages = (state as FetchMyMarqueeMessagesSuccess).messages;
      messages.removeWhere((element) => element.id == model.id);
      emit((state as FetchMyMarqueeMessagesSuccess).copyWith(messages: messages));
    }
  }

  void edit(MarqueeMessageModel message) {
    if (state is FetchMyMarqueeMessagesSuccess) {
      List<MarqueeMessageModel> messages = (state as FetchMyMarqueeMessagesSuccess).messages;
      int index = messages.indexWhere((element) {
        log('${element.id} - ${message.id}');
        return element.id == message.id;
      });
      if (index != -1) {
        messages[index] = message;
        if (!isClosed) {
          emit((state as FetchMyMarqueeMessagesSuccess).copyWith(messages: messages));
        }
      }
    }
  }

  Future<void> fetchMyMoreMarqueeMessages({String? status}) async {
    try {
      if (state is FetchMyMarqueeMessagesSuccess) {
        if ((state as FetchMyMarqueeMessagesSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyMarqueeMessagesSuccess).copyWith(isLoadingMore: true));
        DataOutput<MarqueeMessageModel> result = await _marqueeMessageRepository.fetchMyMarqueeMessages(
          page: (state as FetchMyMarqueeMessagesSuccess).page + 1,
          status: status,
        );
        FetchMyMarqueeMessagesSuccess messagesState = (state as FetchMyMarqueeMessagesSuccess);
        messagesState.messages.addAll(result.modelList);
        emit(FetchMyMarqueeMessagesSuccess(
          isLoadingMore: false,
          hasError: false,
          messages: messagesState.messages,
          page: (state as FetchMyMarqueeMessagesSuccess).page + 1,
          total: result.total,
        ));
      }
    } catch (e) {
      emit((state as FetchMyMarqueeMessagesSuccess).copyWith(
        isLoadingMore: false,
        hasError: true,
      ));
    }
  }

  bool hasMoreData() {
    if (state is FetchMyMarqueeMessagesSuccess) {
      return (state as FetchMyMarqueeMessagesSuccess).messages.length <
          (state as FetchMyMarqueeMessagesSuccess).total;
    }
    return false;
  }
}