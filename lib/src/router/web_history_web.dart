// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Web-specific implementation for replacing browser history
void replaceBrowserHistory(String url) {
  // Ensure URL uses hash routing format (#/path) to avoid server path conflicts
  // The url parameter comes from encodeLocation which returns "/home" format
  // We need to add # prefix for browser history API
  // This replaces the ENTIRE URL path with hash routing, ignoring any server paths
  // Clean any existing # to prevent double ##
  String hashUrl;
  if (url.startsWith('#')) {
    // Already has #, but might have double ##, so clean it to single #
    hashUrl = url.replaceFirst(RegExp(r'^#+'), '#');
  } else {
    // Add # prefix for hash routing
    // This ensures we use hash routing and ignore any server paths like /home
    hashUrl = '#$url';
  }
  // Replace the entire URL with hash routing, this removes any server paths
  // For example: http://localhost:60384/home becomes http://localhost:60384/#/home
  html.window.history.replaceState(null, '', hashUrl);
}
