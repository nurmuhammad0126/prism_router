## 0.1.0

* **BREAKING**: Renamed `resetTo()` to `setStack()` for better clarity
* **BREAKING**: Renamed `change()` to `transformStack()` for better clarity
* Removed deprecated methods: `reset()` and `replaceTop()`
* Removed duplicate code in context extensions - simplified `push()` method
* Improved code quality and documentation
* Enhanced README with comprehensive navigation guide
* Updated examples to use new method names
* Better method naming for improved developer experience

## 0.0.1

* Initial public release of the **Prism Router** package
* First stable version of the `PrismRouter.router` API for Navigator 2.0
* Includes route definitions, guards, browser history integration, and context extensions
* Simple context extension methods: `context.push()`, `context.pop()`, `context.pushReplacement()`, etc.
* Navigation state management with `PrismController`
* Type-safe page definitions using sealed classes
* Navigation guards for access control and validation
* Navigation history tracking with observer pattern
* Custom page transitions support
* Deep linking support through Navigator 2.0
* Browser history integration on Flutter web (forward/back/refresh)
