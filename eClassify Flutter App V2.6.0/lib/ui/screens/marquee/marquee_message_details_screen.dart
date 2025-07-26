import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MarqueeMessageDetailsScreen extends StatefulWidget {
  final MarqueeMessageModel model;

  const MarqueeMessageDetailsScreen({
    super.key,
    required this.model,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return MaterialPageRoute(
      builder: (context) => MarqueeMessageDetailsScreen(
        model: arguments?['model'] as MarqueeMessageModel,
      ),
    );
  }

  @override
  _MarqueeMessageDetailsScreenState createState() => _MarqueeMessageDetailsScreenState();
}

class _MarqueeMessageDetailsScreenState extends State<MarqueeMessageDetailsScreen> {
  ItemModel? item;
  bool isLoadingItem = true;

  @override
  void initState() {
    super.initState();
    fetchItem();
    // print("MarqueeMessage image URL: ${widget.model.image}");
  }

  Future<void> fetchItem() async {
    setState(() {
      isLoadingItem = true;
    });
    try {
      DataOutput<ItemModel> result = await ItemRepository().fetchMyItems(page: 1);
      setState(() {
        item = result.modelList.firstWhere(
              (i) => i.id == widget.model.itemId,
          orElse: () => ItemModel(id: 0, name: "None"),
        );
        isLoadingItem = false;
      });
    } catch (e) {
      setState(() {
        isLoadingItem = false;
      });
      HelperUtils.showSnackBarMessage(context, "failedToLoadItem".translate(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "messageDetails".translate(context),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 18,
          left: 18,
          right: 18,
        ),
        child: UiUtils.buildButton(
          context,
          height: 48,
          fontSize: context.font.large,
          buttonTitle: "editMessage".translate(context),
          onPressed: () {
            Navigator.pushNamed(context, Routes.addMarqueeMessageDetails, arguments: {
              "isEdit": true,
              "message": widget.model,
            }).then((value) {
              if (value == "refresh") {
                // Refresh the details if edited
                Navigator.pop(context, "refresh");
              }
            });
          },
          radius: 8,
          buttonColor: context.color.territoryColor,
          textColor: context.color.textColorDark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "messageDetails".translate(context),
              fontSize: context.font.larger,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            const SizedBox(height: 20),
            if (widget.model.image != null && widget.model.image!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  UiUtils.showFullScreenImage(context, provider: NetworkImage(widget.model.image!));
                },
                child: Container(
                  width: double.maxFinite,
                  height: 200,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.color.textLightColor.withOpacity(0.35)),
                  ),
                  child: UiUtils.getImage(widget.model.image!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 15),
            _buildDetailRow(context, "message".translate(context), widget.model.message ?? "N/A"),
            const SizedBox(height: 10),
            _buildDetailRow(context, "item".translate(context), isLoadingItem ? "Loading..." : (item?.name ?? "None")),
            const SizedBox(height: 10),
            _buildDetailRow(context, "displayOrder".translate(context), widget.model.displayOrder?.toString() ?? "N/A"),
            const SizedBox(height: 10),
            _buildDetailRow(context, "startDate".translate(context), widget.model.startDate?.toIso8601String().substring(0, 10) ?? "N/A"),
            const SizedBox(height: 10),
            _buildDetailRow(context, "endDate".translate(context), widget.model.endDate?.toIso8601String().substring(0, 10) ?? "N/A"),
            const SizedBox(height: 10),
            _buildDetailRow(context, "status".translate(context), widget.model.isActive == true ? "active".translate(context) : "inactive".translate(context)),
            const SizedBox(height: 10),
            _buildDetailRow(context, "location".translate(context), [
              widget.model.areaId != null ? "Area ID: ${widget.model.areaId}" : null,
              widget.model.city,
              widget.model.state,
              widget.model.country,
            ].where((part) => part != null && part.isNotEmpty).join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.textLightColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.textLightColor.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: context.font.normal,
            fontWeight: FontWeight.w600,
            color: context.color.textColorDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              value,
              fontSize: context.font.normal,
              color: context.color.textLightColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}