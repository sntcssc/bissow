// 2025.04.03 - Subhankar added for item discount entry

import 'package:eClassify/data/cubits/item/Item_discount_cubit.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/ui/screens/item/discount_form_widget.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddDiscountFromMenuScreen extends StatefulWidget {
  const AddDiscountFromMenuScreen({Key? key}) : super(key: key);

  @override
  _AddDiscountFromMenuScreenState createState() => _AddDiscountFromMenuScreenState();
}

class _AddDiscountFromMenuScreenState extends State<AddDiscountFromMenuScreen> {
  List<int> selectedItemIds = [];
  Map<int, DiscountDetails?> discountStatus = {};
  List<ItemModel> allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final DataOutput<ItemModel> result = await ItemRepository().fetchMyItems();
      setState(() {
        allItems = result.modelList;
        discountStatus = {
          for (var item in allItems) item.id!: item.discountDetails
        };
        _isLoading = false;
      });
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Failed to load items: $e".translate(context));
      setState(() => _isLoading = false);
    }
  }

  void _showDiscountForm({DiscountDetails? existingDiscount, int? discountId}) {
    final selectedItems = allItems.where((item) => selectedItemIds.contains(item.id)).toList();
    if (existingDiscount == null && selectedItems.isEmpty) {
      HelperUtils.showSnackBarMessage(context, "Please select at least one item".translate(context));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => DiscountFormWidget(
        itemIds: existingDiscount == null ? selectedItemIds : null,
        items: existingDiscount == null
            ? selectedItems
            : [allItems.firstWhere((item) => item.id == existingDiscount.itemId)],
        discountId: discountId,
        existingDiscount: existingDiscount?.toJson(),
        onSuccess: () {
          _fetchItems();
          if (existingDiscount == null) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Discounts".translate(context)),
        elevation: 0,
        actions: [
          if (selectedItemIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showDiscountForm(),
                icon: const Icon(Icons.add, size: 20),
                label: Text("Add Discount".translate(context)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
        ],
      ),
      body: BlocProvider(
        create: (context) => ItemDiscountCubit(ItemRepository()),
        child: BlocListener<ItemDiscountCubit, ItemDiscountState>(
          listener: (context, state) {
            if (state is ItemDiscountSuccess) {
              HelperUtils.showSnackBarMessage(context, state.message, messageDuration: 3);
              _fetchItems(); // Refresh items on any success (create, update, toggle)
            } else if (state is ItemDiscountFailure) {
              HelperUtils.showSnackBarMessage(context, state.error, messageDuration: 3);
            }
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchItems,
            child: allItems.isEmpty
                ? Center(child: Text("No items available".translate(context)))
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                final discount = discountStatus[item.id];
                final isDiscounted = discount != null;
                return Card(
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: CheckboxListTile(
                    title: Row(
                      children: [
                        Flexible(child: Text(item.name ?? '', overflow: TextOverflow.ellipsis)),
                        if (isDiscounted) ...[
                          const SizedBox(width: 8.0),
                          Chip(
                            label: Text(
                              discount!.isActive ? "Active".translate(context) : "Inactive".translate(context),
                            ),
                            backgroundColor: discount.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: discount.isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price: ${item.price}${isDiscounted ? ' (Discounted)' : ''}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (isDiscounted)
                          Text(
                            "Discount: ${discount!.discountValue} ${discount.discountType == 'percentage' ? '%' : ''}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                    value: selectedItemIds.contains(item.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedItemIds.add(item.id!);
                        } else {
                          selectedItemIds.remove(item.id!);
                        }
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    secondary: isDiscounted
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => _showDiscountForm(existingDiscount: discount, discountId: discount!.id),
                        ),
                        IconButton(
                          icon: Icon(
                            discount!.isActive ? Icons.toggle_on : Icons.toggle_off,
                            size: 24,
                            color: discount.isActive ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            print('Toggling discount for ID: ${discount!.id}');
                            context.read<ItemDiscountCubit>().toggleDiscountActive(discountId: discount!.id);
                          },
                        ),
                      ],
                    )
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}