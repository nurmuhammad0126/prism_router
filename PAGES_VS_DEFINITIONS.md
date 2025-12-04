# pages vs definitions - Farq

## Qisqa Javob

**`pages`** - Yangi va qulayroq usul (Tavsiya etiladi!)  
**`definitions`** - Eski usul (Backward compatible)

---

## Batafsil Tushuntirish

### 1. **pages** - `List<ElixirPage>`

```dart
static final pages = [
  const HomePage(),
  SettingsPage(data: ''),
  const ProfilePage(),
  DetailsPage(userId: '', note: ''),
];
```

**Xususiyatlari:**
- ✅ To'g'ridan-to'g'ri page instance'lari
- ✅ Oddiy va qulay
- ✅ Package avtomatik `routeDefinition`'larga aylantiradi
- ✅ Yangi usul

**Router'da ishlatish:**
```dart
Elixir.router(
  pages: AppRoutes.pages,  // YANGI! pages parametri
  initialStack: [const HomePage()],
);
```

**Ichida nima bo'ladi:**
```dart
// Package ichida avtomatik:
for (final page in pages) {
  page.name: page.routeDefinition  // Avtomatik aylantiriladi
}
```

---

### 2. **definitions** - `List<ElixirRouteDefinition>`

```dart
static final definitions = [
  const HomePage().routeDefinition,
  SettingsPage(data: '').routeDefinition,
  const ProfilePage().routeDefinition,
  DetailsPage(userId: '', note: '').routeDefinition,
];
```

**Xususiyatlari:**
- ⚠️ Har bir page uchun `.routeDefinition` chaqirish kerak
- ⚠️ Biroz ko'proq kod
- ✅ Eski usul (backward compatible)
- ✅ To'g'ridan-to'g'ri route definition'lar

**Router'da ishlatish:**
```dart
Elixir.router(
  routes: AppRoutes.definitions,  // ESKI usul
  initialStack: [const HomePage()],
);
```

**Ichida nima bo'ladi:**
```dart
// To'g'ridan-to'g'ri ishlatiladi:
for (final route in routes) {
  route.name: route  // Hech narsa aylantirish kerak emas
}
```

---

## Qiyoslash

| Xususiyat | pages | definitions |
|-----------|-------|-------------|
| Type | `List<ElixirPage>` | `List<ElixirRouteDefinition>` |
| Kod miqdori | ⭐⭐⭐⭐⭐ (5 qator) | ⭐⭐⭐ (7 qator) |
| Qulaylik | ✅ Oddiy | ⚠️ Biroz murakkab |
| `.routeDefinition` | ❌ Kerak emas | ✅ Kerak |
| Avtomatik aylantirish | ✅ Bor | ❌ Yo'q |
| Backward compatible | ✅ | ✅ |

---

## Qaysi Birini Ishlatish Kerak?

### **pages** (Tavsiya etiladi!) ⭐

**Afzalliklari:**
- ✅ Oddiy va qulay
- ✅ Kamroq kod
- ✅ Avtomatik aylantirish

**Ishlatish:**
```dart
Elixir.router(
  pages: AppRoutes.pages,  // YANGI!
  initialStack: [const HomePage()],
);
```

### **definitions** (Eski usul)

**Afzalliklari:**
- ✅ To'g'ridan-to'g'ri route definition'lar
- ✅ Backward compatible

**Ishlatish:**
```dart
Elixir.router(
  routes: AppRoutes.definitions,  // ESKI
  initialStack: [const HomePage()],
);
```

---

## Ichki Ishlash

### pages bilan:
```dart
// User kodi:
pages: AppRoutes.pages

// Package ichida:
final routeMap = {
  for (final page in pages)
    page.name: page.routeDefinition  // Avtomatik aylantiriladi
};
```

### definitions bilan:
```dart
// User kodi:
routes: AppRoutes.definitions

// Package ichida:
final routeMap = {
  for (final route in routes)
    route.name: route  // To'g'ridan-to'g'ri ishlatiladi
};
```

---

## Xulosa

**`pages`** - Yangi va qulayroq usul, tavsiya etiladi!  
**`definitions`** - Eski usul, backward compatible.

**Tavsiya:** `pages` ishlating - oddiy va qulay!

