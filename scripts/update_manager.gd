extends Node

const CURRENT_VERSION := "0.1.5"
const RELEASES_API := "https://api.github.com/repos/kanunal99-jpg/Operasyon-T-rkiye/releases/latest"
const CHECK_INTERVAL := 21600.0

var request: HTTPRequest
var timer: Timer
var panel: PanelContainer
var status_label: Label
var update_button: Button
var download_url := ""

func _ready() -> void:
    request = HTTPRequest.new()
    request.timeout = 10.0
    add_child(request)
    request.request_completed.connect(_on_request_completed)
    timer = Timer.new()
    timer.wait_time = CHECK_INTERVAL
    timer.autostart = true
    timer.timeout.connect(check_for_update)
    add_child(timer)
    call_deferred("_build_ui")
    call_deferred("check_for_update")

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 220
    add_child(layer)
    panel = PanelContainer.new()
    panel.name = "UpdatePanel"
    panel.visible = false
    panel.custom_minimum_size = Vector2(360, 86)
    layer.add_child(panel)
    var box := HBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    status_label = Label.new()
    status_label.text = "Yeni sürüm mevcut"
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.custom_minimum_size = Vector2(220, 70)
    box.add_child(status_label)
    update_button = Button.new()
    update_button.text = "GÜNCELLE"
    update_button.custom_minimum_size = Vector2(115, 60)
    update_button.focus_mode = Control.FOCUS_NONE
    update_button.pressed.connect(_open_update)
    box.add_child(update_button)
    _layout_ui()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _layout_ui()

func _layout_ui() -> void:
    if panel == null:
        return
    var size := get_viewport().get_visible_rect().size
    panel.position = Vector2(maxf(8.0, size.x - panel.custom_minimum_size.x - 12.0), 12.0)

func check_for_update() -> void:
    if request == null or request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    var headers := PackedStringArray(["Accept: application/vnd.github+json", "User-Agent: Operasyon-Turkiye-Update-Checker"])
    request.request(RELEASES_API, headers, HTTPClient.METHOD_GET)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var latest_version := str(parsed.get("tag_name", "")).trim_prefix("v")
    if latest_version.is_empty() or not _is_newer(latest_version, CURRENT_VERSION):
        return
    var assets: Array = parsed.get("assets", [])
    for asset in assets:
        if typeof(asset) == TYPE_DICTIONARY and str(asset.get("name", "")).ends_with(".apk"):
            download_url = str(asset.get("browser_download_url", ""))
            break
    if download_url.is_empty():
        return
    _show_update(latest_version)

func _is_newer(candidate: String, current: String) -> bool:
    var a := candidate.split(".")
    var b := current.split(".")
    for i in range(maxi(a.size(), b.size())):
        var av := int(a[i]) if i < a.size() and a[i].is_valid_int() else 0
        var bv := int(b[i]) if i < b.size() and b[i].is_valid_int() else 0
        if av != bv:
            return av > bv
    return false

func _show_update(version: String) -> void:
    if panel == null:
        return
    status_label.text = "YENİ SÜRÜM %s\nGüncelleme hazır." % version
    panel.visible = true
    _layout_ui()

func _open_update() -> void:
    if not download_url.is_empty():
        OS.shell_open(download_url)
