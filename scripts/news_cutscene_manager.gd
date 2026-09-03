extends CanvasLayer

signal finished

var panel: Panel
var category_label: Label
var headline_label: Label
var body_label: Label
var location_label: Label
var progress_label: Label
var continue_button: Button
var skip_button: Button
var timer := 0.0
var card_index := 0
var cards: Array[Dictionary] = []
var active := false

func _ready() -> void:
    layer = 50
    panel = Panel.new()
    panel.position = Vector2(70, 70)
    panel.size = Vector2(1140, 580)
    add_child(panel)

    category_label = Label.new()
    category_label.position = Vector2(35, 28)
    category_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(category_label)

    headline_label = Label.new()
    headline_label.position = Vector2(35, 75)
    headline_label.size = Vector2(1070, 90)
    headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    headline_label.add_theme_font_size_override("font_size", 34)
    panel.add_child(headline_label)

    body_label = Label.new()
    body_label.position = Vector2(35, 180)
    body_label.size = Vector2(1070, 230)
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 22)
    panel.add_child(body_label)

    location_label = Label.new()
    location_label.position = Vector2(35, 430)
    location_label.size = Vector2(700, 40)
    panel.add_child(location_label)

    progress_label = Label.new()
    progress_label.position = Vector2(35, 475)
    panel.add_child(progress_label)

    continue_button = Button.new()
    continue_button.text = "DEVAM ET"
    continue_button.position = Vector2(820, 455)
    continue_button.size = Vector2(140, 60)
    continue_button.pressed.connect(_next_card)
    panel.add_child(continue_button)

    skip_button = Button.new()
    skip_button.text = "⏭ ATLA"
    skip_button.position = Vector2(970, 455)
    skip_button.size = Vector2(140, 60)
    skip_button.pressed.connect(skip)
    panel.add_child(skip_button)
    panel.visible = false

func play_briefing(country: String, city: String, operation: String, ally_count: int = 0) -> void:
    cards = [
        {"category": "DÜNYA HABERLERİ • SON DAKİKA", "headline": "SINIR HATTINDA GERİLİM TIRMANIYOR", "body": "%s çevresinde güvenlik alarmı verildi. Hükümetler olağanüstü toplantıya çağrıldı ve bölgedeki birlikler teyakkuz durumuna geçirildi." % country, "location": "CANLI YAYIN • %s" % city},
        {"category": "BAŞKANLIK AÇIKLAMASI", "headline": "ULUSAL GÜVENLİK TOPLANTISI SONA ERDİ", "body": "Kurgusal devlet başkanı yaptığı açıklamada ülkenin savunma hazırlıklarının artırıldığını duyurdu. Diplomatik kanallar açık tutulurken ordunun operasyon emri beklediği bildirildi.", "location": "BAŞKENT • ULUSAL BASIN MERKEZİ"},
        {"category": "DİPLOMASİ MASASI", "headline": "İTTİFAK HATTI HAREKETE GEÇİYOR", "body": "%d müttefik ülke destek görüşmelerine katılıyor. Lojistik, istihbarat ve savunma desteği için seçenekler masada. Ardından operasyon başlıyor: %s." % [ally_count, operation], "location": "ORTAK KRİZ MASASI • OPERASYON BRİFİNGİ"}
    ]
    card_index = 0
    timer = 0.0
    active = true
    panel.visible = true
    _show_card()

func _process(delta: float) -> void:
    if not active:
        return
    timer += delta
    if timer >= 5.0:
        _next_card()

func _show_card() -> void:
    if cards.is_empty():
        skip()
        return
    var card: Dictionary = cards[card_index]
    category_label.text = str(card["category"])
    headline_label.text = str(card["headline"])
    body_label.text = str(card["body"])
    location_label.text = str(card["location"])
    progress_label.text = "HABER %d / %d • Otomatik geçiş" % [card_index + 1, cards.size()]
    timer = 0.0

func _next_card() -> void:
    if not active:
        return
    card_index += 1
    if card_index >= cards.size():
        skip()
        return
    _show_card()

func skip() -> void:
    if not active:
        return
    active = false
    panel.visible = false
    finished.emit()
