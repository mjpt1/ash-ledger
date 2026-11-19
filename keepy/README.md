# روپایی پرو

بازی روپایی رقابتی — وب، **اندروید** و **آیفون**.

## بازی سریع (مرورگر)

`index.html` یا `www/index.html` را باز کن.

## اپ موبایل

جزئیات کامل: [`MOBILE.md`](MOBILE.md)

```powershell
cd keepy
npm install
npm run cap:sync
npx cap open android   # Android Studio
npx cap open ios       # فقط روی Mac + Xcode
```

- شناسه: `com.keepypro.app`
- پوشه‌ها: `android/` و `ios/`

### PWA روی گوشی

`www/` را هاست کن یا با کابل باز کن → Add to Home Screen (اندروید/آیفون).

## لیدربورد

```powershell
python server/leaderboard_server.py
```
