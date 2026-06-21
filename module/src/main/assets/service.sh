#!/system/bin/sh
MODDIR=${0%/*}

# Logging function
log_msg() {
    echo "[LinkToWindows] $1" >> /data/adb/modules/linktowindows/service.log
}

log_msg "Service script started at $(date)"

# Check if running on KSU/APatch or Magisk
if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
    log_msg "Running on KSU/APatch (KPM mode) - skipping Magisk SEPolicy"
else
    log_msg "Running on Magisk - applying SEPolicy"
    if [ -f "$MODDIR/sepolicy.rule" ]; then
        magiskpolicy --live --apply "$MODDIR/sepolicy.rule" || log_msg "Warning: SEPolicy application failed"
    fi
fi

# Wait for system to stabilize
log_msg "Waiting for package manager..."
for i in $(seq 1 30); do
    if pm list packages >/dev/null 2>&1; then
        log_msg "Package manager ready after $i seconds"
        break
    fi
    sleep 1
done

# Safely execute injectrc with timeout protection
if [ -f "$MODDIR/injectrc" ]; then
    log_msg "Preparing to execute injectrc"
    
    # Copy to tmp with safer permissions
    cp -af "$MODDIR/injectrc" /data/local/tmp/injectrc_ltw || {
        log_msg "ERROR: Failed to copy injectrc"
        exit 1
    }
    
    chmod +x /data/local/tmp/injectrc_ltw || {
        log_msg "ERROR: Failed to chmod injectrc"
        exit 1
    }
    
    # Execute with timeout (30 seconds max)
    timeout 30 /data/local/tmp/injectrc_ltw /system_ext/etc/init/virtual_keyboard.rc || {
        log_msg "WARNING: injectrc execution timeout or failed"
    }
    
    # Cleanup
    rm -f /data/local/tmp/injectrc_ltw
    log_msg "injectrc execution completed"
else
    log_msg "WARNING: injectrc not found"
fi

# Configure permissions for Microsoft apps
log_msg "Configuring app permissions..."

for pkg in com.microsoft.appmanager com.microsoft.deviceintegrationservice com.microsoftsdk.crossdeviceservicebroker; do
    if pm list packages | grep -q "^package:${pkg}$"; then
        log_msg "Configuring permissions for $pkg"
        
        for op in SYSTEM_ALERT_WINDOW POST_NOTIFICATION RUN_ANY_IN_BACKGROUND START_FOREGROUND; do
            cmd appops set "$pkg" "$op" allow >/dev/null 2>&1 || log_msg "WARNING: Failed to set appop $op for $pkg"
        done
    fi
done

# Grant dangerous permissions for com.microsoft.appmanager
for p in \
    android.permission.NEARBY_WIFI_DEVICES \
    android.permission.BLUETOOTH_SCAN \
    android.permission.RECORD_AUDIO \
    android.permission.GET_ACCOUNTS \
    android.permission.READ_EXTERNAL_STORAGE \
    android.permission.READ_MEDIA_IMAGES \
    android.permission.READ_MEDIA_VIDEO \
    android.permission.WRITE_EXTERNAL_STORAGE; do
    pm grant com.microsoft.appmanager "$p" >/dev/null 2>&1 || true
done

# Grant permissions for com.microsoft.deviceintegrationservice
for p in \
    android.permission.POST_NOTIFICATIONS \
    android.permission.BLUETOOTH_CONNECT; do
    pm grant com.microsoft.deviceintegrationservice "$p" >/dev/null 2>&1 || true
done

log_msg "Service script completed successfully"
