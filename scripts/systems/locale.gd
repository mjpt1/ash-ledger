extends Node

## Persian-first locale helpers.

const DIGITS_FA := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

const STR := {
	"app_title": "دفتر خاکستر",
	"tagline": "شب را تاب بیاور. صفحه را ورق بزن.",
	"open_ledger": "باز کردن دفتر",
	"hub_title": "دفتر خاکستر",
	"ash": "خاکستر",
	"highest_page": "آخرین صفحه",
	"chapters": "فصل‌ها",
	"survive": "بقا",
	"read": "خواندن",
	"locked": "قفل",
	"meta_title": "شراره‌های ماندگار",
	"meta_hp": "قلب سنگی (جان)",
	"meta_damage": "خاکستر داغ‌تر (آسیب)",
	"meta_orbit": "شروع با حلقهٔ اخگر",
	"buy": "خرید",
	"max": "کامل",
	"online": "بازی آنلاین",
	"host": "میزبانی بازی",
	"join": "پیوستن",
	"solo": "تک‌نفره",
	"display_name": "نام نمایشی",
	"room_code": "آی‌پی میزبان",
	"port": "پورت",
	"players": "بازیکن‌ها",
	"start_run": "شروع شب",
	"waiting_host": "منتظر میزبان برای شروع…",
	"connected": "متصل شدید",
	"connection_failed": "اتصال برقرار نشد. دوباره تلاش کنید.",
	"choose_ember": "یک اخگر انتخاب کنید",
	"chapter_held": "فصل نگه داشته شد",
	"ash_settles": "خاکستر فرو نشست",
	"page_turns": "صفحه ورق می‌خورد. داستان منتظر است.",
	"you_fell": "افتادی. کمی خاکستر برای دفتر ماند.",
	"read_ledger": "خواندن دفتر",
	"return_hub": "بازگشت به خانه",
	"continue": "ادامه",
	"lv": "سطح",
	"coop_hint": "کوآپ ۲ تا ۴ نفره روی یک شب؛ میزبان موج دشمن‌ها را کنترل می‌کند.",
	"back": "بازگشت",
	"hosting": "در حال میزبانی…",
	"join_hint": "آی‌پی همان شبکه یا localhost",
}

func t(key: String) -> String:
	return str(STR.get(key, key))

func digits(value: Variant) -> String:
	var s := str(value)
	var out := ""
	for i in s.length():
		var ch := s[i]
		if ch >= "0" and ch <= "9":
			out += DIGITS_FA[int(ch)]
		else:
			out += ch
	return out

func ash_label(amount: int) -> String:
	return "%s: %s" % [t("ash"), digits(amount)]

func level_label(level: int) -> String:
	return "%s %s" % [t("lv"), digits(level)]

func timer_label(seconds: float) -> String:
	var total := maxi(int(floor(seconds)), 0)
	var m := int(total / 60)
	var s := int(total % 60)
	return "%s:%s" % [digits(m), digits("%02d" % s)]
