# Ultra Simple Usage Guide

## Eng Qisqa Kod - Faqat Kerakli Narsalar!

### Oldin (12 qator):
```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          arguments: {'data': data},
        );

  factory SettingsPage.fromArguments(Map<String, Object?> arguments) =>
      SettingsPage(data: arguments['data'] as String? ?? '');

  final String data;

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);

  @override
  Set<String> get tags => {'settings'};

  static const route = ElixirRouteDefinition(
    name: 'settings',
    builder: SettingsPage.fromArguments,
  );
}
```

### Hozir (7 qator - 40% kamroq!):
```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          arguments: {'data': data},
        );

  final String data;

  // Faqat bu override kerak!
  @override
  ElixirPage fromArguments(Map<String, Object?> arguments) =>
      SettingsPage(data: arguments['data'] as String? ?? '');

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);

  // Tags avtomatik: {'settings'} (name'dan)
  // Route avtomatik!
}
```

---

## Qanday Ishlaydi?

### 1. **Tags Avtomatik**
- **Oldin**: `@override Set<String> get tags => {'settings'};` yozish kerak edi
- **Hozir**: Avtomatik `name`'dan yaratiladi: `{'settings'}`
- **Override**: Agar kerak bo'lsa, override qilish mumkin

### 2. **Route Avtomatik**
- **Oldin**: `static const route = ElixirRouteDefinition(...)` yozish kerak edi
- **Hozir**: `routeDefinition` getter avtomatik mavjud
- **Router**: `routes` parametri ixtiyoriy - avtomatik yaratiladi

### 3. **fromArguments Minimal**
- **Oldin**: `factory fromArguments` yozish kerak edi
- **Hozir**: Faqat `@override fromArguments` yozish kifoya
- **Arguments bo'lmasa**: Hech narsa yozish kerak emas!

---

## Misollar

### Simple Page (Hech narsa yozish kerak emas!)
```dart
final class HomePage extends AppPage {
  const HomePage() : super(child: const HomeScreen(), name: 'home');
  
  // fromArguments - ixtiyoriy! Faqat custom behavior kerak bo'lsa
  @override
  ElixirPage fromArguments(Map<String, Object?> _) => const HomePage();
  
  // Tags avtomatik: {'home'}
  // Route avtomatik!
}
```

### Page with Arguments (Faqat fromArguments)
```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          arguments: {'data': data},
        );

  final String data;

  // Faqat bu kerak!
  @override
  ElixirPage fromArguments(Map<String, Object?> arguments) =>
      SettingsPage(data: arguments['data'] as String? ?? '');
  
  // Tags avtomatik: {'settings'}
  // Route avtomatik!
}
```

### Custom Tags (Agar kerak bo'lsa)
```dart
final class SettingsPage extends AppPage {
  // ... constructor ...

  // Faqat custom tags kerak bo'lsa override qilish
  @override
  Set<String> get tags => {'settings', 'preferences', 'config'};
}
```

---

## Router Setup

### Eng Oddiy (Hech narsa yozish kerak emas!)
```dart
final router = Elixir.router(
  // routes ixtiyoriy - avtomatik yaratiladi!
  initialStack: [const HomePage()],
);
```

### Manual Routes (Agar kerak bo'lsa)
```dart
final router = Elixir.router(
  routes: [
    const HomePage().routeDefinition,      // Avtomatik!
    SettingsPage(data: '').routeDefinition, // Avtomatik!
  ],
  initialStack: [const HomePage()],
);
```

---

## Qiyoslash

| Xususiyat | Oldin | Hozir | Yaxshilanish |
|-----------|-------|-------|--------------|
| Simple page | 12 qator | 5 qator | **60% kamroq** |
| Arguments bilan | 12 qator | 7 qator | **40% kamroq** |
| Tags yozish | ✅ Kerak | ❌ Avtomatik | ✅ |
| Route yozish | ✅ Kerak | ❌ Avtomatik | ✅ |
| Factory yozish | ✅ Kerak | ❌ Kerak emas | ✅ |
| Routes parameter | ✅ Required | ❌ Optional | ✅ |

---

## Xulosa

Endi package **ancha osonroq** ishlatiladi:

✅ **Tags avtomatik** - name'dan yaratiladi  
✅ **Route avtomatik** - routeDefinition getter  
✅ **Routes optional** - avtomatik yaratiladi  
✅ **Minimal boilerplate** - faqat kerakli narsalar  
✅ **Backward compatible** - eski kod ishlaydi  

**Eng yaxshi qismi**: Simple page'lar uchun faqat constructor yozish kifoya!

