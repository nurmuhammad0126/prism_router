import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'path_codec.dart';

class PrismRouteInformationParser
    extends RouteInformationParser<List<PrismPage>> {
  const PrismRouteInformationParser({
    required this.routeBuilders,
    required this.initialPages,
  });

  final Map<String, PrismRouteDefinition> routeBuilders;
  final List<PrismPage> initialPages;

  @override
  Future<List<PrismPage>> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    var uri = routeInformation.uri;

    // On web, always use hash routing to avoid server path conflicts
    // Completely ignore server paths and only use fragments
    if (kIsWeb) {
      // Always read from browser URL fragment, ignore server paths
      try {
        // ignore: avoid_web_libraries_in_flutter
        final location = Uri.base;
        final hash = location.fragment;

        if (hash.isNotEmpty) {
          // Use fragment from browser URL (hash routing)
          var fragment = hash;
          // Remove leading # if present (fragment already contains it)
          if (fragment.startsWith('#')) {
            fragment = fragment.substring(1);
          }
          // Ensure it starts with '/'
          if (!fragment.startsWith('/')) {
            fragment = '/$fragment';
          }
          uri = Uri(path: '/', fragment: fragment);
        } else {
          // No hash in URL, use initial pages
          // This ensures we always use hash routing, never server paths
          return initialPages;
        }
      } on Object {
        // Ignore errors when reading browser hash, fall back to initial pages
        return initialPages;
      }
    }

    final encodedSegments = decodeUri(uri);

    if (encodedSegments.isEmpty) {
      return initialPages;
    }

    final pages = <PrismPage>[];
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
  RouteInformation? restoreRouteInformation(List<PrismPage> configuration) {
    final location = encodeLocation(configuration);
    final normalizedLocation =
        location.startsWith('/') ? location : '/$location';

    if (kIsWeb) {
      // Use hash-based routing to avoid conflicts with server paths
      // RouteInformation(location:) on web with hash routing should use just the path
      // Flutter Router will handle adding the # prefix
      // However, to ensure server paths are completely ignored, we also need to
      // manually replace browser history when navigation happens (done in controller)
      // NOTE: Using deprecated 'location' parameter is necessary for web reload
      // functionality. Without it, browser refresh causes navigation to fail.
      // The 'uri' parameter alone doesn't properly handle hash routing on reload.
      // ignore: deprecated_member_use
      return RouteInformation(location: normalizedLocation);
    }

    return RouteInformation(uri: Uri.parse(normalizedLocation));
  }
}
