// 2025.04.03 - Subhankar added for item discount entry

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/item/Item_discount_cubit.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/utils/helper_utils.dart';

class DiscountFormWidget extends StatefulWidget {
  final List<int>? itemIds; // For adding
  final List<ItemModel>? items; // For preview
  final int? discountId; // For editing
  final Map<String, dynamic>? existingDiscount; // For editing
  final VoidCallback? onSuccess;

  const DiscountFormWidget({
    Key? key,
    this.itemIds,
    this.items,
    this.discountId,
    this.existingDiscount,
    this.onSuccess,
  }) : super(key: key);

  @override
  _DiscountFormWidgetState createState() => _DiscountFormWidgetState();
}

class _DiscountFormWidgetState extends State<DiscountFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late double _discountValue;
  late String _discountType;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingDiscount != null) {
      _discountValue = widget.existingDiscount!['discount_value'].toDouble();
      _discountType = widget.existingDiscount!['discount_type'];
      _startDate = DateTime.parse(widget.existingDiscount!['start_date']);
      _endDate = widget.existingDiscount!['end_date'] != null
          ? DateTime.parse(widget.existingDiscount!['end_date'])
          : null;
    } else {
      _discountValue = 0.0;
      _discountType = 'percentage';
      _startDate = DateTime.now();
    }
  }

  double _calculateDiscountedPrice(double? originalPrice) {
    return _discountType == 'percentage'
        ? originalPrice! * (1 - _discountValue / 100)
        : originalPrice! - _discountValue;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemDiscountCubit(ItemRepository()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 8.0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<ItemDiscountCubit, ItemDiscountState>(
            listener: (context, state) {
              if (state is ItemDiscountLoading) {
                setState(() => _isButtonEnabled = false);
              } else if (state is ItemDiscountSuccess) {
                HelperUtils.showSnackBarMessage(context, state.message, messageDuration: 5);
                if (state.discountedItemIds?.isNotEmpty ?? false) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    "Some items already have discounts".translate(context),
                    messageDuration: 5,
                  );
                }
                widget.onSuccess?.call();
                // Navigator.pop(context);
                // Navigator.pop(context);
                HelperUtils.killPreviousPages(
                    context, Routes.main, {"from": "login"});
              } else if (state is ItemDiscountFailure) {
                HelperUtils.showSnackBarMessage(context, state.error, messageDuration: 5);
                setState(() => _isButtonEnabled = true);
              }
            },
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.discountId != null ? "Edit Discount".translate(context) : "Add Discount".translate(context),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      if (widget.itemIds != null)
                        Chip(
                          label: Text("${widget.itemIds!.length} Item${widget.itemIds!.length > 1 ? 's' : ''}"),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      if (widget.items != null && widget.items!.isNotEmpty) ...[
                        const SizedBox(height: 20.0),
                        _buildPreview(context),
                      ],
                      const SizedBox(height: 24.0),
                      _buildDiscountValueField(context),
                      const SizedBox(height: 16.0),
                      _buildDiscountTypeField(context),
                      const SizedBox(height: 16.0),
                      _buildDateField(context, "Start Date", _startDate, (date) => setState(() => _startDate = date), true),
                      const SizedBox(height: 16.0),
                      _buildDateField(context, "End Date (Optional)", _endDate, (date) => setState(() => _endDate = date), false),
                      const SizedBox(height: 28.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isButtonEnabled && state is! ItemDiscountLoading
                              ? () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              if (widget.discountId != null) {
                                context.read<ItemDiscountCubit>().updateDiscount(
                                  discountId: widget.discountId!,
                                  discountValue: _discountValue,
                                  discountType: _discountType,
                                  startDate: _startDate,
                                  endDate: _endDate,
                                );
                              } else {
                                context.read<ItemDiscountCubit>().createDiscount(
                                  itemIds: widget.itemIds!,
                                  discountValue: _discountValue,
                                  discountType: _discountType,
                                  startDate: _startDate,
                                  endDate: _endDate,
                                );
                              }
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            elevation: 2.0,
                          ),
                          child: state is ItemDiscountLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : Text(
                            widget.discountId != null ? "Update Discount".translate(context) : "Apply Discount".translate(context),
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Preview".translate(context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          ...widget.items!.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "${item.name}",
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${item.originalPrice}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      _calculateDiscountedPrice(item.originalPrice).toStringAsFixed(2),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDiscountValueField(BuildContext context) {
    return TextFormField(
      initialValue: _discountValue.toString(),
      decoration: InputDecoration(
        labelText: "Discount Value".translate(context),
        hintText: _discountType == 'percentage' ? "e.g., 20 (%)" : "e.g., 50",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        prefixIcon: const Icon(Icons.local_offer_outlined),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return "Enter a discount value".translate(context);
        final numValue = double.tryParse(value);
        if (numValue == null || numValue <= 0) return "Enter a valid positive number".translate(context);
        if (_discountType == 'percentage' && numValue > 100) return "Percentage cannot exceed 100".translate(context);
        return null;
      },
      onChanged: (value) => setState(() => _discountValue = double.tryParse(value) ?? 0.0),
      onSaved: (value) => _discountValue = double.parse(value!),
    );
  }

  Widget _buildDiscountTypeField(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _discountType,
      decoration: InputDecoration(
        labelText: "Discount Type".translate(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        prefixIcon: const Icon(Icons.percent_outlined),
      ),
      items: [
        DropdownMenuItem(value: 'percentage', child: Text("Percentage (%)")),
        DropdownMenuItem(value: 'fixed', child: Text("Fixed Amount")),
      ],
      onChanged: (value) => setState(() => _discountType = value!),
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime? initialDate, Function(DateTime) onDateSelected, bool required) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) onDateSelected(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label.translate(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          initialDate != null
              ? DateFormat('dd/MM/yyyy').format(initialDate)
              : "Select Date".translate(context),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}