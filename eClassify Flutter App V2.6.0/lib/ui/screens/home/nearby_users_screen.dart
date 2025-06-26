import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_nearby_users_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/user_model.dart';
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

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({Key? key}) : super(key: key);

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const NearbyUsersScreen(),
    );
  }

  @override
  _NearbyUsersScreenState createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  late ScrollController _controller = ScrollController()
    ..addListener(() {
      if (_controller.offset >= _controller.position.maxScrollExtent &&
          !_controller.position.outOfRange &&
          context.read<FetchNearbyUsersCubit>().hasMoreData()) {
        context.read<FetchNearbyUsersCubit>().fetchMore(
          city: HiveUtils.getCityName(),
          country: HiveUtils.getCountryName(),
          state: HiveUtils.getStateName(),
          radius: HiveUtils.getNearbyRadius(),
          longitude: HiveUtils.getLongitude(),
          latitude: HiveUtils.getLatitude(),
        );
      }
    });

  @override
  void initState() {
    super.initState();
    getAllUsers();
  }

  void getAllUsers() {
    final params = {
      'city': HiveUtils.getCityName(),
      'country': HiveUtils.getCountryName(),
      'state': HiveUtils.getStateName(),
      'radius': HiveUtils.getNearbyRadius(),
      'longitude': HiveUtils.getLongitude(),
      'latitude': HiveUtils.getLatitude(),
    };
    if (kDebugMode) {
      print('Fetching nearby users with params: $params');
    }
    context.read<FetchNearbyUsersCubit>().fetch(
      city: params['city'],
      country: params['country'],
      state: params['state'],
      radius: params['radius'],
      longitude: params['longitude'],
      latitude: params['latitude'],
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
          getAllUsers();
        },
        color: context.color.territoryColor,
        child: Scaffold(
          appBar: UiUtils.buildAppBar(context,
              showBackButton: true, title: "nearbyUsers".translate(context)),
          body: BlocBuilder<FetchNearbyUsersCubit, FetchNearbyUsersState>(
            builder: (context, state) {
              if (state is FetchNearbyUsersInProgress) {
                return shimmerEffect();
              } else if (state is FetchNearbyUsersSuccess) {
                if (state.users.isEmpty) {
                  if (kDebugMode) {
                    print('NearbyUsersScreen: No users found');
                  }
                  return Center(
                    child: NoDataFound(
                      onTap: getAllUsers,
                      mainMessage: "noUsersFound".translate(context),
                      subMessage:
                      "noUsersAvailableInThisLocation".translate(context),
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
                        itemCount: state.users.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          UserModel user = state.users[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.sellerProfileScreen,
                                arguments: {"sellerId": user.id},
                              );
                            },
                            child: UserHorizontalCard(user: user),
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
              } else if (state is FetchNearbyUsersFail) {
                if (kDebugMode) {
                  print('NearbyUsersScreen error: ${state.error}');
                }
                if (state.error is ApiException &&
                    (state.error as ApiException).errorMessage == "no-internet") {
                  return NoInternet(onRetry: getAllUsers);
                }
                return Center(
                  child: SomethingWentWrong(
                    // onRetry: getAllUsers,
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

class UserHorizontalCard extends StatelessWidget {
  final UserModel user;

  const UserHorizontalCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15)),
              child: UiUtils.getImage(
                user.profile ?? "",
                height: 122,
                width: 108,
                fit: BoxFit.cover,
                // placeholder: Icons.person,
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
                      user.name ?? "Unknown User",
                      style: TextStyle(
                        fontSize: context.font.normal,
                        color: context.color.textDefaultColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.address != null && user.address!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: context.color.textDefaultColor
                                .withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsetsDirectional.only(start: 2.0),
                              child: Text(
                                user.address!.trim(),
                                style: TextStyle(
                                  fontSize: context.font.smaller,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (user.createdAt != null && user.createdAt!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: context.color.textDefaultColor
                                .withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsetsDirectional.only(start: 2.0),
                              child: Text(
                                UiUtils.convertToAgo(
                                    context: context, setDate: user.createdAt!),
                                style: TextStyle(
                                  fontSize: context.font.smaller,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.5),
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