import '../../elixir.dart';

/// Registry for automatically collecting pages.
///
/// Pages can register themselves automatically when instantiated.
/// This allows collecting all pages without manually listing them.
class ElixirPageRegistry {
  ElixirPageRegistry._();

  static final ElixirPageRegistry _instance = ElixirPageRegistry._();
  static ElixirPageRegistry get instance => _instance;

  final Set<ElixirPage> _pages = {};

  /// Registers a page instance.
  void register(ElixirPage page) {
    _pages.add(page);
  }

  /// Gets all registered pages.
  List<ElixirPage> get pages => _pages.toList();

  /// Clears the registry.
  void clear() => _pages.clear();

  /// Gets route definitions from registered pages.
  List<ElixirRouteDefinition> get routeDefinitions =>
      _pages.map((page) => page.routeDefinition).toList();
}
