import 'package:dio/dio.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/data/repositories/marquee/marquee_message_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchHomeAllMarqueeMessagesState {}

class FetchHomeAllMarqueeMessagesInitial extends FetchHomeAllMarqueeMessagesState {}

class FetchHomeAllMarqueeMessagesInProgress extends FetchHomeAllMarqueeMessagesState {}

class FetchHomeAllMarqueeMessagesSuccess extends FetchHomeAllMarqueeMessagesState {
  final List<MarqueeMessageModel> messages;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchHomeAllMarqueeMessagesSuccess({
    required this.messages,
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchHomeAllMarqueeMessagesSuccess copyWith({
    List<MarqueeMessageModel>? messages,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchHomeAllMarqueeMessagesSuccess(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchHomeAllMarqueeMessagesFail extends FetchHomeAllMarqueeMessagesState {
  final String error;

  FetchHomeAllMarqueeMessagesFail(this.error);
}

class FetchHomeAllMarqueeMessagesCubit extends Cubit<FetchHomeAllMarqueeMessagesState> {
  final MarqueeMessageRepository _marqueeMessageRepository = MarqueeMessageRepository();

  FetchHomeAllMarqueeMessagesCubit() : super(FetchHomeAllMarqueeMessagesInitial());

  void fetch({
    int? itemId,
    String? country,
    String? state,
    String? city,
    int? areaId,
    double? latitude,
    double? longitude,
    double? radius,
    String? sortBy,
    String? postedSince,
  }) async {
    try {
      emit(FetchHomeAllMarqueeMessagesInProgress());
      DataOutput<MarqueeMessageModel> result = await _marqueeMessageRepository.fetchAllMarqueeMessages(
        page: 1,
        itemId: itemId,
        country: country,
        state: state,
        city: city,
        areaId: areaId,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        sortBy: sortBy,
        postedSince: postedSince,
      );

      emit(FetchHomeAllMarqueeMessagesSuccess(
        page: 1,
        isLoadingMore: false,
        loadingMoreError: false,
        messages: result.modelList,
        total: result.total,
      ));
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioError && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      emit(FetchHomeAllMarqueeMessagesFail(errorMessage));
    }
  }

  Future<void> fetchMore({
    int? itemId,
    String? country,
    String? state,
    String? city,
    int? areaId,
    double? latitude,
    double? longitude,
    double? radius,
    String? sortBy,
    String? postedSince,
  }) async {
    try {
      if (state is FetchHomeAllMarqueeMessagesSuccess) {
        if ((state as FetchHomeAllMarqueeMessagesSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchHomeAllMarqueeMessagesSuccess).copyWith(isLoadingMore: true));
        DataOutput<MarqueeMessageModel> result = await _marqueeMessageRepository.fetchAllMarqueeMessages(
          page: (state as FetchHomeAllMarqueeMessagesSuccess).page + 1,
          itemId: itemId,
          country: country,
          state: state,
          city: city,
          areaId: areaId,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          sortBy: sortBy,
          postedSince: postedSince,
        );

        FetchHomeAllMarqueeMessagesSuccess currentState = (state as FetchHomeAllMarqueeMessagesSuccess);
        currentState.messages.addAll(result.modelList);
        emit(FetchHomeAllMarqueeMessagesSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          messages: currentState.messages,
          page: currentState.page + 1,
          total: result.total,
        ));
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioError && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      emit((state as FetchHomeAllMarqueeMessagesSuccess).copyWith(
        isLoadingMore: false,
        loadingMoreError: true,
      ));
    }
  }

  bool hasMoreData() {
    if (state is FetchHomeAllMarqueeMessagesSuccess) {
      return (state as FetchHomeAllMarqueeMessagesSuccess).messages.length <
          (state as FetchHomeAllMarqueeMessagesSuccess).total;
    }
    return false;
  }
}