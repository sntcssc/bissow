import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/main_activity.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessMarqueeMessageScreen extends StatefulWidget {
  final MarqueeMessageModel model;
  final bool isEdit;

  const SuccessMarqueeMessageScreen({
    super.key,
    required this.model,
    required this.isEdit,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return MaterialPageRoute(
      builder: (context) => SuccessMarqueeMessageScreen(
        model: arguments?['model'] as MarqueeMessageModel,
        isEdit: arguments?['isEdit'] ?? false,
      ),
    );
  }

  @override
  _SuccessMarqueeMessageScreenState createState() => _SuccessMarqueeMessageScreenState();
}

class _SuccessMarqueeMessageScreenState extends State<SuccessMarqueeMessageScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSuccessShown = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isBack = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _isLoading = false;
      _isSuccessShown = true;
    }

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.isEdit ? 0 : 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Simulate loading time
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show success animation after loading completes
        Future.delayed(const Duration(seconds: 0), () {
          if (mounted) {
            setState(() {
              _isSuccessShown = true;
              Future.delayed(const Duration(seconds: 1), () {
                _slideController.forward();
              });
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleBackButtonPressed() {
    if (_isSuccessShown && _slideController.isAnimating) {
      setState(() {
        isBack = false;
      });
      return;
    } else {
      _navigateBackToHome();
      return;
    }
  }

  void _navigateToMessageDetailsScreen() {
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushNamed(
      context,
      Routes.marqueeMessageDetailsScreen,
      arguments: {
        'model': widget.model,
      },
    );
  }

  void _navigateBackToHome() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          MainActivity.globalKey.currentState?.onItemTapped(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isBack,
      onPopInvokedWithResult: (didPop, result) async {
        _handleBackButtonPressed();
      },
      child: Scaffold(
        body: Center(
          child: _isLoading
              ? Lottie.asset(
            "assets/lottie/${Constant.loadingSuccessLottieFile}",
          )
              : _isSuccessShown
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/lottie/${Constant.successItemLottieFile}",
                repeat: false,
              ),
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    if (!widget.isEdit)
                      CustomText(
                        'congratulations'.translate(context),
                        fontSize: context.font.extraLarge,
                        fontWeight: FontWeight.w600,
                        color: context.color.territoryColor,
                      ),
                    const SizedBox(height: 18),
                    CustomText(
                      widget.isEdit
                          ? 'messageUpdatedSuccessfully'.translate(context)
                          : 'messagePostedSuccessfully'.translate(context),
                      color: context.color.textDefaultColor,
                      fontSize: context.font.larger,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    InkWell(
                      onTap: () {
                        _navigateToMessageDetailsScreen();
                      },
                      child: Container(
                        height: 48,
                        alignment: AlignmentDirectional.center,
                        margin: const EdgeInsets.symmetric(horizontal: 65, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.color.territoryColor),
                          color: context.color.secondaryColor,
                        ),
                        child: CustomText(
                          "viewMessage".translate(context),
                          textAlign: TextAlign.center,
                          fontSize: context.font.larger,
                          color: context.color.territoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        _navigateBackToHome();
                      },
                      child: CustomText(
                        'backToHome'.translate(context),
                        textAlign: TextAlign.center,
                        fontSize: context.font.larger,
                        color: context.color.textDefaultColor,
                        showUnderline: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : const SizedBox(),
        ),
      ),
    );
  }
}