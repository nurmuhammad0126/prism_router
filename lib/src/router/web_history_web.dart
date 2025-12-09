import 'package:web/web.dart' as web;

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
  web.window.history.replaceState(null, '', hashUrl);
}

// Clear all browser history and set new entry for pushAndRemoveAll
void clearAndSetBrowserHistory(String url) {
  // Prepare hash URL - url comes as "/home" format
  String hashUrl;
  if (url.startsWith('#')) {
    hashUrl = url.replaceFirst(RegExp(r'^#+'), '#');
  } else {
    hashUrl = '#$url';
  }

  // CRITICAL: Strategy to completely clear ALL browser history
  //
  // Problem: location.replace() only replaces current entry, doesn't clear previous entries
  // Solution: Navigate back to first entry using history.go(), then replace it
  //
  // How it works:
  // 1. Navigate back to the first entry in history (this removes intermediate entries)
  // 2. Replace that first entry with our new URL
  // 3. This effectively clears all history and leaves only our new URL
  //
  // Example:
  // Before: [/home, /home/profile, /home/profile/details] -> history.length = 3
  // Step 1: history.go(-2) -> navigates back to /home (removes /profile and /details from stack)
  // Step 2: replaceState('#/home') -> replaces /home with #/home
  // After: [#/home] -> history.length = 1 (back button exits app)

  try {
    final historyLength = web.window.history.length;

    if (historyLength > 1) {
      // Calculate how far back we need to go (to the first entry)
      final stepsBack = historyLength - 1;

      // Step 1: Navigate back to the first entry
      // This removes all intermediate entries from the navigation stack
      // Note: This will trigger a pop_state event, but we handle it
      web.window.history.go(-stepsBack);

      // Step 2: After a brief delay, replace the first entry
      // We use a small delay to ensure navigation completes
      Future.delayed(const Duration(milliseconds: 50), () {
        // Replace the first entry with our new URL
        web.window.history.replaceState(null, '', hashUrl);
      });
    } else {
      // Only one entry exists, just replace it
      web.window.history.replaceState(null, '', hashUrl);
    }
  } on Object catch (_) {
    // Fallback: Use location.replace() if history manipulation fails
    // This causes a page reload but is the most reliable method
    final currentOrigin = web.window.location.origin;
    final currentPath = web.window.location.pathname;
    final newUrl = '$currentOrigin$currentPath$hashUrl';
    web.window.location.replace(newUrl);
  }
}
