import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_marquee_messages_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MarqueeMessagesWidget extends StatelessWidget {
  const MarqueeMessagesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllMarqueeMessagesCubit, FetchHomeAllMarqueeMessagesState>(
      builder: (context, state) {
        if (state is FetchHomeAllMarqueeMessagesInProgress) {
          return shimmerEffect();
        }
        if (state is FetchHomeAllMarqueeMessagesSuccess) {
          if (state.messages.isEmpty) {
            if (kDebugMode) {
              print('MarqueeMessagesWidget: No messages found');
            }
            return Center(
              child: NoDataFound(
                mainMessage: "noMarqueeMessagesFound".translate(context),
                subMessage: "noMessagesAvailableInThisLocation".translate(context),
                onTap: () {
                  context.read<FetchHomeAllMarqueeMessagesCubit>().fetch(
                    city: HiveUtils.getCityName(),
                    country: HiveUtils.getCountryName(),
                    state: HiveUtils.getStateName(),
                    radius: HiveUtils.getNearbyRadius()?.toDouble(),
                    longitude: HiveUtils.getLongitude(),
                    latitude: HiveUtils.getLatitude(),
                    sortBy: 'display_order',
                    postedSince: 'all-time',
                  );
                },
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 18,
                  bottom: 12,
                  start: sidePadding,
                  end: sidePadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "marqueeMessages".translate(context),
                        style: TextStyle(
                          fontSize: context.font.large,
                          fontWeight: FontWeight.w600,
                          color: context.color.textDefaultColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, Routes.marqueeMessagesScreen);
                      },
                      child: Text(
                        "seeAll".translate(context),
                        style: TextStyle(
                          fontSize: context.font.small,
                          color: context.color.territoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GridListAdapter(
                type: ListUiType.List,
                height: MediaQuery.of(context).size.height / 3.2,
                listAxis: Axis.horizontal,
                listSeparator: (BuildContext _, int __) => const SizedBox(width: 14),
                builder: (context, int index, bool _) {
                  MarqueeMessageModel message = state.messages[index];
                  return MarqueeMessageCard(message: message);
                },
                total: state.messages.length > 5 ? 5 : state.messages.length,
              ),
            ],
          );
        }
        if (state is FetchHomeAllMarqueeMessagesFail) {
          if (kDebugMode) {
            print('MarqueeMessagesWidget error: ${state.error}');
          }
          if (state.error is ApiException && (state.error as ApiException).errorMessage == "no-internet") {
            return Center(
              child: NoInternet(
                onRetry: () {
                  context.read<FetchHomeAllMarqueeMessagesCubit>().fetch(
                    city: HiveUtils.getCityName(),
                    country: HiveUtils.getCountryName(),
                    state: HiveUtils.getStateName(),
                    radius: HiveUtils.getNearbyRadius()?.toDouble(),
                    longitude: HiveUtils.getLongitude(),
                    latitude: HiveUtils.getLatitude(),
                    sortBy: 'display_order',
                    postedSince: 'all-time',
                  );
                },
              ),
            );
          }
          return const Center(child: SomethingWentWrong());
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CustomShimmer(height: 90, width: 90),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      CustomShimmer(
                        height: 10,
                        width: constraints.maxWidth - 50,
                      ),
                      const SizedBox(height: 10),
                      const CustomShimmer(height: 10),
                      const SizedBox(height: 10),
                      CustomShimmer(
                        height: 10,
                        width: constraints.maxWidth / 1.2,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MarqueeMessageCard extends StatelessWidget {
  final MarqueeMessageModel message;

  const MarqueeMessageCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode);
    return GestureDetector(
      onTap: () {
        // Navigate to a marquee message details screen if needed
        // Navigator.pushNamed(context, Routes.marqueeMessageDetailsScreen, arguments: {"messageId": message.id});
      },
      child: Container(
        width: 192,
        decoration: BoxDecoration(
          border: Border.all(
            color: context.color.textLightColor.withValues(alpha: 0.13),
            width: 1,
          ),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: message.image != null && message.image!.isNotEmpty
                  ? UiUtils.getImage(
                message.image!,
                height: MediaQuery.sizeOf(context).height / 5.45,
                width: double.infinity,
                fit: BoxFit.cover,
                // placeholder: Icons.message,
              )
                  : Container(
                height: MediaQuery.sizeOf(context).height / 5.45,
                width: double.infinity,
                color: context.color.textLightColor.withValues(alpha: 0.2),
                child: const Icon(Icons.message, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message ?? "No message",
                    style: TextStyle(
                      fontSize: context.font.normal,
                      fontWeight: FontWeight.w500,
                      color: context.color.textDefaultColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        message.isActive == true ? Icons.check_circle : Icons.cancel,
                        size: 13,
                        color: message.isActive == true
                            ? context.color.territoryColor
                            : context.color.textLightColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        message.isActive == true ? "active".translate(context) : "inactive".translate(context),
                        style: TextStyle(
                          fontSize: context.font.smaller,
                          color: context.color.textDefaultColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (message.startDate != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      "${"starts".translate(context)}: ${dateFormat.format(message.startDate!)}",
                      style: TextStyle(
                        fontSize: context.font.smaller,
                        color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}