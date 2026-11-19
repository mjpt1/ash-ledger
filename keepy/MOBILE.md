# اپ موبایل — روپایی پرو

پروژه با **Capacitor 7** برای **اندروید** و **آیفون** آماده است.

شناسه اپ: `com.keepypro.app`

## اندروید (آماده روی ویندوز)

فایل آماده:

`dist/keepy-pro-debug.apk`

یا دوباره بساز:

```powershell
cd keepy
npm run cap:sync
cd android
.\gradlew.bat assembleDebug
```

## آیفون / iOS

پوشه `ios/` کامل است (آیکون، نام فارسی، تنظیمات شبکه و جهت‌گیری).  
**ولی ساخت فایل نصب (IPA) فقط روی Mac با Xcode ممکن است** — روی ویندوز Apple اجازهٔ کامپایل iOS نمی‌دهد.

### روی مک

```bash
cd keepy
npm install
npm run ios:build
# یا:
npm run cap:sync
npx cap open ios
```

در Xcode:

1. signing → Apple ID / Team را انتخاب کن  
2. Run روی آیفون یا Simulator  
3. برای IPA: **Product → Archive → Distribute App**

### الان روی آیفون بدون Mac (PWA)

1. `www/index.html` را با Safari باز کن (یا روی یک هاست بگذار)  
2. Share → **Add to Home Screen**  
3. مثل اپ تمام‌صفحه باز می‌شود

## همگام‌سازی بعد از تغییر بازی

```powershell
cd keepy
npm run cap:sync
```

## لیدربورد

```powershell
python server/leaderboard_server.py
```
