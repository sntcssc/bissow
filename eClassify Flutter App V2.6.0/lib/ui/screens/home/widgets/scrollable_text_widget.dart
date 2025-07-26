import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_marquee_messages_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/not_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee_list/marquee_list.dart';
import 'package:marquee/marquee.dart';

class ScrollableTextWidget extends StatelessWidget {
  const ScrollableTextWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllMarqueeMessagesCubit, FetchHomeAllMarqueeMessagesState>(
      builder: (context, state) {
        if (state is FetchHomeAllMarqueeMessagesInProgress) {
          return shimmerEffect(context);
        }
        if (state is FetchHomeAllMarqueeMessagesSuccess) {
          if (state.messages.isEmpty) {
            if (kDebugMode) {
              print('ScrollableTextWidget: No messages found');
            }
            return Center(
              child: NotFound(
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
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: sidePadding, vertical: 12),
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.color.territoryColor.withOpacity(0.95),
                  context.color.territoryColor.withOpacity(0.65),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.color.textLightColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.color.shadow.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: context.color.textDefaultColor,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Latest: ",
                        style: TextStyle(
                          fontSize: context.font.larger,
                          fontWeight: FontWeight.w700,
                          color: context.color.textDefaultColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MarqueeList(
                    scrollDirection: Axis.horizontal,
                    scrollDuration: const Duration(seconds: 4),
                    // reverse: false,
                    children: state.messages.map((message) {
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routes.marqueeMessageDetailsScreen,
                            arguments: {"model": message},
                          );
                        },
                        splashColor: context.color.territoryColor.withOpacity(0.3),
                        highlightColor: context.color.territoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            message.message ?? "No message",
                            style: TextStyle(
                              fontSize: context.font.normal,
                              fontWeight: FontWeight.w500,
                              color: context.color.textDefaultColor.withOpacity(0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is FetchHomeAllMarqueeMessagesFail) {
          if (kDebugMode) {
            print('ScrollableTextWidget error: ${state.error}');
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

  Widget shimmerEffect(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: sidePadding, vertical: 12),
      height: 64,
      decoration: BoxDecoration(
        color: context.color.textLightColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CustomShimmer(),
    );
  }
}