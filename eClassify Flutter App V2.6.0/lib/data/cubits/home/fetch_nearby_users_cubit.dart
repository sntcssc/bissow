import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/user_model.dart';
import 'package:eClassify/data/repositories/home/home_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchNearbyUsersState {}

class FetchNearbyUsersInitial extends FetchNearbyUsersState {}

class FetchNearbyUsersInProgress extends FetchNearbyUsersState {}

class FetchNearbyUsersSuccess extends FetchNearbyUsersState {
  final List<UserModel> users;
  final bool isLoadingMore;
  final bool loadingMoreError;
  final int page;
  final int total;

  FetchNearbyUsersSuccess({
    required this.users,
    required this.isLoadingMore,
    required this.loadingMoreError,
    required this.page,
    required this.total,
  });

  FetchNearbyUsersSuccess copyWith({
    List<UserModel>? users,
    bool? isLoadingMore,
    bool? loadingMoreError,
    int? page,
    int? total,
  }) {
    return FetchNearbyUsersSuccess(
      users: users ?? this.users,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class FetchNearbyUsersFail extends FetchNearbyUsersState {
  final dynamic error;

  FetchNearbyUsersFail(this.error);
}

class FetchNearbyUsersCubit extends Cubit<FetchNearbyUsersState> {
  FetchNearbyUsersCubit() : super(FetchNearbyUsersInitial());

  final HomeRepository _homeRepository = HomeRepository();

  void fetch({
    String? country,
    String? state,
    String? city,
    int? areaId,
    int? radius,
    double? latitude,
    double? longitude,
  }) async {
    try {
      emit(FetchNearbyUsersInProgress());
      final params = {
        'city': city,
        'country': country,
        'state': state,
        'areaId': areaId,
        'radius': radius,
        'latitude': latitude,
        'longitude': longitude,
      };
      if (kDebugMode) {
        print('Fetching nearby users with params: $params');
      }
      DataOutput<UserModel> result = await _homeRepository.fetchNearbyUsers(
        page: 1,
        city: city,
        areaId: areaId,
        country: country,
        state: state,
        radius: radius,
        longitude: longitude,
        latitude: latitude,
      );

      if (kDebugMode) {
        print('Fetched ${result.modelList.length} users, total: ${result.total}');
        print('User data: ${result.modelList.map((u) => u.toString()).toList()}');
      }

      emit(
        FetchNearbyUsersSuccess(
          page: 1,
          isLoadingMore: false,
          loadingMoreError: false,
          users: result.modelList,
          total: result.total,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('FetchNearbyUsersCubit fetch error: $e');
      }
      print('FetchNearbyUsersCubit fetch error: $e');
      emit(FetchNearbyUsersFail(e));
    }
  }

  Future<void> fetchMore({
    String? country,
    String? stateName,
    String? city,
    int? areaId,
    int? radius,
    double? latitude,
    double? longitude,
  }) async {
    try {
      if (state is FetchNearbyUsersSuccess) {
        if ((state as FetchNearbyUsersSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchNearbyUsersSuccess).copyWith(isLoadingMore: true));
        DataOutput<UserModel> result = await _homeRepository.fetchNearbyUsers(
          page: (state as FetchNearbyUsersSuccess).page + 1,
          city: city,
          areaId: areaId,
          country: country,
          state: stateName,
          radius: radius,
          latitude: latitude,
          longitude: longitude,
        );

        FetchNearbyUsersSuccess userState = (state as FetchNearbyUsersSuccess);
        userState.users.addAll(result.modelList);
        if (kDebugMode) {
          print('Fetched more ${result.modelList.length} users, new total: ${userState.users.length}');
        }
        emit(FetchNearbyUsersSuccess(
          isLoadingMore: false,
          loadingMoreError: false,
          users: userState.users,
          page: (state as FetchNearbyUsersSuccess).page + 1,
          total: result.total,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('FetchNearbyUsersCubit fetchMore error: $e');
      }
      emit((state as FetchNearbyUsersSuccess)
          .copyWith(isLoadingMore: false, loadingMoreError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchNearbyUsersSuccess) {
      return (state as FetchNearbyUsersSuccess).users.length <
          (state as FetchNearbyUsersSuccess).total;
    }
    return false;
  }
}