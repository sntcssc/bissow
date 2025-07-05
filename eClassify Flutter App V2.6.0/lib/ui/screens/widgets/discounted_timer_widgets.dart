import 'dart:async';

import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// New Discount Timer Widget : whole widget added by Subhankar 2025.04.01
class DiscountTimer extends StatefulWidget {
  final String endDate;

  const DiscountTimer({super.key, required this.endDate});

  @override
  _DiscountTimerState createState() => _DiscountTimerState();
}

class _DiscountTimerState extends State<DiscountTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final endDate = DateTime.parse(widget.endDate);
    final now = DateTime.now();
    setState(() {
      _remainingTime = endDate.isAfter(now) ? endDate.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime.inSeconds <= 0) {
      return const SizedBox.shrink();
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = _remainingTime.inDays;
    final hours = twoDigits(_remainingTime.inHours.remainder(24));
    final minutes = twoDigits(_remainingTime.inMinutes.remainder(60));
    final seconds = twoDigits(_remainingTime.inSeconds.remainder(60));

    return Row(
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: Colors.red.withOpacity(0.8),
        ),
        const SizedBox(width: 4),
        CustomText(
          "Ends in ${days}d ${hours}h ${minutes}m ${seconds}s",
          fontSize: context.font.small,
          color: Colors.red.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}