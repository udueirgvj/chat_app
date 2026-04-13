# 💬 ChatApp — تطبيق دردشة مثل Telegram

مشروع Flutter كامل يدعم Android و iOS، مبني على Firebase.

---

## 📋 الميزات

- ✅ تسجيل دخول / إنشاء حساب (Email + Password)
- ✅ إرسال رسائل نصية في الوقت الفعلي
- ✅ إرسال صور (كاميرا + معرض)
- ✅ إرسال ملفات
- ✅ رسائل صوتية
- ✅ الرد على رسالة (Reply)
- ✅ حذف الرسائل (للجميع أو لي فقط)
- ✅ إشعارات Push (FCM)
- ✅ حالة متصل/غير متصل
- ✅ علامات القراءة (✓✓)
- ✅ عداد الرسائل غير المقروءة
- ✅ بحث عن المستخدمين
- ✅ الوضع الداكن (Dark Mode)
- ✅ تحديث الملف الشخصي + صورة

---

## 🚀 خطوات الإعداد

### 1. إنشاء مشروع Firebase

1. اذهب إلى [console.firebase.google.com](https://console.firebase.google.com)
2. أنشئ مشروعاً جديداً
3. فعّل الخدمات التالية:
   - **Authentication** → Email/Password
   - **Cloud Firestore** → Start in test mode (ثم طبّق القواعد)
   - **Storage** → Start in test mode
   - **Cloud Messaging** (FCM) — تلقائي

---

### 2. ربط Firebase بالمشروع

```bash
# ثبّت FlutterFire CLI
dart pub global activate flutterfire_cli

# في مجلد المشروع
flutterfire configure
```

سيُنشئ ملف `lib/firebase_options.dart` تلقائياً.

---

### 3. تثبيت الحزم

```bash
flutter pub get
```

---

### 4. رفع قواعد Firestore و Storage

في Firebase Console:

- **Firestore > Rules** → انسخ محتوى `firestore.rules`
- **Storage > Rules** → انسخ محتوى `storage.rules`

---

### 5. تشغيل التطبيق

```bash
# Android
flutter run

# iOS (يحتاج Mac)
flutter run -d ios

# تشغيل على محاكي معين
flutter run -d emulator-5554
```

---

## 🔨 البناء عبر Codemagic

### الإعداد:

1. ارفع المشروع على **GitHub / GitLab**
2. سجّل في [codemagic.io](https://codemagic.io)
3. اربطه بمستودعك
4. Codemagic سيكتشف `codemagic.yaml` تلقائياً

### لبناء APK للاختبار السريع:

1. في Codemagic → اختر workflow: **Android Debug Build**
2. اضغط **Start New Build**
3. بعد الانتهاء → حمّل APK مباشرةً

### لبناء APK Release:

1. أنشئ Keystore:
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
2. ارفع الـ Keystore في **Codemagic > Code Signing**
3. شغّل workflow: **Android Release Build**

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                    # نقطة الدخول
├── app.dart                     # Router + Theme
├── firebase_options.dart        # ⚠️ يُولَّد بـ flutterfire configure
├── core/
│   ├── constants/               # ثوابت التطبيق
│   ├── theme/                   # الثيم (داكن/فاتح)
│   └── utils/                   # دوال مساعدة
├── models/                      # نماذج البيانات
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── services/                    # Firebase Services
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── storage_service.dart
│   └── notification_service.dart
├── providers/                   # State Management
│   ├── auth_provider.dart
│   └── chat_provider.dart
├── screens/                     # شاشات التطبيق
│   ├── splash/
│   ├── auth/
│   ├── home/
│   ├── chat/
│   └── profile/
└── widgets/                     # مكوّنات UI مشتركة
    ├── message_bubble.dart
    ├── chat_input_bar.dart
    ├── chat_list_tile.dart
    └── reply_preview.dart
```

---

## ⚙️ المتطلبات

| الأداة | الإصدار |
|--------|---------|
| Flutter | 3.24+ (stable) |
| Dart | 3.5+ |
| Android minSdk | 23 (Android 6) |
| iOS | 12.0+ |

---

## 🐛 حل المشاكل الشائعة

### `google-services.json` غير موجود
→ شغّل `flutterfire configure` أولاً

### خطأ في الـ Permissions على Android
→ تأكد أن `minSdk = 23` في `build.gradle`

### خطأ FCM على iOS
→ تأكد من إضافة **Push Notifications Capability** في Xcode

### خطأ `PERMISSION_DENIED` في Firestore
→ راجع قواعد `firestore.rules` وطبّقها في Console

---

## 📞 الدعم

لأي مشكلة راجع [Flutter Docs](https://docs.flutter.dev) أو [Firebase Docs](https://firebase.google.com/docs).
