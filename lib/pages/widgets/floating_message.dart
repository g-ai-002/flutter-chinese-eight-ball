import 'package:flutter/material.dart';

/// 浮层提示：不改变主界面布局，新提示会替换尚未消失的旧提示。
void showFloatingMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
