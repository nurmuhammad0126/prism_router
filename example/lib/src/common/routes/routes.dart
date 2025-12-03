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

  @override
  Set<String> get tags => {'home'};
}

final class SettingsPage extends AppPage {
  SettingsPage({required final String data})
    : super(child: SettingsScreen(data: data), name: 'settings');

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);

  @override
  Set<String> get tags => {'settings'};
}

final class ProfilePage extends AppPage {
  const ProfilePage() : super(name: 'profile', child: const ProfileScreen());

  @override
  Set<String> get tags => {'profile'};
}

final class DetailsPage extends AppPage {
  DetailsPage({required this.userId, required this.note})
    : super(
        name: 'details',
        child: DetailsScreen(userId: userId, note: note),
        arguments: {'userId': userId, 'note': note},
      );

  final String userId;
  final String note;

  @override
  Set<String> get tags => {'details'};
}
