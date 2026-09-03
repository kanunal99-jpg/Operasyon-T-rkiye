extends Node

# Lightweight narrative state machine. Events are fictional and use real countries only as campaign context.
signal event_started(title: String)
signal event_message(text: String)
signal alliance_changed(country: String, allied: bool)

var relations: Dictionary = {}
var alliances: Array[String] = []
var war_alert := 0

func set_relation(country: String, value: int) -> void:
    relations[country] = clampi(value, -100, 100)

func get_relation(country: String) -> int:
    return int(relations.get(country, 0))

func propose_alliance(country: String) -> bool:
    if country == "" or country in alliances:
        return false
    if get_relation(country) < 20:
        event_message.emit("%s ittifak teklifini kabul etmedi." % country)
        return false
    alliances.append(country)
    event_started.emit("DİPLOMATİK GELİŞME")
    event_message.emit("%s ile savunma ittifakı kuruldu." % country)
    alliance_changed.emit(country, true)
    return true

func break_alliance(country: String) -> void:
    if country in alliances:
        alliances.erase(country)
        set_relation(country, get_relation(country) - 25)
        event_started.emit("İTTİFAK KRİZİ")
        event_message.emit("%s ile ittifak sona erdi." % country)
        alliance_changed.emit(country, false)

func raise_alert(amount: int = 10) -> void:
    war_alert = clampi(war_alert + amount, 0, 100)

func build_news_cards(country: String, city: String, operation: String) -> Array[Dictionary]:
    var ally_text := "Müttefik ülkeler ortak savunma toplantısına katılıyor." if not alliances.is_empty() else "Diplomatik başkentlerde acil temas trafiği başladı."
    return [
        {"category":"DÜNYA HABERLERİ • SON DAKİKA", "headline":"SINIR HATTINDA GERİLİM TIRMANIYOR", "body":"%s çevresinde güvenlik alarmı yükseldi. Hükümetler olağanüstü toplantıya çağrıldı; askeri birlikler savunma hazırlıklarını artırdı." % country, "location":"CANLI YAYIN • %s" % city},
        {"category":"BAŞKANLIK AÇIKLAMASI", "headline":"BAŞKENTTEN SERT AÇIKLAMA", "body":"Kurgusal devlet başkanı, ülkenin egemenliğini korumak için gerekli tüm tedbirlerin alınacağını açıkladı. %s" % ally_text, "location":"BAŞKENT • ULUSAL BASIN MERKEZİ"},
        {"category":"İTTİFAK MASASI", "headline":"MÜTTEFİKLER ORTAK SAVUNMAYI GÖRÜŞÜYOR", "body":"%d müttefik ülke koordinasyon görüşmelerinde. İstihbarat, lojistik ve savunma desteği seçenekleri değerlendiriliyor." % alliances.size(), "location":"ORTAK KRİZ MASASI"},
        {"category":"GAZETE • SABAH BASKISI", "headline":"DÜNYA YENİ BİR KRİZİN EŞİĞİNDE", "body":"Başkentlerde diplomasi sürerken bölgedeki birlikler alarmda. Gözler şimdi %s operasyonunda." % operation, "location":"ULUSLARARASI BASIN • ÖZEL HABER"}
    ]
