import '../navigator/prism_page.dart';
import '../navigator/types.dart';

/// Registry for automatically collecting pages.
///
/// Pages can register themselves automatically when instantiated.
/// This allows collecting all pages without manually listing them.
class PrismPageRegistry {
  PrismPageRegistry._();

  static final PrismPageRegistry _instance = PrismPageRegistry._();
  static PrismPageRegistry get instance => _instance;

  final Set<PrismPage> _pages = {};

  /// Registers a page instance.
  void register(PrismPage page) {
    _pages.add(page);
  }

  /// Gets all registered pages.
  List<PrismPage> get pages => _pages.toList();

  /// Clears the registry.
  void clear() => _pages.clear();

  /// Gets route definitions from registered pages.
  List<PrismRouteDefinition> get routeDefinitions =>
      _pages.map((page) => page.routeDefinition).toList();
}
