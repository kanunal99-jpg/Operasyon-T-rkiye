extends Node

# Global operation generator: every country on the campaign map always has
# three fictionalized, playable operations based on its capital and difficulty.
const GlobalMap = preload("res://scripts/global_world_map.gd")

const OPERATIONS := {
    "Türkiye": [["İstanbul", "Boğaz Hattı", "Şehir içinde keşif ekibini durdur.", 1], ["Ankara", "Başkent Savunması", "Kritik bölgeyi savun.", 2], ["İzmir", "Ege Kıyısı", "İletişim merkezini ele geçir.", 2]],
    "Almanya": [["Berlin", "Gece Koridoru", "Şehir operasyonunu tamamla.", 3], ["Hamburg", "Liman Görevi", "Liman bölgesini temizle.", 3], ["Münih", "Güney Hattı", "Lojistik merkezini güvenceye al.", 3]],
    "Fransa": [["Paris", "Şehir Işıkları", "Ana iletişim noktasını kontrol et.", 3], ["Marsilya", "Liman Hattı", "Kıyı operasyonunu tamamla.", 3], ["Lyon", "Merkez Koridoru", "Tahliye hattını güvenceye al.", 3]],
    "İtalya": [["Roma", "Tarihî Hat", "Görev bölgesini güvenceye al.", 3], ["Milano", "Kuzey Operasyonu", "Hedef ekibi takip et.", 3], ["Napoli", "Kıyı Alarmı", "Liman yaklaşımını savun.", 3]],
    "İspanya": [["Madrid", "Başkent Görevi", "Operasyon merkezine ulaş.", 3], ["Barselona", "Kıyı Operasyonu", "Kıyı hattını savun.", 3], ["Valensiya", "Akdeniz Koridoru", "İkmal hattını koru.", 3]],
    "ABD": [["Washington", "Başkent Krizi", "Kritik bölgeyi koru.", 4], ["New York", "Metropol Hattı", "Şehir görevini tamamla.", 4], ["Los Angeles", "Batı Koridoru", "Tahliye merkezini güvenceye al.", 4]],
    "Kanada": [["Ottawa", "Kuzey Görevi", "Görev alanını güvenceye al.", 3], ["Toronto", "Metropol Savunması", "Ekibi tahliye et.", 3], ["Vancouver", "Pasifik Hattı", "Lojistik koridorunu koru.", 3]],
    "Japonya": [["Tokyo", "Neon Hattı", "Şehir merkezine ulaş.", 5], ["Osaka", "Kentsel Görev", "Hedef bölgeyi güvenceye al.", 5], ["Yokohama", "Liman Alarmı", "Kıyı hattını savun.", 5]],
    "Brezilya": [["Brasília", "Federal Hat", "Operasyon merkezini savun.", 4], ["São Paulo", "Metropol Görevi", "Şehir hattını güvenceye al.", 4], ["Rio de Janeiro", "Kıyı Koridoru", "Tahliye hattını güvenceye al.", 4]]
}

static func get_operations(country: String) -> Array:
    if OPERATIONS.has(country):
        return OPERATIONS[country]
    for item in GlobalMap.COUNTRIES:
        if item[0] == country:
            var capital := str(item[2])
            var difficulty := int(item[3])
            return [
                [capital, "Başkent Operasyonu", "Görev bölgesini güvenceye al.", difficulty],
                [capital, "Kentsel Hat", "İletişim ve tahliye hattını kontrol et.", difficulty],
                [capital, "Son Savunma", "Müttefik desteğiyle operasyonu tamamla.", mini(5, difficulty + 1)]
            ]
    return [["Merkez", "İlk Temas", "Görev bölgesini güvenceye al.", 2], ["Merkez", "Kriz Hattı", "Tahliye koridorunu kontrol et.", 2], ["Merkez", "Son Savunma", "Operasyonu tamamla.", 3]]

static func get_operation(country: String, index: int) -> Array:
    var list := get_operations(country)
    return list[clampi(index, 0, list.size() - 1)]
