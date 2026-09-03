extends Node

# Country -> city -> operation data. This is deliberately data-driven so full
# country/city content can be expanded without rewriting gameplay code.
const OPERATIONS := {
    "Türkiye": [["İstanbul", "Boğaz Hattı", "Şehir içinde keşif ekibini durdur.", 1], ["Ankara", "Başkent Savunması", "Kritik bölgeyi savun.", 2], ["İzmir", "Ege Kıyısı", "İletişim merkezini ele geçir.", 2]],
    "Yunanistan": [["Atina", "Akropolis Hattı", "Kentsel tehdidi etkisizleştir.", 2], ["Selanik", "Kuzey Geçidi", "İkmal hattını güvenceye al.", 2]],
    "Almanya": [["Berlin", "Gece Koridoru", "Şehir operasyonunu tamamla.", 3], ["Hamburg", "Liman Görevi", "Liman bölgesini temizle.", 3]],
    "Fransa": [["Paris", "Şehir Işıkları", "Ana iletişim noktasını kontrol et.", 3], ["Marsilya", "Liman Hattı", "Kıyı operasyonunu tamamla.", 3]],
    "İtalya": [["Roma", "Tarihî Hat", "Görev bölgesini güvenceye al.", 3], ["Milano", "Kuzey Operasyonu", "Hedef ekibi takip et.", 3]],
    "İspanya": [["Madrid", "Başkent Görevi", "Operasyon merkezine ulaş.", 3], ["Barselona", "Kıyı Operasyonu", "Kıyı hattını savun.", 3]],
    "ABD": [["Washington", "Başkent Krizi", "Kritik bölgeyi koru.", 4], ["New York", "Metropol Hattı", "Şehir görevini tamamla.", 4]],
    "Kanada": [["Ottawa", "Kuzey Görevi", "Görev alanını güvenceye al.", 3], ["Toronto", "Metropol Savunması", "Ekibi tahliye et.", 3]],
    "Meksika": [["Mexico City", "Şehir Operasyonu", "Hedef bölgeyi kontrol et.", 3], ["Monterrey", "Kuzey Hattı", "İkmal hattını koru.", 3]],
    "Brezilya": [["Brasília", "Federal Hat", "Operasyon merkezini savun.", 4], ["São Paulo", "Metropol Görevi", "Şehir hattını güvenceye al.", 4]],
    "Mısır": [["Kahire", "Nil Hattı", "Görev bölgesini temizle.", 3], ["İskenderiye", "Akdeniz Kapısı", "Limanı güvenceye al.", 3]],
    "Fas": [["Rabat", "Atlas Görevi", "İletişim merkezini kontrol et.", 2], ["Kazablanka", "Liman Hattı", "Kıyı bölgesini savun.", 3]],
    "Suudi Arabistan": [["Riyad", "Çöl Operasyonu", "İleri karakolu güvenceye al.", 4], ["Cidde", "Kızıldeniz Hattı", "Liman hattını savun.", 4]],
    "İran": [["Tahran", "Başkent Hattı", "Kritik bölgeyi kontrol et.", 4], ["İsfahan", "Merkez Operasyonu", "Görev ekibini durdur.", 4]],
    "Irak": [["Bağdat", "Dicle Hattı", "Şehir operasyonunu tamamla.", 4], ["Basra", "Güney Limanı", "Liman bölgesini güvenceye al.", 4]],
    "Hindistan": [["Yeni Delhi", "Başkent Operasyonu", "Görev merkezini ele geçir.", 4], ["Mumbai", "Kıyı Hattı", "Metropol hattını savun.", 4]],
    "Pakistan": [["İslamabad", "Kuzey Başkent", "Kritik noktayı koru.", 4], ["Karaçi", "Liman Savunması", "Liman hattını güvenceye al.", 4]],
    "Çin": [["Pekin", "Doğu Hattı", "Operasyon merkezini kontrol et.", 5], ["Şanghay", "Metropol Operasyonu", "Görev zincirini tamamla.", 5]],
    "Japonya": [["Tokyo", "Neon Hattı", "Şehir merkezine ulaş.", 5], ["Osaka", "Kentsel Görev", "Hedef bölgeyi güvenceye al.", 5]],
    "Güney Kore": [["Seul", "Han Nehri Hattı", "Şehir savunmasını tamamla.", 4], ["Busan", "Liman Operasyonu", "Kıyı hattını kontrol et.", 4]],
    "Avustralya": [["Canberra", "Güney Görevi", "Başkent bölgesini savun.", 4], ["Sydney", "Liman Hattı", "Kıyı operasyonunu tamamla.", 4]],
    "Yeni Zelanda": [["Wellington", "Ada Savunması", "Başkent bölgesini güvenceye al.", 3], ["Auckland", "Kuzey Limanı", "Liman hattını kontrol et.", 3]]
}

static func get_operations(country: String) -> Array:
    return OPERATIONS.get(country, [["Merkez", "İlk Temas", "Görev bölgesini güvenceye al.", 2]])

static func get_operation(country: String, index: int) -> Array:
    var list := get_operations(country)
    return list[clampi(index, 0, list.size() - 1)]
