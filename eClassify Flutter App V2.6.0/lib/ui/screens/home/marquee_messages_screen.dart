import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_marquee_messages_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MarqueeMessagesScreen extends StatefulWidget {
  const MarqueeMessagesScreen({Key? key}) : super(key: key);

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const MarqueeMessagesScreen(),
    );
  }

  @override
  _MarqueeMessagesScreenState createState() => _MarqueeMessagesScreenState();
}

class _MarqueeMessagesScreenState extends State<MarqueeMessagesScreen> {
  late ScrollController _controller = ScrollController()
    ..addListener(() {
      if (_controller.offset >= _controller.position.maxScrollExtent &&
          !_controller.position.outOfRange &&
          context.read<FetchHomeAllMarqueeMessagesCubit>().hasMoreData()) {
        context.read<FetchHomeAllMarqueeMessagesCubit>().fetchMore(
          city: HiveUtils.getCityName(),
          country: HiveUtils.getCountryName(),
          state: HiveUtils.getStateName(),
          radius: HiveUtils.getNearbyRadius()?.toDouble(),
          longitude: HiveUtils.getLongitude(),
          latitude: HiveUtils.getLatitude(),
          sortBy: 'display_order',
          postedSince: 'all-time',
        );
      }
    });

  @override
  void initState() {
    super.initState();
    getAllMarqueeMessages();
  }

  void getAllMarqueeMessages() {
    final params = {
      'city': HiveUtils.getCityName(),
      'country': HiveUtils.getCountryName(),
      'state': HiveUtils.getStateName(),
      'radius': HiveUtils.getNearbyRadius()?.toDouble(),
      'longitude': HiveUtils.getLongitude(),
      'latitude': HiveUtils.getLatitude(),
      'sortBy': 'display_order',
      'postedSince': 'all-time',
    };
    if (kDebugMode) {
      print('Fetching marquee messages with params: $params');
    }
    context.read<FetchHomeAllMarqueeMessagesCubit>().fetch(
      city: params['city'],
      country: params['country'],
      state: params['state'],
      radius: params['radius'],
      longitude: params['longitude'],
      latitude: params['latitude'],
      sortBy: params['sortBy'],
      postedSince: params['postedSince'],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          getAllMarqueeMessages();
        },
        color: context.color.territoryColor,
        child: Scaffold(
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: "marqueeMessages".translate(context),
          ),
          body: BlocBuilder<FetchHomeAllMarqueeMessagesCubit, FetchHomeAllMarqueeMessagesState>(
            builder: (context, state) {
              if (state is FetchHomeAllMarqueeMessagesInProgress) {
                return shimmerEffect();
              } else if (state is FetchHomeAllMarqueeMessagesSuccess) {
                if (state.messages.isEmpty) {
                  if (kDebugMode) {
                    print('MarqueeMessagesScreen: No messages found');
                  }
                  return Center(
                    child: NoDataFound(
                      onTap: getAllMarqueeMessages,
                      mainMessage: "noMarqueeMessagesFound".translate(context),
                      subMessage: "noMessagesAvailableInThisLocation".translate(context),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _controller,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.messages.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          MarqueeMessageModel message = state.messages[index];
                          return InkWell(
                            onTap: () {
                              // Navigate to a marquee message details screen if needed
                              // Navigator.pushNamed(
                              //   context,
                              //   Routes.marqueeMessageDetailsScreen,
                              //   arguments: {"messageId": message.id},
                              // );
                            },
                            child: MarqueeMessageHorizontalCard(message: message),
                          );
                        },
                      ),
                    ),
                    if (state.isLoadingMore)
                      UiUtils.progress(
                        normalProgressColor: context.color.territoryColor,
                      ),
                  ],
                );
              } else if (state is FetchHomeAllMarqueeMessagesFail) {
                if (kDebugMode) {
                  print('MarqueeMessagesScreen error: ${state.error}');
                }
                if (state.error is ApiException &&
                    (state.error as ApiException).errorMessage == "no-internet") {
                  return NoInternet(onRetry: getAllMarqueeMessages);
                }
                return Center(
                  child: SomethingWentWrong(
                    // onRetry: getAllMarqueeMessages,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
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

class MarqueeMessageHorizontalCard extends StatelessWidget {
  final MarqueeMessageModel message;

  const MarqueeMessageHorizontalCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Container(
        height: 124,
        decoration: BoxDecoration(
          border: Border.all(
            color: context.color.textLightColor.withValues(alpha: 0.28),
          ),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: message.image != null && message.image!.isNotEmpty
                  ? UiUtils.getImage(
                message.image!,
                height: 122,
                width: 108,
                fit: BoxFit.cover,
                // placeholder: Icons.message,
              )
                  : Container(
                height: 122,
                width: 108,
                color: context.color.textLightColor.withValues(alpha: 0.2),
                child: const Icon(Icons.message, size: 40),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 12,
                  end: 12,
                  top: 8,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      message.message ?? "No message",
                      style: TextStyle(
                        fontSize: context.font.normal,
                        color: context.color.textDefaultColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          message.isActive == true ? Icons.check_circle : Icons.cancel,
                          size: 15,
                          color: message.isActive == true
                              ? context.color.territoryColor
                              : context.color.textLightColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          message.isActive == true ? "active".translate(context) : "inactive".translate(context),
                          style: TextStyle(
                            fontSize: context.font.smaller,
                            color: context.color.textDefaultColor.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (message.createdAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: context.color.textDefaultColor.withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(start: 2.0),
                              child: Text(
                                UiUtils.convertToAgo(
                                  context: context,
                                  setDate: DateFormat('yyyy-MM-dd HH:mm').format(message.createdAt!),
                                ),
                                style: TextStyle(
                                  fontSize: context.font.smaller,
                                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}