import 'package:elixir/elixir.dart';
import 'package:flutter/material.dart';

import '../../common/routes/routes.dart';

/// {@template details_screen}
/// Light-weight screen that showcases reading data passed through the page.
/// {@endtemplate}
class DetailsScreen extends StatelessWidget {
  /// {@macro details_screen}
  const DetailsScreen({required this.userId, required this.note, super.key});

  final String userId;
  final String note;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Details'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: context.elixir.pop,
      ),
      actions: [
        IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.home),
          onPressed: () => context.elixir.change((state) => [const HomePage()]),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User ID: $userId',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('Note: $note'),
        ],
      ),
    ),
  );
}
