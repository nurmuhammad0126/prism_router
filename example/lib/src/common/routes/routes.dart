import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

import '../../feature/details/details_screen.dart';
import '../../feature/home/home_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/settings/settings_screen.dart';
import 'custom_route_transitions.dart';

final pages = [
  const HomePage(),
  SettingsPage(data: ''),
  const ProfilePage(),
  DetailsPage(userId: '', note: ''),
];

@immutable
sealed class AppPage extends PrismPage {
  const AppPage({
    required super.name,
    required super.child,
    super.arguments,
    super.tags,
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
  PrismPage pageBuilder(Map<String, Object?> _) => const HomePage();
}

final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
    : super(
        child: SettingsScreen(data: data),
        name: 'settings',
        tags: {'settings'},
        arguments: {'data': data},
      );

  final String data;

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) {
    // Pattern matching - type-safe, no cast needed, IDE autocomplete works!
    if (arguments case {'data': String data}) {
      return SettingsPage(data: data);
    }
    // Fallback if pattern doesn't match
    return SettingsPage(data: arguments['data'] as String? ?? '');
  }

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);
}

final class ProfilePage extends AppPage {
  const ProfilePage() : super(name: 'profile', child: const ProfileScreen());

  @override
  PrismPage pageBuilder(Map<String, Object?> _) => const ProfilePage();
}

final class DetailsPage extends AppPage {
  DetailsPage({required this.userId, required this.note})
    : super(
        name: 'details',
        tags: {'details'}, // Tags from super!
        child: DetailsScreen(userId: userId, note: note),
        arguments: {'userId': userId, 'note': note},
      );

  final String userId;
  final String note;

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) {
    // Pattern matching - type-safe, no cast needed, IDE autocomplete works!
    if (arguments case {'userId': String userId, 'note': String note}) {
      return DetailsPage(userId: userId, note: note);
    }
    // Fallback if pattern doesn't match
    return DetailsPage(
      userId: arguments['userId'] as String? ?? '',
      note: arguments['note'] as String? ?? '',
    );
  }
}
