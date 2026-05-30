import 'package:flutter/material.dart';

const double desktopBreakpoint = 600;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= desktopBreakpoint;
