import 'package:flutter/material.dart';

abstract final class RadioMotion {
  static const quick = Duration(milliseconds: 160);
  static const player = Duration(milliseconds: 280);
  static const ease = Cubic(.23, 1, .32, 1);
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Duration duration(BuildContext context, [Duration value = quick]) =>
      reduced(context) ? Duration.zero : value;
}
