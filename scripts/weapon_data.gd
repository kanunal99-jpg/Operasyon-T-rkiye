extends RefCounted

# Weapon definitions are intentionally data-driven for future balancing and new weapons.
const WEAPONS := {
    "TAARRUZ TÜFEĞİ": {"damage": 34, "cooldown": 0.12, "magazine": 30, "reserve": 90, "range": 90.0, "reload": 1.55},
    "HAFİF MAKİNELİ": {"damage": 24, "cooldown": 0.075, "magazine": 40, "reserve": 120, "range": 75.0, "reload": 1.8},
    "KESKİN NİŞANCI": {"damage": 90, "cooldown": 0.8, "magazine": 8, "reserve": 32, "range": 160.0, "reload": 2.1}
}

static func get_weapon(name: String) -> Dictionary:
    return WEAPONS.get(name, WEAPONS["TAARRUZ TÜFEĞİ"])

static func names() -> Array:
    return WEAPONS.keys()