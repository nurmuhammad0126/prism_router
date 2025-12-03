import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'browser_history_sync_stub.dart'
    if (dart.library.html) 'browser_history_sync_web.dart';
import 'elixir_page.dart';
import 'history_constants.dart';
import 'observer.dart';
import 'types.dart';

/// {@template navigator}
/// AppNavigator widget.
/// {@endtemplate}
class Elixir extends StatefulWidget {
  /// {@macro navigator}
  Elixir({
    required this.pages,
    this.guards = const [],
    this.observers = const [],
    this.transitionDelegate = const DefaultTransitionDelegate<Object?>(),
    this.revalidate,
    this.onBackButtonPressed,
    this.routes = const [],
    this.routeDecoder,
    super.key,
  }) : assert(pages.isNotEmpty, 'pages cannot be empty'),
       controller = null;

  /// {@macro navigator}
  Elixir.controlled({
    required ValueNotifier<ElixirNavigationState> this.controller,
    this.guards = const [],
    this.observers = const [],
    this.transitionDelegate = const DefaultTransitionDelegate<Object?>(),
    this.revalidate,
    this.onBackButtonPressed,
    this.routes = const [],
    this.routeDecoder,
    super.key,
  }) : assert(controller.value.isNotEmpty, 'controller cannot be empty'),
       pages = controller.value;

  /// The [AppNavigatorState] from the closest instance of this class
  /// that encloses the given context, if any.
  static ElixirState? maybeOf(BuildContext context, {bool listen = false}) =>
      _InheritedElixir.maybeOf(context, listen: listen)?.state;

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `ElixirState.of(context)`
  static ElixirState of(BuildContext context, {bool listen = false}) =>
      _InheritedElixir.of(context, listen: listen).state;

  /// The navigation state from the closest instance of this class
  /// that encloses the given context, if any.
  static ElixirNavigationState? stateOf(
    BuildContext context, {
    bool listen = false,
  }) => maybeOf(context, listen: listen)?.state;

  /// The navigator from the closest instance of this class
  /// that encloses the given context, if any.
  static NavigatorState? navigatorOf(
    BuildContext context, {
    bool listen = false,
  }) => maybeOf(context, listen: listen)?.navigator;

  /// Initial pages to display.
  final ElixirNavigationState pages;

  /// The controller to use for the navigator.
  final ValueNotifier<ElixirNavigationState>? controller;

  /// Guards to apply to the pages.
  final ElixirGuard guards;

  /// Observers to attach to the navigator.
  final List<NavigatorObserver> observers;

  /// The transition delegate to use for the navigator.
  final TransitionDelegate<Object?> transitionDelegate;

  /// Revalidate the pages.
  final Listenable? revalidate;

  /// The callback function that will be called when the back button is pressed.
  ///
  /// It must return a boolean with true if this navigator will handle the request;
  /// otherwise, return a boolean with false.
  ///
  /// Also you can mutate the [AppNavigationState] to change the navigation stack.
  final ({ElixirNavigationState state, bool handled}) Function(
    ElixirNavigationState state,
  )?
  onBackButtonPressed;

  /// Optional static route definitions. When provided, Elixir can persist the
  /// navigation stack across browser refreshes by re-instantiating pages.
  final List<ElixirRouteDefinition> routes;

  /// Optional callback that rebuilds a page stack from a browser location/state
  /// pair. Provide this if you want hard refreshes on Flutter web to restore
  /// the previous navigation stack.
  final ElixirRouteDecoder? routeDecoder;

  @override
  State<Elixir> createState() => ElixirState();
}

/// State for widget AppNavigator.
class ElixirState extends State<Elixir> with WidgetsBindingObserver {
  /// The current [Navigator] state (null if not yet built).
  NavigatorState? get navigator => _navigatorObserver.navigator;
  final NavigatorObserver _navigatorObserver = NavigatorObserver();

  /// The custom observer.
  late final ElixirObserver$NavigatorImpl _observer;
  ElixirStateObserver get observer => _observer;

  /// The current pages list.
  ElixirNavigationState get state => _state;

  late ElixirNavigationState _state;
  List<NavigatorObserver> _observers = const [];

  // Browser history integration (web only).
  BrowserHistorySync? _browserHistorySync;
  final Map<String, ElixirNavigationState> _browserSnapshots =
      <String, ElixirNavigationState>{};
  final Map<String, ElixirNavigationState> _browserSnapshotsByLocation =
      <String, ElixirNavigationState>{};
  final Map<String, String> _browserLocationsByKey = <String, String>{};
  final Queue<String> _browserSnapshotOrder = Queue<String>();
  bool _isReplayingBrowserHistory = false;
  String? _currentBrowserSnapshotKey;
  String? _lastSyncedLocation;
  int _browserSnapshotSeed = 0;
  Map<String, ElixirRouteDefinition> _routeBuilders =
      <String, ElixirRouteDefinition>{};

  static const int _maxBrowserSnapshots = 256;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    _routeBuilders = {for (final route in widget.routes) route.name: route};
    _browserHistorySync = _createBrowserHistorySync();
    _state = _tryRestoreInitialState() ?? widget.pages;
    widget.revalidate?.addListener(revalidate);

    _observer = ElixirObserver$NavigatorImpl(_state);

    _observers = <NavigatorObserver>[_navigatorObserver, ...widget.observers];
    widget.controller?.addListener(_controllerListener);
    _controllerListener();
    WidgetsBinding.instance.addObserver(this);
    _initializeBrowserHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    revalidate();
  }

  @override
  void didUpdateWidget(covariant Elixir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.revalidate, oldWidget.revalidate)) {
      oldWidget.revalidate?.removeListener(revalidate);
      widget.revalidate?.addListener(revalidate);
    }
    if (!listEquals(widget.routes, oldWidget.routes)) {
      _routeBuilders = {for (final route in widget.routes) route.name: route};
    }
    if (!identical(widget.observers, oldWidget.observers)) {
      _observers = <NavigatorObserver>[_navigatorObserver, ...widget.observers];
    }
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?.removeListener(_controllerListener);
      widget.controller?.addListener(_controllerListener);
      _controllerListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_controllerListener);
    widget.revalidate?.removeListener(revalidate);
    _browserHistorySync?.dispose();
    super.dispose();
  }
  /* #endregion */

  /// Add a page to the stack.
  void push(ElixirPage page) => change((state) => [...state, page]);

  /// Pop the last page from the stack.
  void pop() => change((state) {
    if (state.isNotEmpty) state.removeLast();
    return state;
  });

  /// Clear the pages to the initial state.
  void reset(ElixirPage page) => change((_) => widget.pages);

  @override
  Future<bool> didPopRoute() {
    // If the back button handler is defined, call it.
    final backButtonHandler = widget.onBackButtonPressed;
    if (backButtonHandler != null) {
      final result = backButtonHandler(_state.toList());
      change((pages) => result.state);
      return SynchronousFuture(result.handled);
    }

    // Otherwise, handle the back button press with the default behavior.
    if (_state.length < 2) return SynchronousFuture(false);
    _onDidRemovePage(_state.last);
    return SynchronousFuture(true);
  }

  void _setStateToController() {
    if (widget.controller
        case ValueNotifier<ElixirNavigationState> controller) {
      controller
        ..removeListener(_controllerListener)
        ..value = _state
        ..addListener(_controllerListener);
    }

    _observer.changeState((_) => _state);
  }

  void _controllerListener() {
    final controller = widget.controller;
    if (controller == null || !mounted) return;
    final newValue = controller.value;
    if (identical(newValue, _state)) return;
    final ctx = context;
    final next = widget.guards.fold(newValue.toList(), (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) {
      _setStateToController(); // Revert the controller value.
    } else {
      _state = UnmodifiableListView<ElixirPage>(next);
      _notifyStateChanged();
    }
  }

  /// Revalidate the pages.
  void revalidate() {
    if (!mounted) return;
    final ctx = context;
    final next = widget.guards.fold(_state.toList(), (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) return;
    _state = UnmodifiableListView<ElixirPage>(next);
    _notifyStateChanged();
  }

  /// Change the pages.
  void change(ElixirNavigationState Function(ElixirNavigationState pages) fn) {
    final prev = _state.toList();
    var next = fn(prev);
    if (next.isEmpty) return;
    if (!mounted) return;
    final ctx = context;
    next = widget.guards.fold(next, (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) return;
    _state = UnmodifiableListView<ElixirPage>(next);
    _notifyStateChanged();
  }

  /// Called when a page is removed from the stack.
  void _onDidRemovePage(ElixirPage page) {
    change((pages) => pages..removeWhere((p) => p.key == page.key));
  }

  void _notifyStateChanged() {
    _setStateToController();
    _syncBrowserHistory();
    if (mounted) setState(() {});
  }

  ElixirNavigationState? _tryRestoreInitialState() {
    final sync = _browserHistorySync;
    final decoder = widget.routeDecoder;
    if (sync == null) return null;
    final payload = sync.readInitialPayload();
    if (payload == null) return null;
    ElixirNavigationState? decoded;
    if (payload.snapshot != null) {
      decoded = _decodeSnapshot(payload.snapshot!);
    }
    if (decoded == null && decoder != null) {
      decoded = decoder(payload.location, payload.stateKey);
    }
    if (decoded == null || decoded.isEmpty) return null;
    final ctx = context;
    final guarded = widget.guards.fold(decoded.toList(), (s, g) => g(ctx, s));
    if (guarded.isEmpty) return null;
    final normalized = _locationFromState(guarded);
    final snapshot = UnmodifiableListView<ElixirPage>(guarded);
    final key = _storeBrowserSnapshot(
      snapshot,
      location: normalized,
      key: payload.stateKey,
    );
    _currentBrowserSnapshotKey = key;
    _lastSyncedLocation = normalized;
    return snapshot;
  }

  void _initializeBrowserHistory() {
    final sync = _browserHistorySync;
    if (sync == null) return;
    final location = _lastSyncedLocation ?? _locationFromState(_state);
    final snapshotKey =
        _currentBrowserSnapshotKey ??
        _storeBrowserSnapshot(_state, location: location);
    _currentBrowserSnapshotKey = snapshotKey;
    _lastSyncedLocation = location;
    sync.initialize(stateKey: snapshotKey, location: location);
  }

  BrowserHistorySync? _createBrowserHistorySync() =>
      kIsWeb ? const BrowserHistorySync() : null;

  void _syncBrowserHistory() {
    final location = _locationFromState(_state);
    final historySync = _browserHistorySync;
    if (historySync == null || _isReplayingBrowserHistory) {
      _browserSnapshotsByLocation[location] = _state;
      return;
    }
    if (location == _lastSyncedLocation && _currentBrowserSnapshotKey != null) {
      return;
    }
    final snapshotKey = _storeBrowserSnapshot(_state, location: location);
    _currentBrowserSnapshotKey = snapshotKey;
    _lastSyncedLocation = location;
    historySync.update(location: location, stateKey: snapshotKey);
  }

  String _locationFromState(ElixirNavigationState state) {
    if (state.isEmpty) return '/';
    final segments = state
        .map((page) => page.name.trim())
        .where((name) => name.isNotEmpty)
        .map(Uri.encodeComponent)
        .toList(growable: false);
    if (segments.isEmpty) return '/';
    return '/${segments.join('/')}';
  }

  String _storeBrowserSnapshot(
    ElixirNavigationState state, {
    required String location,
    String? key,
  }) {
    final snapshotKey =
        key ??
        '${DateTime.now().microsecondsSinceEpoch}-${_browserSnapshotSeed++}';
    final snapshot = List<ElixirPage>.unmodifiable(state.toList());
    _browserSnapshots[snapshotKey] = snapshot;
    _browserSnapshotsByLocation[location] = snapshot;
    _browserLocationsByKey[snapshotKey] = location;
    _browserSnapshotOrder.addLast(snapshotKey);
    if (_browserSnapshotOrder.length > _maxBrowserSnapshots) {
      final oldest = _browserSnapshotOrder.removeFirst();
      _browserSnapshots.remove(oldest);
      final oldestLocation = _browserLocationsByKey.remove(oldest);
      if (oldestLocation != null) {
        _browserSnapshotsByLocation.remove(oldestLocation);
      }
    }
    _persistSnapshotForKey(snapshotKey, snapshot);
    return snapshotKey;
  }

  bool _applySnapshotFromHistory(String? stateKey, {String? location}) {
    if (stateKey == null && location == null) return false;
    var snapshot = stateKey != null ? _browserSnapshots[stateKey] : null;
    if (snapshot == null && stateKey != null) {
      final persisted = _browserHistorySync?.snapshotFor(stateKey);
      if (persisted != null) {
        snapshot = _decodeSnapshot(persisted);
        if (snapshot != null) {
          _browserSnapshots[stateKey] = snapshot;
        }
      }
    }
    snapshot ??=
        location != null ? _browserSnapshotsByLocation[location] : null;
    if (snapshot == null) return false;
    _isReplayingBrowserHistory = true;
    _state = UnmodifiableListView<ElixirPage>(snapshot);
    var resolvedKey = stateKey;
    if (resolvedKey == null && location != null) {
      for (final entry in _browserLocationsByKey.entries) {
        if (entry.value == location) {
          resolvedKey = entry.key;
          break;
        }
      }
    }
    if (resolvedKey != null && resolvedKey.isNotEmpty) {
      _currentBrowserSnapshotKey = resolvedKey;
    }
    _lastSyncedLocation = location ?? _locationFromState(_state);
    _notifyStateChanged();
    _isReplayingBrowserHistory = false;
    return true;
  }

  void _persistSnapshotForKey(String key, ElixirNavigationState state) {
    final sync = _browserHistorySync;
    if (sync == null) return;
    final encoded = _encodeSnapshot(state);
    if (encoded == null) return;
    sync.persistSnapshot(key, encoded);
  }

  String? _encodeSnapshot(ElixirNavigationState state) {
    if (_routeBuilders.isEmpty) return null;
    final payload = state
        .map(
          (page) => <String, Object?>{
            'name': page.name,
            'arguments': page.arguments,
          },
        )
        .toList(growable: false);
    return jsonEncode(payload);
  }

  ElixirNavigationState? _decodeSnapshot(String encoded) {
    if (_routeBuilders.isEmpty) return null;
    final dynamic data = jsonDecode(encoded);
    if (data is! List) return null;
    final pages = <ElixirPage>[];
    for (final entry in data) {
      if (entry is! Map) return null;
      final name = entry['name'];
      if (name is! String) return null;
      final definition = _routeBuilders[name];
      if (definition == null) return null;
      final rawArgs = entry['arguments'];
      final args =
          rawArgs is Map
              ? rawArgs.map<String, Object?>(
                (key, value) => MapEntry(key.toString(), value),
              )
              : const <String, Object?>{};
      pages.add(definition.builder(args));
    }
    return pages;
  }

  String? _stateKeyFromRouteInformation(RouteInformation routeInformation) {
    final state = routeInformation.state;
    if (state is Map && state[kElixirHistoryStateKey] is String) {
      return state[kElixirHistoryStateKey] as String;
    }
    return null;
  }

  String _locationFromRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    if (!uri.hasScheme && uri.path.isEmpty) return '/';
    return uri.toString();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    final handled = _applySnapshotFromHistory(
      _stateKeyFromRouteInformation(routeInformation),
      location: _locationFromRouteInformation(routeInformation),
    );
    if (handled) return SynchronousFuture<bool>(true);
    return super.didPushRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) => _InheritedElixir(
    state: this,
    child: Navigator(
      pages: _state,
      reportsRouteUpdateToEngine: false,
      restorationScopeId: 'elixir_navigator',
      transitionDelegate: widget.transitionDelegate,
      onDidRemovePage: (page) => _onDidRemovePage(page as ElixirPage),
      observers: _observers,
    ),
  );
}

/// Inherited widget for quick access in the element tree.
class _InheritedElixir extends InheritedWidget {
  const _InheritedElixir({required this.state, required super.child});

  final ElixirState state;

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// For example: `Elixir.maybeOf(context)`.
  static _InheritedElixir? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) =>
      listen
          ? context.dependOnInheritedWidgetOfExactType<_InheritedElixir>()
          : context.getInheritedWidgetOfExactType<_InheritedElixir>();

  static Never _notFoundInheritedWidgetOfExactType() =>
      throw ArgumentError(
        'Out of scope, not found inherited widget '
            'a _InheritedElixir of the exact type',
        'out_of_scope',
      );

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// For example: `Elixir.of(context)`.
  static _InheritedElixir of(BuildContext context, {bool listen = true}) =>
      maybeOf(context, listen: listen) ?? _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(covariant _InheritedElixir oldWidget) => false;
}
