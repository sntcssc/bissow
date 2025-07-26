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
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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
  int? currentUserId; // Placeholder for logged-in user ID

  @override
  void initState() {
    super.initState();
    fetchCurrentUserId();
    fetchItem();
    print("Marquee ID: ${widget.model.id}");
    print("User ID : ${HiveUtils.getUserId()}");
  }

  Future<void> fetchCurrentUserId() async {
    // Replace with your actual method to get the logged-in user's ID
    // Example: Using a provider, Firebase Auth, or SharedPreferences
    try {
      // Placeholder: Replace with actual implementation
      // e.g., currentUserId = await AuthProvider().getUserId();
      String? getUserID = HiveUtils.getUserId();
      currentUserId = int.parse(getUserID!); // Dummy value; replace with real user ID fetching logic
      print("User ID : ${currentUserId}");
      setState(() {});
    } catch (e) {
      // Handle error if needed
      print("Error fetching user ID: $e");
    }
  }

  Future<void> fetchItem() async {
    setState(() {
      isLoadingItem = true;
    });
    try {
      DataOutput<ItemModel> result = await ItemRepository().fetchItemFromItemId(widget.model.itemId!);
      setState(() {
        item = result.modelList.isNotEmpty ? result.modelList.first : ItemModel(id: 0, name: "None");
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
    final dateFormat = DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "Message Details".translate(context),
        // titleTextStyle: TextStyle(
        //   fontSize: context.font.larger,
        //   fontWeight: FontWeight.w600,
        //   color: context.color.textColorDark,
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Header
            Text(
              widget.model.message ?? "No Message",
              style: TextStyle(
                fontSize: context.font.large,
                fontWeight: FontWeight.bold,
                color: context.color.textColorDark,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Image Section
            if (widget.model.image != null && widget.model.image!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  UiUtils.showFullScreenImage(context, provider: NetworkImage(widget.model.image!));
                },
                child: Container(
                  width: double.maxFinite,
                  height: 220,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.color.textLightColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: context.color.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: UiUtils.getImage(
                    widget.model.image!,
                    fit: BoxFit.cover,
                    // placeholder: Icons.image,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Details Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.color.textLightColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: context.color.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.description,
                    label: "Message",
                    value: widget.model.message ?? "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.category,
                    label: "Item",
                    value: isLoadingItem ? "Loading..." : (item?.name ?? "None"),
                    onTap: isLoadingItem || item == null || item!.id == 0
                        ? null
                        : () {
                      Navigator.pushNamed(
                        context,
                        Routes.adDetailsScreen,
                        arguments: {'model': item},
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.sort,
                    label: "Display Order",
                    value: widget.model.displayOrder?.toString() ?? "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: "Start Date",
                    value: widget.model.startDate != null
                        ? dateFormat.format(widget.model.startDate!)
                        : "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_month,
                    label: "End Date",
                    value: widget.model.endDate != null
                        ? dateFormat.format(widget.model.endDate!)
                        : "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.check_circle,
                    label: "Status",
                    value: widget.model.isActive == true
                        ? "Active".translate(context)
                        : "Inactive".translate(context),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on,
                    label: "Location",
                    value: [
                      widget.model.areaId != null ? "Area ID: ${widget.model.areaId}" : null,
                      widget.model.city,
                      widget.model.state,
                      widget.model.country,
                    ].where((part) => part != null && part.isNotEmpty).join(', '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Edit Button
            // Buttons Row
            Row(
              children: [
                if (currentUserId != null && widget.model.userId == currentUserId)
                  Expanded(
                    child: UiUtils.buildButton(
                      context,
                      height: 50,
                      fontSize: context.font.large,
                      buttonTitle: "Edit Message".translate(context),
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.addMarqueeMessageDetails, arguments: {
                          "isEdit": true,
                          "message": widget.model,
                        }).then((value) {
                          if (value == "refresh") {
                            Navigator.pop(context, "refresh");
                          }
                        });
                      },
                      radius: 12,
                      buttonColor: context.color.territoryColor,
                      textColor: context.color.textColorDark,
                    ),
                  ),
                if (currentUserId != null && widget.model.userId == currentUserId)
                  const SizedBox(width: 16),
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    height: 50,
                    fontSize: context.font.large,
                    buttonTitle: "View Item Details".translate(context),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.adDetailsScreen,
                        arguments: {'model': item},
                      );
                    },
                    radius: 12,
                    buttonColor: context.color.territoryColor.withOpacity(0.8),
                    textColor: context.color.textColorDark,
                    // disabledButtonColor: context.color.textLightColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: context.color.textLightColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: context.color.territoryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.translate(context),
                    style: TextStyle(
                      fontSize: context.font.normal,
                      fontWeight: FontWeight.w600,
                      color: context.color.textColorDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: context.font.normal,
                      color: context.color.textLightColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.color.textLightColor.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}