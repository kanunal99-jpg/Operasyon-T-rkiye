@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
    export_plugin = AndroidExportPlugin.new()
    add_export_plugin(export_plugin)

func _exit_tree() -> void:
    if export_plugin != null:
        remove_export_plugin(export_plugin)
        export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
    const PLUGIN_NAME := "OperasyonTurkiyeOTA"

    func _supports_platform(platform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_android_libraries(_platform, debug: bool) -> PackedStringArray:
        if debug:
            return PackedStringArray([PLUGIN_NAME + "/bin/debug/" + PLUGIN_NAME + "-debug.aar"])
        return PackedStringArray([PLUGIN_NAME + "/bin/release/" + PLUGIN_NAME + "-release.aar"])

    func _get_android_dependencies(_platform, debug: bool) -> PackedStringArray:
        return PackedStringArray(["androidx.core:core:1.13.1"])

    func _get_name() -> String:
        return PLUGIN_NAME
