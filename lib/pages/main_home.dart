import 'package:flutter/material.dart';
import '../widgets/home/home_root.dart';

class MainHome extends StatelessWidget {
  final bool wsOk;
  final int rttMs;

  const MainHome({
    super.key,
    required this.wsOk,
    required this.rttMs,
  });

  @override
  Widget build(BuildContext context) {
    return HomeRoot(wsOk: wsOk, rttMs: rttMs);
  }
}
