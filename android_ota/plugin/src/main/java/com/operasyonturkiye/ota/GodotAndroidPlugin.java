package com.operasyonturkiye.ota;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.core.content.FileProvider;

import java.io.File;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public class GodotAndroidPlugin extends GodotPlugin {
    public GodotAndroidPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return BuildConfig.GODOT_PLUGIN_NAME;
    }

    @UsedByGodot
    public boolean canInstallPackages() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return true;
        }
        return getActivity().getPackageManager().canRequestPackageInstalls();
    }

    @UsedByGodot
    public void openInstallPermissionSettings() {
        runOnUiThread(() -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
                intent.setData(Uri.parse("package:" + getActivity().getPackageName()));
                getActivity().startActivity(intent);
            }
        });
    }

    @UsedByGodot
    public boolean installApk(String absolutePath) {
        File apk = new File(absolutePath);
        if (!apk.isFile() || apk.length() <= 0) {
            return false;
        }

        runOnUiThread(() -> {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !canInstallPackages()) {
                    openInstallPermissionSettings();
                    return;
                }

                Uri apkUri = FileProvider.getUriForFile(
                    getActivity(),
                    getActivity().getPackageName() + ".ota.fileprovider",
                    apk
                );

                Intent intent = new Intent(Intent.ACTION_INSTALL_PACKAGE);
                intent.setDataAndType(apkUri, "application/vnd.android.package-archive");
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                getActivity().startActivity(intent);
            } catch (Exception ignored) {
                // Installation remains user-driven by Android's package installer.
            }
        });
        return true;
    }
}
