import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/marquee/delete_marquee_message_cubit.dart';
import 'package:eClassify/data/cubits/marquee/fetch_my_marquee_messages_cubit.dart';
import 'package:eClassify/data/cubits/marquee/manage_marquee_message_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/seller/qr_code_scanner_screen.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

Map<String, FetchMyMarqueeMessagesCubit> myMarqueeMessagesCubitReference = {};

class MyMarqueeMessageTab extends StatefulWidget {
  final String? getMessagesWithStatus;

  const MyMarqueeMessageTab({super.key, this.getMessagesWithStatus});

  @override
  CloudState<MyMarqueeMessageTab> createState() => _MyMarqueeMessageTabState();
}

class _MyMarqueeMessageTabState extends CloudState<MyMarqueeMessageTab> {
  late final ScrollController _pageScrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    if (HiveUtils.isUserAuthenticated()) {
      context.read<FetchMyMarqueeMessagesCubit>().fetchMyMarqueeMessages(status: widget.getMessagesWithStatus);
      _pageScrollController.addListener(_pageScroll);
      setReferenceOfCubit();
    }
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchMyMarqueeMessagesCubit>().hasMoreData()) {
        context.read<FetchMyMarqueeMessagesCubit>().fetchMyMoreMarqueeMessages(status: widget.getMessagesWithStatus);
      }
    }
  }

  void setReferenceOfCubit() {
    myMarqueeMessagesCubitReference[widget.getMessagesWithStatus ?? "all"] =
        context.read<FetchMyMarqueeMessagesCubit>();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10 + defaultPadding, horizontal: defaultPadding),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: context.color.secondaryColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CustomShimmer(height: 90, width: 90),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    CustomShimmer(height: 10, width: context.screenWidth * 0.5),
                    const SizedBox(height: 10),
                    CustomShimmer(height: 10, width: context.screenWidth * 0.6),
                    const SizedBox(height: 10),
                    CustomShimmer(height: 10, width: context.screenWidth * 0.4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget showStatus(MarqueeMessageModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: _getStatusColor(model.isActive),
      ),
      child: CustomText(
        model.isActive == true ? "active".translate(context) : "inactive".translate(context),
        fontSize: context.font.small,
        color: _getStatusTextColor(model.isActive),
      ),
    );
  }

  Color _getStatusColor(bool? isActive) {
    return isActive == true
        ? context.color.territoryColor.withOpacity(0.2)
        : context.color.deactivateColor.withOpacity(0.2);
  }

  Color _getStatusTextColor(bool? isActive) {
    return isActive == true ? context.color.territoryColor : context.color.deactivateColor;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeleteMarqueeMessageCubit, DeleteMarqueeMessageState>(
          listener: (context, state) {
            if (state is DeleteMarqueeMessageSuccess) {
              HelperUtils.showSnackBarMessage(context, "messageDeleted".translate(context));
              myMarqueeMessagesCubitReference.forEach((key, cubit) {
                cubit.fetchMyMarqueeMessages(status: key == "all" ? null : key);
              });
            } else if (state is DeleteMarqueeMessageFailure) {
              HelperUtils.showSnackBarMessage(context, state.errorMessage);
            }
          },
        ),
        BlocListener<ManageMarqueeMessageCubit, ManageMarqueeMessageState>(
          listener: (context, state) {
            if (state is ManageMarqueeMessageSuccess) {
              HelperUtils.showSnackBarMessage(context, "statusUpdated".translate(context));
              myMarqueeMessagesCubitReference.forEach((key, cubit) {
                cubit.fetchMyMarqueeMessages(status: key == "all" ? null : key);
              });
            } else if (state is ManageMarqueeMessageFail) {
              HelperUtils.showSnackBarMessage(context, state.error.toString());
            }
          },
        ),
      ],
      child: BlocBuilder<FetchMyMarqueeMessagesCubit, FetchMyMarqueeMessagesState>(
        builder: (context, state) {
          if (state is FetchMyMarqueeMessagesInProgress) {
            return shimmerEffect();
          }

          if (state is FetchMyMarqueeMessagesFailed) {
            if (state.error is ApiException && state.error.error == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchMyMarqueeMessagesCubit>().fetchMyMarqueeMessages(status: widget.getMessagesWithStatus);
                },
              );
            }
            return const SomethingWentWrong();
          }

          if (state is FetchMyMarqueeMessagesSuccess) {
            if (state.messages.isEmpty) {
              return NoDataFound(
                mainMessage: "noMessagesFound".translate(context),
                subMessage: "noMessagesAvailable".translate(context),
                onTap: () {
                  context.read<FetchMyMarqueeMessagesCubit>().fetchMyMarqueeMessages(status: widget.getMessagesWithStatus);
                },
              );
            }

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    triggerMode: RefreshIndicatorTriggerMode.anywhere,
                    onRefresh: () async {
                      context.read<FetchMyMarqueeMessagesCubit>().fetchMyMarqueeMessages(status: widget.getMessagesWithStatus);
                      setReferenceOfCubit();
                    },
                    color: context.color.territoryColor,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      controller: _pageScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: sidePadding, vertical: 8),
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        MarqueeMessageModel message = state.messages[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.marqueeMessageDetailsScreen, arguments: {
                              "model": message,
                            }).then((value) {
                              if (value == "refresh") {
                                myMarqueeMessagesCubitReference.forEach((key, cubit) {
                                  cubit.fetchMyMarqueeMessages(status: key == "all" ? null : key);
                                });
                              }
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: message.isActive == false
                                    ? context.color.deactivateColor.withOpacity(0.1)
                                    : context.color.secondaryColor,
                                border: Border.all(
                                  color: context.color.textLightColor.withOpacity(0.18),
                                  width: 1,
                                ),
                              ),
                              width: double.infinity,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: SizedBox(
                                      width: 116,
                                      height: double.infinity,
                                      child: UiUtils.getImage(
                                        message.image ?? "",
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              showStatus(message),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: context.color.territoryColor),
                                                    onPressed: () {
                                                      Navigator.pushNamed(context, Routes.addMarqueeMessageDetails, arguments: {
                                                        "isEdit": true,
                                                        "message": message,
                                                      }).then((value) {
                                                        if (value == "refresh") {
                                                          myMarqueeMessagesCubitReference.forEach((key, cubit) {
                                                            cubit.fetchMyMarqueeMessages(status: key == "all" ? null : key);
                                                          });
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: context.color.error),
                                                    onPressed: () {
                                                      UiUtils.showBlurredDialoge(
                                                        context,
                                                        dialoge: BlurredDialogBox(
                                                          title: "confirmDelete".translate(context),
                                                          content: CustomText("deleteMessageConfirmation".translate(context)),
                                                          acceptButtonName: "delete".translate(context),
                                                          onAccept: () async {
                                                            await context.read<DeleteMarqueeMessageCubit>().deleteMarqueeMessage(message.id!);
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      message.isActive == true ? Icons.toggle_on : Icons.toggle_off,
                                                      color: message.isActive == true
                                                          ? context.color.territoryColor
                                                          : context.color.textLightColor,
                                                    ),
                                                    onPressed: () {
                                                      context.read<ManageMarqueeMessageCubit>().manage(
                                                        ManageMarqueeMessageType.edit,
                                                        {
                                                          "id": message.id,
                                                          "is_active": message.isActive! ^ true,
                                                          "message": message.message,
                                                          "display_order": message.displayOrder,
                                                          "start_date": message.startDate?.toIso8601String(),
                                                          "end_date": message.endDate?.toIso8601String(),
                                                          "latitude": message.latitude,
                                                          "longitude": message.longitude,
                                                          "city": message.city,
                                                          "country": message.country,
                                                          "user_id": HiveUtils.getUserId(),
                                                          "item_id": message.itemId,
                                                        },
                                                        null,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              message.message ?? "",
                                              maxLines: 3, // Limit to 3 lines to prevent overflow
                                              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                              firstUpperCaseWidget: true,
                                              fontSize: context.font.normal,
                                              fontWeight: FontWeight.w600,
                                              softWrap: true, // Enable text wrapping
                                            ),
                                          ),
                                          CustomText(
                                            "${message.city ?? ''}, ${message.country ?? ''}",
                                            fontSize: context.font.small,
                                            color: context.color.textColorDark.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: state.messages.length,
                    ),
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}