import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_nearby_users_cubit.dart';
import 'package:eClassify/data/helper/designs.dart';
import 'package:eClassify/data/model/user_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/grid_list_adapter.dart';
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
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NearbyUsersWidget extends StatelessWidget {
  const NearbyUsersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchNearbyUsersCubit, FetchNearbyUsersState>(
      builder: (context, state) {
        if (state is FetchNearbyUsersInProgress) {
          return shimmerEffect();
        }
        if (state is FetchNearbyUsersSuccess) {
          if (state.users.isEmpty) {
            if (kDebugMode) {
              print('NearbyUsersWidget: No users found');
            }
            return Center(
              child: NotFound(
                mainMessage: "noUsersFound".translate(context),
                subMessage: "noUsersAvailableInThisLocation".translate(context),
                onTap: () {
                  context.read<FetchNearbyUsersCubit>().fetch(
                    city: HiveUtils.getCityName(),
                    country: HiveUtils.getCountryName(),
                    state: HiveUtils.getStateName(),
                    radius: HiveUtils.getNearbyRadius(),
                    longitude: HiveUtils.getLongitude(),
                    latitude: HiveUtils.getLatitude(),
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
                        "nearbyUsers".translate(context),
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
                        Navigator.pushNamed(context, Routes.nearbyUsersScreen);
                      },
                      child: Container(
                        // padding: Colors.purpleAccent,
                        child: Text(
                          "seeAll".translate(context),
                          style: TextStyle(
                            fontSize: context.font.small,
                            color: context.color.territoryColor,
                          ),
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
                listSeparator: (BuildContext _, int __) => const SizedBox(
                  width: 14,
                ),
                builder: (context, int index, bool _) {
                  UserModel user = state.users[index];
                  return UserCard(user: user);
                },
                total: state.users.length > 5 ? 5 : state.users.length,
              ),
            ],
          );
        }
        if (state is FetchNearbyUsersFail) {
          if (kDebugMode) {
            print('NearbyUsersWidget error: ${state.error}');
          }
          if (state.error is ApiException &&
              (state.error as ApiException).errorMessage == "no-internet") {
            return Center(
              child: NoInternet(
                onRetry: () {
                  context.read<FetchNearbyUsersCubit>().fetch(
                    city: HiveUtils.getCityName(),
                    country: HiveUtils.getCountryName(),
                    state: HiveUtils.getStateName(),
                    radius: HiveUtils.getNearbyRadius(),
                    longitude: HiveUtils.getLongitude(),
                    latitude: HiveUtils.getLatitude(),
                  );
                },
              ),
            );
          }
          return const Center(child: NoInternet());
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

class UserCard extends StatelessWidget {
  final UserModel user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.sellerProfileScreen,
            arguments: {"sellerId": user.id});
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
              child: UiUtils.getImage(
                user.profile ?? "",
                height: MediaQuery.sizeOf(context).height / 5.45,
                width: double.infinity,
                fit: BoxFit.cover,
                // placeholder: Icons.person,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? "Unknown User",
                    style: TextStyle(
                      fontSize: context.font.normal,
                      fontWeight: FontWeight.w500,
                      color: context.color.textDefaultColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.address != null && user.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: context.color.textDefaultColor
                              .withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 3.0),
                            child: Text(
                              user.address!,
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
          ],
        ),
      ),
    );
  }
}