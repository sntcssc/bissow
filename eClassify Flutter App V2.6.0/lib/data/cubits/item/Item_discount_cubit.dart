// 2025.04.03 - Subhankar added for item discount entry

import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ItemDiscountState {
  final List<int>? discountedItemIds;
  ItemDiscountState({this.discountedItemIds});
}

class ItemDiscountInitial extends ItemDiscountState {}

class ItemDiscountLoading extends ItemDiscountState {}

class ItemDiscountSuccess extends ItemDiscountState {
  final String message;
  final List<int> successfulItemIds;
  final int? discountId; // For update/toggle
  final bool? isActive; // For toggle
  ItemDiscountSuccess(this.message, this.successfulItemIds, {this.discountId, this.isActive, List<int>? discountedItemIds})
      : super(discountedItemIds: discountedItemIds);
}

class ItemDiscountFailure extends ItemDiscountState {
  final String error;
  ItemDiscountFailure(this.error, {List<int>? discountedItemIds}) : super(discountedItemIds: discountedItemIds);
}

class ItemDiscountCubit extends Cubit<ItemDiscountState> {
  final ItemRepository repository;
  bool _isSubmitting = false;

  ItemDiscountCubit(this.repository) : super(ItemDiscountInitial());

  void createDiscount({
    required List<int> itemIds,
    required double discountValue,
    required String discountType,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(ItemDiscountLoading());
    try {
      final response = await repository.createItemDiscount(
        itemIds: itemIds,
        discountValue: discountValue,
        discountType: discountType,
        startDate: startDate,
        endDate: endDate,
        discountSource: 'Customer',
      );
      final bool success = response['success'] ?? false;
      if (success) {
        emit(ItemDiscountSuccess(
          response['message'] ?? "Discount applied",
          List<int>.from(response['data']['successful_item_ids'] ?? []),
          discountedItemIds: response['data']['discounted_item_ids'] != null
              ? List<int>.from(response['data']['discounted_item_ids'])
              : null,
        ));
      } else {
        emit(ItemDiscountFailure(
          response['message'] ?? "Unknown error",
          discountedItemIds: response['data']['discounted_item_ids'] != null
              ? List<int>.from(response['data']['discounted_item_ids'])
              : null,
        ));
      }
    } catch (e) {
      emit(ItemDiscountFailure("Error: $e"));
    } finally {
      _isSubmitting = false;
    }
  }

  void updateDiscount({
    required int discountId,
    required double discountValue,
    required String discountType,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(ItemDiscountLoading());
    try {
      final response = await repository.updateItemDiscount(
        discountId: discountId,
        discountValue: discountValue,
        discountType: discountType,
        startDate: startDate,
        endDate: endDate,
      );
      final bool success = response['success'] ?? false;
      if (success) {
        emit(ItemDiscountSuccess(
          response['message'] ?? "Discount updated",
          [], // No successful_item_ids for update
          discountId: response['data']['discount_id'],
        ));
      } else {
        emit(ItemDiscountFailure(response['message'] ?? "Unknown error"));
      }
    } catch (e) {
      emit(ItemDiscountFailure("Error: $e"));
    } finally {
      _isSubmitting = false;
    }
  }

  void toggleDiscountActive({
    required int discountId,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit(ItemDiscountLoading());
    try {
      final response = await repository.toggleDiscountActive(discountId: discountId);
      print('Cubit Toggle Response: $response');
      final bool success = response['success'] ?? false;
      if (success) {
        final bool newIsActive = response['data']['is_active'] as bool;
        emit(ItemDiscountSuccess(
          response['message'] ?? "Discount toggled",
          [], // No successful_item_ids for toggle
          discountId: response['data']['discount_id'] as int,
          isActive: newIsActive,
        ));
      } else {
        emit(ItemDiscountFailure(response['message'] ?? "Unknown error"));
      }
    } catch (e) {
      emit(ItemDiscountFailure("Error: $e"));
    } finally {
      _isSubmitting = false;
    }
  }
}