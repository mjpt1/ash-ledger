class_name UpgradeCatalog
extends RefCounted

const ALL := [
	{"id": "fire_rate", "title": "اخگر تند", "desc": "شلیک سریع‌تر."},
	{"id": "damage", "title": "خاکستر داغ‌تر", "desc": "گلوله‌ها قوی‌تر می‌زنند."},
	{"id": "magnet", "title": "کشش خاکستر", "desc": "تجربه را از دورتر جمع می‌کنی."},
	{"id": "orbit", "title": "حلقهٔ اخگر", "desc": "حلقه‌ای سوزان دشمنان نزدیک را می‌سوزاند."},
	{"id": "blast", "title": "انفجار جرقه", "desc": "گلوله‌ها هنگام برخورد منفجر می‌شوند."},
	{"id": "multishot", "title": "جرقهٔ شکافته", "desc": "یک پرتابهٔ اضافه شلیک می‌کنی."},
	{"id": "max_hp", "title": "قلب سنگی", "desc": "جان بیشینه بیشتر می‌شود."},
]

static func pick_three(rng: RandomNumberGenerator) -> Array:
	var pool: Array = ALL.duplicate()
	var picks: Array = []
	for _i in 3:
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1)
		picks.append(pool[idx])
		pool.remove_at(idx)
	return picks
