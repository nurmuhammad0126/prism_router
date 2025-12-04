## 0.2.0

* replaced the old `Elixir` widget with a Router-based API (`Elixir.router`)
* added `ElixirRouteDefinition` so routes are declared once and reused for
  parsing/restoration
* adopted `MaterialApp.router`, giving GoRouter-level back/forward/refresh
  behavior on web, mobile, and desktop
* simplified Flutter web refresh handling—stacks are encoded directly into the
  URL, no manual state management needed

## 0.1.0

* added automatic browser history & URL syncing on Flutter web
* added optional `routeDecoder` to restore stacks after browser refreshes
* fixed browser back/forward handling by mirroring route information updates
* improved refresh resilience by using multi-entry history snapshots
* exported navigation type definitions for easier reuse

## 0.0.2

* added Elixir controller extension

## 0.0.1

* initial configuration
