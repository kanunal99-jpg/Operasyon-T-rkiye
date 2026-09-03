extends Node

# Campaign regions are grouped by continent so the world map can scale to a full global campaign.
const COUNTRIES := [
    ["Türkiye", "ASYA/AVRUPA", "İstanbul", 1], ["Yunanistan", "AVRUPA", "Atina", 2], ["Bulgaristan", "AVRUPA", "Sofya", 2], ["Almanya", "AVRUPA", "Berlin", 3], ["Fransa", "AVRUPA", "Paris", 3], ["İtalya", "AVRUPA", "Roma", 3], ["İspanya", "AVRUPA", "Madrid", 3], ["Birleşik Krallık", "AVRUPA", "Londra", 4], ["Norveç", "AVRUPA", "Oslo", 3], ["Polonya", "AVRUPA", "Varşova", 3],
    ["ABD", "KUZEY AMERİKA", "Washington", 4], ["Kanada", "KUZEY AMERİKA", "Ottawa", 3], ["Meksika", "KUZEY AMERİKA", "Mexico City", 3],
    ["Brezilya", "GÜNEY AMERİKA", "Brasília", 4], ["Arjantin", "GÜNEY AMERİKA", "Buenos Aires", 4], ["Şili", "GÜNEY AMERİKA", "Santiago", 3], ["Kolombiya", "GÜNEY AMERİKA", "Bogotá", 3],
    ["Mısır", "AFRİKA", "Kahire", 3], ["Fas", "AFRİKA", "Rabat", 2], ["Güney Afrika", "AFRİKA", "Pretoria", 4], ["Nijerya", "AFRİKA", "Abuja", 4], ["Kenya", "AFRİKA", "Nairobi", 3],
    ["Suudi Arabistan", "ASYA", "Riyad", 4], ["Birleşik Arap Emirlikleri", "ASYA", "Abu Dabi", 4], ["İran", "ASYA", "Tahran", 4], ["Irak", "ASYA", "Bağdat", 4], ["Hindistan", "ASYA", "Yeni Delhi", 4], ["Pakistan", "ASYA", "İslamabad", 4], ["Çin", "ASYA", "Pekin", 5], ["Japonya", "ASYA", "Tokyo", 5], ["Güney Kore", "ASYA", "Seul", 4], ["Endonezya", "ASYA", "Cakarta", 4],
    ["Avustralya", "OKYANUSYA", "Canberra", 4], ["Yeni Zelanda", "OKYANUSYA", "Wellington", 3]
]

var selected_country := "Türkiye"
var unlocked := {"Türkiye": true}

func countries_by_continent(continent: String) -> Array:
    return COUNTRIES.filter(func(item): return item[1] == continent)

func select_country(country: String) -> bool:
    for item in COUNTRIES:
        if item[0] == country and (unlocked.has(country) or country == "Türkiye"):
            selected_country = country
            return true
    return false

func unlock_country(country: String) -> void:
    unlocked[country] = true

func is_unlocked(country: String) -> bool:
    return unlocked.has(country)
