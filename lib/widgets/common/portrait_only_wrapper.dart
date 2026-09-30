import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PortraitOnlyWrapper extends StatefulWidget {
  final Widget child;

  const PortraitOnlyWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PortraitOnlyWrapper> createState() => _PortraitOnlyWrapperState();
}

class _PortraitOnlyWrapperState extends State<PortraitOnlyWrapper> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}