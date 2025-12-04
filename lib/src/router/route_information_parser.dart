import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../navigator/elixir_page.dart';
import '../navigator/types.dart';
import 'path_codec.dart';

class ElixirRouteInformationParser
    extends RouteInformationParser<List<ElixirPage>> {
  const ElixirRouteInformationParser({
    required this.routeBuilders,
    required this.initialPages,
  });

  final Map<String, ElixirRouteDefinition> routeBuilders;
  final List<ElixirPage> initialPages;

  @override
  Future<List<ElixirPage>> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    var uri = routeInformation.uri;

    // On web, if fragment is empty but we're using hash routing,
    // try to read directly from browser URL
    if (kIsWeb && uri.fragment.isEmpty && uri.pathSegments.isEmpty) {
      try {
        // ignore: avoid_web_libraries_in_flutter
        final location = Uri.base;
        final hash = location.fragment;
        if (hash.isNotEmpty) {
          // Reconstruct URI with fragment from browser
          var fragment = hash;
          if (fragment.startsWith('#')) {
            fragment = fragment.substring(1);
          }
          if (!fragment.startsWith('/')) {
            fragment = '/$fragment';
          }
          uri = Uri(path: '/', fragment: fragment);
        }
      } on Object {
        // Ignore errors when reading browser hash
      }
    }

    final encodedSegments = decodeUri(uri);

    if (encodedSegments.isEmpty) {
      return initialPages;
    }

    final pages = <ElixirPage>[];
    for (final segment in encodedSegments) {
      final definition = routeBuilders[segment.name];
      if (definition == null) {
        // If any route is not found, fall back to initial pages
        return initialPages;
      }
      pages.add(definition.builder(segment.arguments));
    }

    return pages;
  }

  @override
  RouteInformation? restoreRouteInformation(List<ElixirPage> configuration) {
    final location = encodeLocation(configuration);
    final normalizedLocation =
        location.startsWith('/') ? location : '/$location';

    if (kIsWeb) {
      // NOTE: Using deprecated 'location' parameter is necessary for web reload
      // functionality. Without it, browser refresh causes navigation to fail.
      // The 'uri' parameter alone doesn't properly handle hash routing on reload.
      // ignore: deprecated_member_use
      return RouteInformation(location: normalizedLocation);
    }

    return RouteInformation(uri: Uri.parse(normalizedLocation));
  }
}
