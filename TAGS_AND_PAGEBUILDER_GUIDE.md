# Tags va pageBuilder Qo'llanmasi

## Qilingan O'zgarishlar

### 1. **Tags Super'dan O'tkaziladi** ✅

Endi tags'ni ham `name` kabi super'dan o'tkazish mumkin:

**Oldin:**
```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          arguments: {'data': data},
        );

  @override
  Set<String> get tags => {'settings'};  // Override qilish kerak edi
}
```

**Hozir:**
```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          tags: 'settings',  // Super'dan o'tkaziladi!
          arguments: {'data': data},
        );

  // Tags override qilish kerak emas!
}
```

### 2. **fromArguments → pageBuilder** ✅

`fromArguments` endi deprecated, `pageBuilder` ishlatiladi:

**Oldin:**
```dart
@override
ElixirPage fromArguments(Map<String, Object?> arguments) =>
    SettingsPage(data: arguments['data'] as String? ?? '');
```

**Hozir:**
```dart
@override
ElixirPage pageBuilder(Object? arguments) {
  if (arguments is Map<String, Object?>) {
    return SettingsPage(data: arguments['data'] as String? ?? '');
  }
  return SettingsPage(data: '');
}
```

### 3. **Record Support (Type-Safe)** ✅

`pageBuilder` endi `Object?` qabul qiladi, shuning uchun Record ishlatish mumkin:

```dart
@override
ElixirPage pageBuilder(Object? arguments) {
  // Pattern matching bilan type-safe
  if (arguments case {'data': String data}) {
    return SettingsPage(data: data);
  }
  return SettingsPage(data: '');
}
```

---

## Tags Formatlari

Tags'ni 3 xil usulda berish mumkin:

### 1. Single String (Eng Oddiy)
```dart
SettingsPage({required this.data})
    : super(
        name: 'settings',
        tags: 'settings',  // Single tag
        ...
      );
```

### 2. Set of Strings (Multiple Tags)
```dart
SettingsPage({required this.data})
    : super(
        name: 'settings',
        tags: {'settings', 'preferences', 'config'},  // Multiple tags
        ...
      );
```

### 3. Auto-generated (Default)
```dart
SettingsPage({required this.data})
    : super(
        name: 'settings',
        // tags berilmasa, avtomatik name'dan yaratiladi: {'settings'}
        ...
      );
```

---

## pageBuilder Misollari

### Map bilan (Oldingi Usul)
```dart
@override
ElixirPage pageBuilder(Object? arguments) {
  if (arguments is Map<String, Object?>) {
    return SettingsPage(data: arguments['data'] as String? ?? '');
  }
  return SettingsPage(data: '');
}
```

### Record bilan (Type-Safe)
```dart
@override
ElixirPage pageBuilder(Object? arguments) {
  // Pattern matching - type-safe!
  if (arguments case {'data': String data}) {
    return SettingsPage(data: data);
  }
  if (arguments case {'data': String data, 'theme': String theme}) {
    return SettingsPage(data: data, theme: theme);
  }
  return SettingsPage(data: '');
}
```

### Multiple Arguments bilan
```dart
@override
ElixirPage pageBuilder(Object? arguments) {
  if (arguments is Map<String, Object?>) {
    return DetailsPage(
      userId: arguments['userId'] as String? ?? '',
      note: arguments['note'] as String? ?? '',
    );
  }
  return DetailsPage(userId: '', note: '');
}
```

---

## CustomMaterialRoute Muammosi Hal Qilindi ✅

**Muammo:**
```dart
// Error: The argument type 'SettingsPage' can't be assigned to the parameter type 'AppPage'
CustomMaterialRoute(page: this);
```

**Yechim:**
`CustomMaterialRoute` endi `ElixirPage` qabul qiladi (generic):

```dart
class CustomMaterialRoute extends PageRoute<void> {
  CustomMaterialRoute({required ElixirPage page}) : super(settings: page);
  
  ElixirPage get page => settings as ElixirPage;
}
```

Endi barcha page'lar bilan ishlaydi!

---

## To'liq Misol

```dart
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          tags: 'settings',  // Super'dan!
          arguments: {'data': data},
        );

  final String data;

  // pageBuilder - Record bilan type-safe!
  @override
  ElixirPage pageBuilder(Object? arguments) {
    if (arguments case {'data': String data}) {
      return SettingsPage(data: data);
    }
    return SettingsPage(data: '');
  }

  @override
  Route<void> createRoute(BuildContext context) =>
      CustomMaterialRoute(page: this);  // Endi ishlaydi!

  // Tags avtomatik: {'settings'} (super'dan)
  // Route avtomatik!
}
```

---

## Xulosa

✅ **Tags super'dan** - `tags: 'settings'` yoki `tags: {'settings'}`  
✅ **pageBuilder** - `fromArguments` o'rniga  
✅ **Record support** - Type-safe pattern matching  
✅ **CustomMaterialRoute** - Endi barcha page'lar bilan ishlaydi  

Endi package **ancha qulayroq** ishlatiladi!

