import 'dart:async';
import 'package:flutter/material.dart';
import 'src/common/widget/app.dart';

void main() => runZonedGuarded<void>(
  () => runApp(const App()),
  (error, stackTrace) => log('Top level exception: $error'),
);
