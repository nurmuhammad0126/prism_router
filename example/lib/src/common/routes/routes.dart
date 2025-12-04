import 'package:elixir/elixir.dart';
import 'package:flutter/material.dart';

import '../../feature/details/details_screen.dart';
import '../../feature/home/home_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/settings/settings_screen.dart';
import 'custom_route_transitions.dart';

/// Type definition for the page.
@immutable
sealed class AppPage extends ElixirPage {
  const AppPage({
    required super.name,
    required super.child,
    super.arguments,
    super.key,
  });

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppPage && key == other.key;

  @override
  String toString() => '/$name${arguments.isEmpty ? '' : '~$arguments'}';
}

final class HomePage extends AppPage {
  const HomePage() : super(child: const HomeScreen(), name: 'home');

  factory HomePage.fromArguments(Map<String, Object?> _) => const HomePage();

  @override
  Set<String> get tags => {'home'};

  static const route = ElixirRouteDefinition(
    name: 'home',
    builder: HomePage.fromArguments,
  );
}

final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
    : super(
        child: SettingsScreen(data: data),
        name: 'settings',
        arguments: {'data': data},
      );

  factory SettingsPage.fromArguments(Map<String, Object?> arguments) =>
      SettingsPage(data: arguments['data'] as String? ?? '');

  final String data;

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);

  @override
  Set<String> get tags => {'settings'};

  static const route = ElixirRouteDefinition(
    name: 'settings',
    builder: SettingsPage.fromArguments,
  );
}

final class ProfilePage extends AppPage {
  const ProfilePage() : super(name: 'profile', child: const ProfileScreen());

  factory ProfilePage.fromArguments(Map<String, Object?> _) =>
      const ProfilePage();

  @override
  Set<String> get tags => {'profile'};

  static const route = ElixirRouteDefinition(
    name: 'profile',
    builder: ProfilePage.fromArguments,
  );
}

final class DetailsPage extends AppPage {
  DetailsPage({required this.userId, required this.note})
    : super(
        name: 'details',
        child: DetailsScreen(userId: userId, note: note),
        arguments: {'userId': userId, 'note': note},
      );

  factory DetailsPage.fromArguments(Map<String, Object?> arguments) =>
      DetailsPage(
        userId: arguments['userId'] as String? ?? '',
        note: arguments['note'] as String? ?? '',
      );

  final String userId;
  final String note;

  @override
  Set<String> get tags => {'details'};

  static const route = ElixirRouteDefinition(
    name: 'details',
    builder: DetailsPage.fromArguments,
  );
}

abstract final class AppRoutes {
  static const definitions = [
    HomePage.route,
    SettingsPage.route,
    ProfilePage.route,
    DetailsPage.route,
  ];
}
