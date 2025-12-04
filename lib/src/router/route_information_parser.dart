import 'dart:developer';

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
    Uri uri = routeInformation.uri;

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
          log('Read hash from browser: "$hash" -> fragment="$fragment"');
        }
      } on Object catch (e) {
        log('Error reading browser hash: $e');
      }
    }

    // Debug: log what we're receiving
    log(
      'parseRouteInformation: path="${uri.path}", fragment="${uri.fragment}", '
      'pathSegments=${uri.pathSegments}, fullUri="${uri.toString()}"',
    );

    final encodedSegments = decodeUri(uri);

    log('decoded segments: ${encodedSegments.map((s) => s.name).toList()}');

    if (encodedSegments.isEmpty) {
      log(
        'No segments found, returning initialPages: ${initialPages.map((p) => p.name).toList()}',
      );
      return initialPages;
    }

    final pages = <ElixirPage>[];
    for (final segment in encodedSegments) {
      final definition = routeBuilders[segment.name];
      if (definition == null) {
        // If any route is not found, fall back to initial pages
        log(
          'Route definition not found for: ${segment.name}, returning initialPages',
        );
        return initialPages;
      }
      pages.add(definition.builder(segment.arguments));
    }

    log('Successfully parsed pages: ${pages.map((p) => p.name).toList()}');
    return pages;
  }

  @override
  RouteInformation? restoreRouteInformation(List<ElixirPage> configuration) {
    final location = encodeLocation(configuration);
    final normalizedLocation =
        location.startsWith('/') ? location : '/$location';

    if (kIsWeb) {
      log(
        'restoreRouteInformation: location=$location, normalized=$normalizedLocation',
      );
      return RouteInformation(location: normalizedLocation);
    }

    return RouteInformation(uri: Uri.parse(normalizedLocation));
  }
}
