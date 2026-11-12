# خزائن الهدى — Khazain Al-Huda

تطبيق Android أصلي مبني باستخدام Kotlin وJetpack Compose. الإصدار الحالي: **1.0.23 (25)**.

## البناء المحلي

```bash
export ANDROID_HOME=/path/to/android-sdk
chmod +x ./gradlew
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

ينتج APK التجريبي في:

`app/build/outputs/apk/debug/app-debug.apk`

## ملاحظة التوقيع

نسخة `debug` موقعة بمفتاح Android debug لتسهيل التثبيت والاختبار. إصدار `release` يتطلب مفتاح التوقيع الأصلي للمالك عبر متغيرات البيئة `KEYSTORE_PATH`, `STORE_PASSWORD`, `KEY_PASSWORD`, و`KEY_ALIAS`، ولا يتم تضمين أي مفتاح خاص داخل المستودع.

## GitHub Actions

يتم تشغيل الاختبارات وبناء APK تلقائيًا عند الدفع إلى فرع `main`، كما يمكن تشغيله يدويًا من تبويب Actions.
