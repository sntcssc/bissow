import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class NotFound extends StatelessWidget {
  final double? height;
  final String? mainMessage;
  final String? subMessage;
  final VoidCallback? onTap;
  final double? mainMsgStyle;
  final double? subMsgStyle;
  final bool? showImage;

  const NotFound(
      {super.key,
        this.onTap,
        this.height,
        this.mainMessage,
        this.subMessage,
        this.mainMsgStyle,
        this.subMsgStyle, this.showImage});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CustomText(
              //   mainMessage ?? "nodatafound".translate(context),
              //   fontSize: mainMsgStyle ?? context.font.smaller,
              //   color: context.color.territoryColor,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
