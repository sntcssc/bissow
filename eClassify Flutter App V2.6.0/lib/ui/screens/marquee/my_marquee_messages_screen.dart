import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/marquee/fetch_my_marquee_messages_cubit.dart';
import 'package:eClassify/ui/screens/marquee/my_marquee_message_tab_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyMarqueeMessagesScreen extends StatefulWidget {
  const MyMarqueeMessagesScreen({super.key});

  @override
  State<MyMarqueeMessagesScreen> createState() => _MyMarqueeMessagesState();

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const MyMarqueeMessagesScreen(),
    );
  }
}

class _MyMarqueeMessagesState extends State<MyMarqueeMessagesScreen> with TickerProviderStateMixin {
  int selectTab = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    List<Map> sections = [
      {
        "title": "allMessages".translate(context),
        "status": "",
      },
      {
        "title": "active".translate(context),
        "status": "active",
      },
      {
        "title": "inactive".translate(context),
        "status": "inactive",
      },
      // {
      //   "title": "expired".translate(context),
      //   "status": "expired",
      // },
    ];

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
          title: "myMarqueeMessages".translate(context),
          bottomHeight: 49,
          bottom: [
            SizedBox(
              width: context.screenWidth,
              height: 45,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(18, 5, 18, 2),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  Map section = sections[index];
                  return customTab(
                    context,
                    isSelected: (selectTab == index),
                    onTap: () {
                      selectTab = index;
                      setState(() {});
                      _pageController.jumpToPage(index);
                    },
                    name: section['title'],
                    onDoubleTap: () {},
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 8);
                },
                itemCount: sections.length,
              ),
            ),
          ],
        ),
        body: ScrollConfiguration(
          behavior: RemoveGlow(),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              selectTab = value;
              setState(() {});
            },
            controller: _pageController,
            children: List.generate(sections.length, (index) {
              Map section = sections[index];
              return BlocProvider(
                create: (context) => FetchMyMarqueeMessagesCubit(),
                child: MyMarqueeMessageTab(
                  getMessagesWithStatus: section['status'],
                ),
              );
            }),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: context.color.territoryColor,
          onPressed: () {
            Navigator.pushNamed(context, Routes.addMarqueeMessageDetails, arguments: {
              "isEdit": false,
            }).then((value) {
              if (value == "refresh") {
                context.read<FetchMyMarqueeMessagesCubit>().fetchMyMarqueeMessages();
              }
            });
          },
          child: Icon(Icons.add, color: context.color.buttonColor),
        ),
      ),
    );
  }

  Widget customTab(
      BuildContext context, {
        required bool isSelected,
        required String name,
        required Function() onTap,
        required Function() onDoubleTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 110),
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? context.color.territoryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? context.color.territoryColor : context.color.textLightColor,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomText(
              name,
              color: isSelected ? context.color.buttonColor : context.color.textColorDark,
              fontSize: context.font.large,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}