import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/image_picker.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddMarqueeMessageDetails extends StatefulWidget {
  final bool isEdit;
  final MarqueeMessageModel? message;

  const AddMarqueeMessageDetails({
    super.key,
    this.isEdit = false,
    this.message,
  });

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (context) => AddMarqueeMessageDetails(
        isEdit: arguments?['isEdit'] ?? false,
        message: arguments?['message'],
      ),
    );
  }

  @override
  CloudState<AddMarqueeMessageDetails> createState() => _AddMarqueeMessageDetailsState();
}

class _AddMarqueeMessageDetailsState extends CloudState<AddMarqueeMessageDetails> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PickImage _pickImage = PickImage();
  String imageURL = "";
  final TextEditingController messageController = TextEditingController();
  final TextEditingController displayOrderController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  ItemModel? selectedItem;
  bool isActive = true;
  List<ItemModel> items = [];
  bool isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.message != null) {
      messageController.text = widget.message?.message ?? "";
      displayOrderController.text = widget.message?.displayOrder?.toString() ?? "";
      startDateController.text = widget.message?.startDate?.toIso8601String().substring(0, 10) ?? "";
      endDateController.text = widget.message?.endDate?.toIso8601String().substring(0, 10) ?? "";
      imageURL = widget.message?.image ?? "";
      isActive = widget.message?.isActive ?? true;
      fetchItems();
    } else {
      fetchItems();
    }
    _pickImage.listener((files) {
      imageURL = "";
      setState(() {});
    });
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoadingItems = true;
    });
    try {
      DataOutput<ItemModel> result = await ItemRepository().fetchMyItems(page: 1);
      setState(() {
        items = result.modelList;
        isLoadingItems = false;
        if (widget.isEdit && widget.message?.itemId != null) {
          selectedItem = items.firstWhere(
                (item) => item.id == widget.message!.itemId,
            orElse: () => ItemModel(id: 0, name: "None"),
          );
        }
      });
    } catch (e) {
      setState(() {
        isLoadingItems = false;
      });
      HelperUtils.showSnackBarMessage(context, "failedToLoadItems".translate(context));
    }
  }

  Future<void> showImageSourceDialog(BuildContext context, Function(ImageSource) onSelected) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText('selectImageSource'.translate(context)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: CustomText('camera'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.camera);
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: CustomText('gallery'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget imageListener() {
    return _pickImage.listenChangesInUI((context, List<File>? files) {
      Widget currentWidget = Container();
      File? file = files?.isNotEmpty == true ? files![0] : null;

      if (imageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: NetworkImage(imageURL));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: UiUtils.getImage(imageURL, fit: BoxFit.cover),
          ),
        );
      }

      if (file != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }

      return Wrap(
        children: [
          if (file == null && imageURL.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    _pickImage.resumeSubscription();
                    _pickImage.pick(
                      pickMultiple: false,
                      context: context,
                      source: source,
                      enableEditing: true,
                    );
                    _pickImage.pauseSubscription();
                    imageURL = "";
                    setState(() {});
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addMainPicture".translate(context),
                    color: context.color.textColorDark,
                    fontSize: context.font.large,
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              if (file != null || imageURL.isNotEmpty)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: GestureDetector(
                    onTap: () {
                      _pickImage.clearImage();
                      imageURL = "";
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.color.primaryColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (file != null || imageURL.isNotEmpty)
            GestureDetector(
              onTap: () {
                showImageSourceDialog(context, (source) {
                  _pickImage.resumeSubscription();
                  _pickImage.pick(
                    pickMultiple: false,
                    context: context,
                    source: source,
                    enableEditing: true,
                  );
                  _pickImage.pauseSubscription();
                  imageURL = "";
                  setState(() {});
                });
              },
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(5),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: DottedBorder(
                  color: context.color.textColorDark.withValues(alpha: 0.5),
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(10),
                  child: Container(
                    alignment: AlignmentDirectional.center,
                    child: CustomText("uploadPhoto".translate(context)),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    displayOrderController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    _pickImage.dispose();
    super.dispose();
  }

  String? validateItem(ItemModel? value) {
    return value == null || value.id == 0 ? "selectItemRequired".translate(context) : null;
  }

  String? validateStatus(bool? value) {
    return value == null ? "statusRequired".translate(context) : null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedSafeArea(
      isAnnotated: true,
      child: Scaffold(
        appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
          title: widget.isEdit ? "editMarqueeMessage".translate(context) : "addMarqueeMessage".translate(context),
        ),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: UiUtils.buildButton(
            context,
            outerPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // Validate end date is after start date
                DateTime? startDate = DateTime.tryParse(startDateController.text);
                DateTime? endDate = DateTime.tryParse(endDateController.text);
                if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
                  UiUtils.showBlurredDialoge(
                    context,
                    dialoge: BlurredDialogBox(
                      title: "invalidDate".translate(context),
                      content: CustomText("endDateAfterStartDate".translate(context)),
                      acceptButtonName: "ok".translate(context),
                    ),
                  );
                  return;
                }
                if (_pickImage.pickedFile == null && imageURL.isEmpty) {
                  UiUtils.showBlurredDialoge(
                    context,
                    dialoge: BlurredDialogBox(
                      title: "imageRequired".translate(context),
                      content: CustomText("selectImageYourMessage".translate(context)),
                      acceptButtonName: "ok".translate(context),
                    ),
                  );
                  return;
                }
                // Store marquee message details
                Map<String, dynamic> marqueeDetails = {
                  "message": messageController.text,
                  "display_order": int.tryParse(displayOrderController.text) ?? 0,
                  "start_date": startDateController.text,
                  "end_date": endDateController.text,
                  "is_active": isActive,
                  "item_id": selectedItem?.id,
                  "user_id": HiveUtils.getUserId(),
                  if (widget.isEdit) "id": widget.message?.id,
                };
                addCloudData("marquee_message_details", marqueeDetails);
                // Store edit_request for edit mode
                if (widget.isEdit && widget.message != null) {
                  addCloudData("edit_request", widget.message);
                }
                Navigator.pushNamed(context, Routes.confirmMarqueeMessageLocationScreen, arguments: {
                  "isEdit": widget.isEdit,
                  "mainImage": _pickImage.pickedFile,
                }).then((value) {
                  if (value == "refresh") {
                    Navigator.pop(context, "refresh");
                  }
                });
              }
            },
            height: 48,
            fontSize: context.font.large,
            buttonTitle: "next".translate(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  widget.isEdit ? "editYourMessage".translate(context) : "createYourMessage".translate(context),
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w600,
                  color: context.color.textColorDark,
                ),
                const SizedBox(height: 16),
                CustomText("item".translate(context)),
                const SizedBox(height: 10),
                isLoadingItems
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<ItemModel>(
                  value: selectedItem,
                  hint: Text("selectItem".translate(context)),
                  items: items.map((item) {
                    return DropdownMenuItem<ItemModel>(
                      value: item,
                      child: CustomText(item.name ?? "Item ${item.id}"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedItem = value;
                    });
                  },
                  validator: validateItem,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.color.textLightColor.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withOpacity(0.35)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withOpacity(0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.color.territoryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("marqueeMessage".translate(context)),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: messageController,
                  validator: CustomTextFieldValidator.nullCheck,
                  action: TextInputAction.next,
                  capitalization: TextCapitalization.sentences,
                  hintText: "messageHere".translate(context),
                  hintTextStyle: TextStyle(
                    color: context.color.textLightColor.withOpacity(0.5),
                    fontSize: context.font.large,
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("displayOrder".translate(context)),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: displayOrderController,
                  action: TextInputAction.next,
                  keyboard: TextInputType.number,
                  formaters: [FilteringTextInputFormatter.digitsOnly],
                  validator: CustomTextFieldValidator.number,
                  hintText: "displayOrderHint".translate(context),
                  hintTextStyle: TextStyle(
                    color: context.color.textLightColor.withOpacity(0.5),
                    fontSize: context.font.large,
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("startDate".translate(context)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    print("Start date tapped"); // Debug print
                    FocusScope.of(context).unfocus(); // Prevent keyboard
                    try {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      ).then((pickedDate) {
                        if (pickedDate != null && mounted) {
                          print("Start date selected: $pickedDate"); // Debug print
                          setState(() {
                            startDateController.text = pickedDate.toIso8601String().substring(0, 10);
                          });
                        } else {
                          print("Start date picker cancelled"); // Debug print
                        }
                      });
                    } catch (e) {
                      print("Error opening start date picker: $e"); // Debug print
                      HelperUtils.showSnackBarMessage(context, "failedToOpenDatePicker".translate(context));
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextFormField(
                      controller: startDateController,
                      action: TextInputAction.next,
                      validator: CustomTextFieldValidator.date,
                      hintText: "YYYY-MM-DD",
                      hintTextStyle: TextStyle(
                        color: context.color.textLightColor.withOpacity(0.5),
                        fontSize: context.font.large,
                      ),
                      isReadOnly: true,
                      keyboard: TextInputType.none, // Prevent keyboard
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("endDate".translate(context)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    print("End date tapped"); // Debug print
                    FocusScope.of(context).unfocus(); // Prevent keyboard
                    try {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      ).then((pickedDate) {
                        if (pickedDate != null && mounted) {
                          print("End date selected: $pickedDate"); // Debug print
                          setState(() {
                            endDateController.text = pickedDate.toIso8601String().substring(0, 10);
                          });
                        } else {
                          print("End date picker cancelled"); // Debug print
                        }
                      });
                    } catch (e) {
                      print("Error opening end date picker: $e"); // Debug print
                      HelperUtils.showSnackBarMessage(context, "failedToOpenDatePicker".translate(context));
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextFormField(
                      controller: endDateController,
                      action: TextInputAction.done,
                      validator: CustomTextFieldValidator.date,
                      hintText: "YYYY-MM-DD",
                      hintTextStyle: TextStyle(
                        color: context.color.textLightColor.withOpacity(0.5),
                        fontSize: context.font.large,
                      ),
                      isReadOnly: true,
                      keyboard: TextInputType.none, // Prevent keyboard
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("status".translate(context)),
                const SizedBox(height: 10),
                DropdownButtonFormField<bool>(
                  value: isActive,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: CustomText("active".translate(context)),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: CustomText("inactive".translate(context)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      isActive = value ?? true;
                    });
                  },
                  validator: validateStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.color.textLightColor.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withOpacity(0.35)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withOpacity(0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.color.territoryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText("mainPicture".translate(context)),
                CustomText(
                  "recommendedSize".translate(context),
                  fontStyle: FontStyle.italic,
                  fontSize: context.font.small,
                  color: context.color.textLightColor.withOpacity(0.4),
                ),
                const SizedBox(height: 10),
                imageListener(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}