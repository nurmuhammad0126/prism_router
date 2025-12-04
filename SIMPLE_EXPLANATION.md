# Elixir Package - Simple Explanation

## Qisqa Tushuntirish (Uzbek)

Elixir - Flutter uchun navigation package. U Flutter'ning Navigator 2.0 API'siga qurilgan va navigation state'ni `List<ElixirPage>` (sahifalar ro'yxati) sifatida boshqaradi.

## Asosiy Komponentlar

### 1. **ElixirPage** - Har bir sahifa
- Har bir ekran `ElixirPage` dan extends qilinadi
- `name`: sahifa nomi ('home', 'settings')
- `child`: ekran widget'i
- `arguments`: sahifaga uzatiladigan ma'lumotlar
- `tags`: sahifalarni filter qilish uchun

### 2. **ElixirController** - State boshqaruvchi
- Navigation stack'ni saqlaydi: `List<ElixirPage>`
- Metodlar:
  - `push(page)` - yangi sahifa qo'shadi
  - `pop()` - oxirgi sahifani olib tashlaydi
  - `change(transform)` - stack'ni o'zgartiradi
- **Guards**: Navigation'ni nazorat qiluvchi funksiyalar
  - Masalan: agar foydalanuvchi login qilmagan bo'lsa, login sahifasiga yo'naltirish

### 3. **ElixirRouterDelegate** - Flutter Router bilan bog'lanish
- `RouterDelegate` ni implement qiladi
- Controller state o'zgarganda Navigator'ni rebuild qiladi
- Browser URL o'zgarganda controller'ni yangilaydi

### 4. **ElixirRouteInformationParser** - URL parsing
- Browser URL → `List<ElixirPage>` ga aylantiradi
- `List<ElixirPage>` → Browser URL ga aylantiradi
- Web'da hash routing'ni qo'llab-quvvatlaydi: `/#/home/settings`

### 5. **Path Codec** - URL encoding/decoding
- `encodeLocation()`: `[HomePage, SettingsPage]` → `"/home/settings"`
- `decodeUri()`: `"/home/settings"` → `[home, settings]` segments
- **Eslatma**: Faqat sahifa nomlari URL'da saqlanadi, arguments yo'qoladi

## Ishlash Prinsipi

### Navigation (push/pop):
```
User: context.elixir.push(SettingsPage())
  ↓
Controller: [HomePage] → [HomePage, SettingsPage]
  ↓
_setState() → notifyListeners()
  ↓
RouterDelegate rebuild → Navigator yangi sahifalarni ko'rsatadi
  ↓
restoreRouteInformation() → Browser URL yangilanadi: /home/settings
```

### Refresh (browser refresh button):
```
Browser URL: /#/home/settings
  ↓
parseRouteInformation() → URL'ni o'qiydi
  ↓
decodeUri() → [home, settings] segments
  ↓
Route definitions → [HomePage(), SettingsPage()]
  ↓
setNewRoutePath() → Controller state yangilanadi
  ↓
Navigator rebuild → To'g'ri sahifalar ko'rsatiladi
```

## Web'da Refresh Muammosi va Yechimi

**Muammo**: Refresh qilganda har doim initial page'ga qaytib ketardi.

**Sabab**: `PlatformRouteInformationProvider` har doim initial location bilan initialize qilingan edi, browser URL e'tiborga olinmagan.

**Yechim**: Web'da `Uri.base` (haqiqiy browser URL) ishlatiladi:
```dart
final initialRouteInformation = kIsWeb
    ? RouteInformation(uri: Uri.base)  // Browser URL'ni o'qiydi
    : RouteInformation(uri: Uri.parse(encodeLocation(initialStack)));
```

Endi refresh qilganda parser browser URL'ni o'qiydi va to'g'ri stack'ni restore qiladi.

## Double Hash Muammosi (#/#/home)

**Muammo**: URL'da `/#/#/home` ko'rinardi.

**Sabab**: Code manual ravishda `#/` qo'shgan edi, Flutter esa o'zi qo'shadi.

**Yechim**: Faqat path qaytariladi (`/home`), Flutter o'zi `#` qo'shadi:
```dart
// Oldin: Uri(path: '/', fragment: '/home') → /#/#/home
// Hozir: RouteInformation(location: '/home') → /#/home
```

## Guard System

Guards - navigation'ni nazorat qiluvchi funksiyalar:

```dart
guards: [
  (context, state) {
    // Agar stack bo'sh bo'lsa, home'ga qaytar
    if (state.isEmpty) return [const HomePage()];
    return state;
  },
  (context, state) {
    // Agar foydalanuvchi login qilmagan bo'lsa
    if (!isAuthenticated && state.any((p) => p.tags.contains('protected'))) {
      return [LoginPage()];
    }
    return state;
  },
]
```

Guards ketma-ket ishlaydi va har biri state'ni o'zgartirishi mumkin.

## Xulosa

Elixir package:
- Navigation state'ni `List<ElixirPage>` sifatida boshqaradi (declarative)
- Browser URL bilan avtomatik sync qiladi
- Type-safe page definitions
- Guard system bilan navigation'ni nazorat qiladi
- Web, mobile, desktop'da ishlaydi

---

## English Summary

Elixir is a Flutter navigation package that:
1. Manages navigation as a stack of pages (`List<ElixirPage>`)
2. Syncs with browser URLs automatically (web)
3. Uses guards to control navigation flow
4. Provides type-safe page definitions
5. Works on all platforms (web, mobile, desktop)

**Key fix for refresh issue**: On web, the router now reads the actual browser URL (`Uri.base`) instead of always using the initial location, so refresh preserves the navigation stack.

