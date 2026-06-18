# Ludo Nova Android/Kotlin Host

هذا مشروع Android/Kotlin حاوية لتشغيل محرك Godot داخل تطبيق أندرويد.

## الفكرة

- Kotlin لا يبني اللوبي أو السوق أو شاشة اللعب.
- Kotlin يفتح `MainActivity` فقط.
- `MainActivity` تمتد من `GodotActivity`.
- مشروع Godot الموجود في:

```text
../godot-dice-preview/
```

يتم نسخه تلقائيًا إلى:

```text
app/src/main/assets/
```

أثناء بناء تطبيق Android.

## أين الشاشات؟

كل هذه الشاشات داخل Godot:

- شاشة الدخول.
- اللوبي.
- شاشة اختيار نمط اللعب.
- شاشة اللعب مع لوحة لودو.
- حركة رمي النرد.
- حركة حجر تجريبي بعد نتيجة النرد.
- تبويب سوق النرد.
- اختيار وتجهيز النردات.

## التشغيل

افتح مجلد `android-kotlin-host` في Android Studio ثم شغّل تطبيق `app`.

يتطلب المشروع:

- Android Studio حديث يدعم Android Gradle Plugin 9.0.1.
- Android SDK 36.
- اتصال Maven Central لتحميل:

```kotlin
implementation("org.godotengine:godot:4.4.1.stable")
```

## ملاحظة مهمة

إذا أردت أن تكون اللعبة كاملة في المحرك، استمر بتطوير `godot-dice-preview`.
تطبيق Kotlin سيبقى غلافًا Android فقط، وهذا يحافظ على أن السوق واللوبي واللعبة ليست شاشات Kotlin.
