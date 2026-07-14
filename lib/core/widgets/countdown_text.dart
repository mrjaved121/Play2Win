import 'dart:async';

import 'package:flutter/material.dart';

/// Text that ticks down every second from [duration] to zero, formatted
/// `mm:ss` (or `hh:mm:ss` past an hour). Used for the limited-offer
/// ticker and the daily-bonus reset timer.
class CountdownText extends StatefulWidget {
  const CountdownText({
    required this.duration,
    required this.style,
    this.onComplete,
    super.key,
  });

  final Duration duration;
  final TextStyle style;
  final VoidCallback? onComplete;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Duration _remaining = widget.duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (!mounted) return;
    if (_remaining.inSeconds <= 0) {
      timer.cancel();
      widget.onComplete?.call();
      return;
    }
    setState(() => _remaining -= const Duration(seconds: 1));
  }

  String _format(Duration d) {
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_format(_remaining), style: widget.style);
  }
}
