import 'package:flutter/material.dart';

import '../router/controller.dart';
import '../router/scope.dart';

extension ElixirContextExtension on BuildContext {
  ElixirController get elixir => ElixirScope.of(this, listen: false);
}
