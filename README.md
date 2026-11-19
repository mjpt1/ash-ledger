# دفتر خاکستر (Ash Ledger)

بازی hybridcasual اندروید: **بقا (Survivor)** + **داستان کوتاه AI** + متای سبک.

## MVP آماده‌ی اجرا

- حلقهٔ بقا: حرکت، شلیک خودکار، XP، ارتقا، موج دشمن، boss
- ۵ فصل JSON در `content/story/` + پرامپت AI در `content/prompts/`
- هاب با ۳ ارتقای دائمی (جان / آسیب / حلقهٔ اخگر) و ذخیرهٔ محلی
- رابط فارسی RTL، پالت خاکستر+کهربایی، جوی‌استیک لمسی، portrait

## اجرا (Godot 4.7+)

1. پروژه را در Godot باز کن (`project.godot`)
2. `F5` بزن
3. **تک‌نفره** → هاب → **بقا** روی فصل باز

### کنترل

- کیبورد: WASD / فلش‌ها
- لمس: جوی‌استیک گوشه

## جریان بازی

منو → هاب → ران survivor → (برد) خواندن فصل → آنلاک فصل بعد → متا با خاکستر

## داستان با AI

پرامپت: [`content/prompts/chapter_generator.md`](content/prompts/chapter_generator.md)  
فایل‌ها: `content/story/chapter_XX.json` + افزودن id به `GameState.CHAPTER_ORDER`

## خروجی اندروید

Preset در `export_presets.cfg` (پکیج `com.ashledger.game`).  
راهنما: [`export/ANDROID.md`](export/ANDROID.md)

```bat
godot --headless --path . --export-debug "Android" export/AshLedger-debug.apk
```

نیاز: Export Templates نسخهٔ 4.7.stable + Android SDK + JDK.

## دموی وب سریع

[`export/demo/ash-ledger-demo.html`](export/demo/ash-ledger-demo.html)
