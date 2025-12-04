# Elixir Navigation Package - Architecture Explanation

## Overview
Elixir is a Flutter navigation package built on top of Flutter's Navigator 2.0 API. It provides a declarative, type-safe way to manage navigation state using a stack-based approach where the navigation state is represented as a `List<ElixirPage>`.

## Core Architecture

### 1. **ElixirPage** - Base Page Class
```dart
abstract base class ElixirPage extends Page<void>
```

**Purpose**: Every screen in the app extends `ElixirPage`, which itself extends Flutter's `Page<void>`.

**Key Features**:
- Each page has a `name` (unique identifier like 'home', 'settings')
- Each page has a `child` widget (the actual screen widget)
- Each page has optional `arguments` (data passed to the page)
- Each page has `tags` (for filtering/identifying pages)
- Automatic key generation based on name + arguments hash

**Logic**: 
- When arguments are provided, the key is `ValueKey('$name#${shortHash(arguments)}')`
- This ensures pages with different arguments are treated as different pages
- The `createRoute()` method creates a `MaterialPageRoute` by default (can be overridden)

---

### 2. **ElixirController** - State Management Core

**Purpose**: Manages the navigation stack state and applies guards.

**State Storage**:
```dart
late UnmodifiableListView<ElixirPage> _state;  // Current navigation stack
final UnmodifiableListView<ElixirPage> _initialPages;  // Initial pages
```

**Key Methods**:

1. **`push(ElixirPage page)`**: Adds a page to the stack
   ```dart
   void push(ElixirPage page) => change((pages) => pages..add(page));
   ```

2. **`pop()`**: Removes the last page (if stack has >1 page)
   ```dart
   bool pop() {
     if (_state.length < 2) return false;
     change((pages) => pages..removeLast());
     return true;
   }
   ```

3. **`change(transform)`**: Applies a transformation function to the stack
   ```dart
   void change(List<ElixirPage> Function(List<ElixirPage> current) transform) {
     final next = transform(_state.toList());
     if (next.isEmpty) return;
     final guarded = _applyGuards(List<ElixirPage>.from(next));
     _setState(guarded);
   }
   ```

4. **`resetTo(List<ElixirPage> pages)`**: Replaces entire stack with new pages

**Guard System**:
```dart
List<ElixirPage> _applyGuards(List<ElixirPage> next) {
  if (next.isEmpty) return next;
  final ctx = _guardContext;
  if (ctx == null || _guards.isEmpty) return next;
  return _guards.fold<List<ElixirPage>>(next, (state, guard) {
    final guarded = guard(ctx, List<ElixirPage>.from(state));
    return guarded.isEmpty ? state : guarded;
  });
}
```

**Guard Logic**:
- Guards are functions that take `(BuildContext, List<ElixirPage>)` and return `List<ElixirPage>`
- Guards are applied in sequence using `fold()`
- Each guard can modify the navigation state (e.g., redirect to login if not authenticated)
- If a guard returns empty list, the previous state is kept

**State Updates**:
```dart
void _setState(List<ElixirPage> next, {bool force = false}) {
  final immutable = UnmodifiableListView<ElixirPage>(next);
  if (!force && listEquals(immutable, _state)) return;  // Skip if unchanged
  _state = immutable;
  _observer.changeState((_) => _state);  // Update observer
  notifyListeners();  // Notify RouterDelegate
}
```

---

### 3. **ElixirRouterDelegate** - Navigator 2.0 Bridge

**Purpose**: Implements `RouterDelegate<List<ElixirPage>>` to connect Flutter's Router with ElixirController.

**Key Responsibilities**:

1. **Build Navigator Widget**:
   ```dart
   @override
   Widget build(BuildContext context) => ElixirScope(
     controller: controller,
     child: Navigator(
       key: navigatorKey,
       pages: controller.state,  // Navigator uses controller's state
       onPopPage: (route, result) {
         final didPop = route.didPop(result);
         if (didPop) controller.pop();
         return didPop;
       },
     ),
   );
   ```

2. **Handle URL Changes from Browser**:
   ```dart
   @override
   Future<void> setNewRoutePath(List<ElixirPage> configuration) {
     controller.setFromRouter(configuration);  // Update controller from URL
     return SynchronousFuture<void>(null);
   }
   ```

3. **Handle Back Button**:
   ```dart
   @override
   Future<bool> popRoute() {
     if (controller.isAtInitialState) return SynchronousFuture<bool>(false);
     return SynchronousFuture<bool>(controller.pop());
   }
   ```

**Data Flow**:
- When controller state changes → `notifyListeners()` → RouterDelegate rebuilds Navigator
- When browser URL changes → Parser creates pages → `setNewRoutePath()` → Controller updates

---

### 4. **ElixirRouteInformationParser** - URL Parsing

**Purpose**: Converts browser URLs into `List<ElixirPage>` and vice versa.

**parseRouteInformation()** - URL → Pages:
```dart
Future<List<ElixirPage>> parseRouteInformation(RouteInformation routeInformation) async {
  Uri uri = routeInformation.uri;
  
  // On web, handle hash routing
  if (kIsWeb && uri.fragment.isEmpty && uri.pathSegments.isEmpty) {
    final location = Uri.base;
    final hash = location.fragment;
    if (hash.isNotEmpty) {
      // Extract path from hash: #/home/settings -> /home/settings
      var fragment = hash;
      if (fragment.startsWith('#')) fragment = fragment.substring(1);
      if (!fragment.startsWith('/')) fragment = '/$fragment';
      uri = Uri(path: '/', fragment: fragment);
    }
  }
  
  // Decode URI to segments: /home/settings -> [home, settings]
  final encodedSegments = decodeUri(uri);
  
  if (encodedSegments.isEmpty) {
    return initialPages;  // Fallback to initial pages
  }
  
  // Build pages from segments using route definitions
  final pages = <ElixirPage>[];
  for (final segment in encodedSegments) {
    final definition = routeBuilders[segment.name];
    if (definition == null) return initialPages;  // Unknown route
    pages.add(definition.builder(segment.arguments));
  }
  
  return pages;
}
```

**restoreRouteInformation()** - Pages → URL:
```dart
RouteInformation? restoreRouteInformation(List<ElixirPage> configuration) {
  final location = encodeLocation(configuration);  // /home/settings
  final normalizedLocation = location.startsWith('/') ? location : '/$location';
  
  if (kIsWeb) {
    // On web, use location (Flutter handles hash routing automatically)
    return RouteInformation(location: normalizedLocation);
  }
  
  return RouteInformation(uri: Uri.parse(normalizedLocation));
}
```

---

### 5. **Path Codec** - URL Encoding/Decoding

**encodeLocation()** - Pages → URL String:
```dart
String encodeLocation(List<ElixirPage> pages) {
  if (pages.isEmpty) return '/';
  // Only encode page names, not arguments (to keep URLs clean)
  // [HomePage, SettingsPage] -> "/home/settings"
  final segments = pages.map((page) => page.name).join('/');
  return '/$segments';
}
```

**decodeUri()** - URL → Segments:
```dart
List<EncodedRouteSegment> decodeUri(Uri uri) {
  List<String> segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  
  // Handle hash routing: #/home/settings
  if (segments.isEmpty && uri.fragment.isNotEmpty) {
    var fragment = uri.fragment;
    if (fragment.startsWith('#')) fragment = fragment.substring(1);
    if (!fragment.startsWith('/')) fragment = '/$fragment';
    
    try {
      final fragUri = Uri.parse(fragment);
      segments = fragUri.pathSegments.where((s) => s.isNotEmpty).toList();
    } on Object {
      segments = fragment.split('/').where((s) => s.isNotEmpty).toList();
    }
  }
  
  // Clean up segments (remove empty, trim, filter out stray '#')
  segments = segments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty && segment != '#')
      .toList();
  
  if (segments.isEmpty) return const [];
  return segments.map((name) => EncodedRouteSegment(name, const {})).toList();
}
```

**Note**: Arguments are NOT encoded in URLs. Only page names are stored. This means:
- URL: `/home/settings` (clean)
- Arguments are lost on refresh (but route hierarchy is preserved)

---

### 6. **Elixir.router()** - Setup Function

**Purpose**: Creates and configures all router components.

```dart
static RouterConfig<Object> router({
  required List<ElixirRouteDefinition> routes,
  required List<ElixirPage> initialStack,
  ElixirGuard guards = const [],
  ...
}) {
  // 1. Create controller (manages state)
  final controller = ElixirController(
    initialPages: initialStack,
    guards: guards,
  );
  
  // 2. Create route map for parsing
  final routeMap = {for (final route in routes) route.name: route};
  
  // 3. Create router delegate (connects to Navigator)
  final delegate = ElixirRouterDelegate(controller: controller, ...);
  
  // 4. Create parser (URL ↔ Pages)
  final parser = ElixirRouteInformationParser(
    routeBuilders: routeMap,
    initialPages: initialStack,
  );
  
  // 5. Create route information provider
  // On web: use actual browser URL (Uri.base) so refresh works
  // On mobile: use encoded initial location
  final initialRouteInformation = kIsWeb
      ? RouteInformation(uri: Uri.base)  // Read browser URL
      : RouteInformation(uri: Uri.parse(encodeLocation(initialStack)));
  
  final provider = PlatformRouteInformationProvider(
    initialRouteInformation: initialRouteInformation,
  );
  
  // 6. Return RouterConfig
  return RouterConfig<Object>(
    routerDelegate: delegate,
    routeInformationParser: parser,
    routeInformationProvider: provider,
    backButtonDispatcher: ElixirBackButtonDispatcher(controller),
  );
}
```

---

## Data Flow Diagram

```
User Action (push/pop)
    ↓
ElixirController.change()
    ↓
_applyGuards() → Guards modify state
    ↓
_setState() → Update _state
    ↓
notifyListeners() → RouterDelegate notified
    ↓
RouterDelegate.build() → Navigator rebuilds with new pages
    ↓
restoreRouteInformation() → Update browser URL
```

```
Browser URL Change (refresh/back button)
    ↓
PlatformRouteInformationProvider
    ↓
parseRouteInformation() → Decode URL to segments
    ↓
Build pages from route definitions
    ↓
setNewRoutePath() → Update controller
    ↓
Controller state updated → Navigator rebuilds
```

---

## Web-Specific Handling

### Hash Routing
- Flutter web uses hash routing by default: `http://localhost:1234/#/home/settings`
- The `#` is handled automatically by Flutter's Router
- We only encode the path part: `/home/settings`
- Flutter adds the `#` prefix automatically

### Refresh Handling
- On web, `PlatformRouteInformationProvider` is initialized with `Uri.base` (actual browser URL)
- This allows the parser to read the current URL on app start
- On refresh, the parser reads the hash from `Uri.base.fragment` and reconstructs the stack
- This is why refresh now works correctly

### Double Hash Fix
- Previously, code was manually adding `#/` prefix, causing `/#/#/home`
- Now we only return the path (`/home/settings`) and let Flutter handle the hash
- The decoder also filters out stray `'#'` segments

---

## Key Design Decisions

1. **Immutable State**: Navigation state is `UnmodifiableListView` - changes create new lists
2. **Declarative**: Navigation state is a list of pages, not imperative commands
3. **Type-Safe**: Pages are sealed classes, compile-time safety
4. **Guard System**: Functional guards that can transform state
5. **URL Clean**: Only page names in URLs, not arguments (simpler URLs)
6. **Platform Agnostic**: Same code works on mobile, web, desktop (with platform-specific URL handling)

---

## Example Usage Flow

1. **Setup**:
   ```dart
   final routerConfig = Elixir.router(
     routes: [HomePage.route, SettingsPage.route],
     initialStack: [const HomePage()],
     guards: [(context, state) => state.length > 1 ? state : [const HomePage()]],
   );
   ```

2. **Navigate**:
   ```dart
   context.elixir.push(SettingsPage(data: 'hello'));
   // Controller: [HomePage] → [HomePage, SettingsPage]
   // URL: /home → /home/settings
   ```

3. **Refresh**:
   - Browser URL: `/#/home/settings`
   - Parser reads hash: `#/home/settings`
   - Decodes to: `[home, settings]`
   - Builds pages: `[HomePage(), SettingsPage(data: '')]` (data lost, but route preserved)
   - Controller state restored

---

## Summary

Elixir provides a clean abstraction over Navigator 2.0 by:
- Representing navigation as a stack of pages (declarative)
- Managing state in a controller with guard support
- Automatically syncing with browser URLs (web)
- Providing type-safe page definitions
- Handling platform differences (web hash routing, mobile paths)

The architecture follows Flutter's Navigator 2.0 pattern but simplifies it with a stack-based state model and automatic URL synchronization.

