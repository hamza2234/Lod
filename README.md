# Lod

Prototype لتطبيق لودو بدون Unity: محرك Godot للعبة والواجهات، وتطبيق Kotlin كحاوية Android.

## النسخة الأساسية: Godot Engine

المجلد التالي يحتوي مشروع **Godot 4** حقيقي:

```text
godot-dice-preview/
```

افتح الملف التالي داخل Godot:

```text
godot-dice-preview/project.godot
```

هذه هي نسخة محرك الألعاب: دخول، لوبي، اختيار نمط، لوحة لودو، نرد 3D، سوق نرد، رمي تفاعلي، حركة حجر، كاميرا، إضاءة، وجسيمات.

## تطبيق Kotlin host

المجلد التالي يحتوي تطبيق Android/Kotlin:

```text
android-kotlin-host/
```

التطبيق لا يبني شاشات اللعبة بكوتلن. هو يشغّل Godot عبر `GodotActivity`، وGradle ينسخ مشروع Godot إلى Android assets أثناء البناء.

## نسخة المعاينة السريعة في المتصفح

يوجد أيضًا نموذج **Three.js / WebGL** سريع للتجربة من المتصفح. هذا ليس بديلًا عن محرك الألعاب، بل نسخة عرض سريعة لرؤية الفكرة من رابط.

## التشغيل

### تشغيل معاينة المتصفح

```bash
npm install
npm run dev
```

ثم افتح رابط Vite الذي يظهر في الطرفية.

### تشغيل نسخة Godot

1. ثبّت Godot 4.x.
2. افتح Godot.
3. اختر Import.
4. اختر:

```text
godot-dice-preview/project.godot
```

5. اضغط Run.

### تشغيل تطبيق Kotlin

افتح:

```text
android-kotlin-host/
```

في Android Studio، ثم شغّل module `app`.

## الموجود في النموذج

- نرد 3D بحواف دائرية ونقاط مضيئة.
- خمسة أشكال نرد: Royal Gold, Inferno Core, Frost Crystal, Galaxy Void, Emerald Royal.
- سوق نرد داخل Godot لاختيار وتجهيز الشكل.
- شاشة دخول ولوبي واختيار نمط وشاشة لعب داخل Godot.
- ضغط مباشر على النرد أو زر الرمي.
- حركة رمي سينمائية مع جسيمات وإضاءة ونتيجة نهائية واضحة.
- حركة حجر تجريبي على لوحة لودو بعد نتيجة النرد.
