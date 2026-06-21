#!/system/bin/sh

SKIPUNZIP=0
AUTOMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

# Safety checks
if [ "$ARCH" != arm64 ]; then
  ui_print "-----------------------------------------------------------"
  ui_print "! This module is only available for arm64 devices"
  abort "-----------------------------------------------------------"
fi

# Display running environment
if [ "$KSU" = "true" ]; then
  ui_print "- KernelSU version: $KSU_VER ($KSU_VER_CODE)"
elif [ "$APATCH" = "true" ]; then
  APATCH_VER=$(cat "/data/adb/ap/version")
  ui_print "- APatch version: $APATCH_VER ($APATCH_VER_CODE)"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

# Check system_ext selinux context file
if [ ! -f /system_ext/etc/selinux/system_ext_service_contexts ]; then
  ui_print "-----------------------------------------------------------"
  ui_print "! /system_ext/etc/selinux/system_ext_service_contexts not found"
  ui_print "! This device's SEPolicy layout is incompatible with the module"
  abort "-----------------------------------------------------------"
fi

ui_print "- Patching SELinux service contexts…"
mkdir -p $MODPATH/system/system_ext/etc/selinux
cp -af /system_ext/etc/selinux/system_ext_service_contexts $MODPATH/system/system_ext/etc/selinux/

# Add service contexts if not present
grep -q "^cross_device_service[[:space:]]" $MODPATH/system/system_ext/etc/selinux/system_ext_service_contexts || \
    echo "cross_device_service u:object_r:cross_device_service:s0" >> $MODPATH/system/system_ext/etc/selinux/system_ext_service_contexts

grep -q "^vendor.virtual_keyboard[[:space:]]" $MODPATH/system/system_ext/etc/selinux/system_ext_service_contexts || \
    echo "vendor.virtual_keyboard u:object_r:virtual_keyboard_service:s0" >> $MODPATH/system/system_ext/etc/selinux/system_ext_service_contexts

ui_print "- Setting permissions…"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/system/system_ext/bin 0 2000 0751 0755

# Create logging directory
mkdir -p $MODPATH
touch $MODPATH/service.log
set_perm $MODPATH/service.log 0 0 0644

ui_print "- Installing Microsoft apps…"
for entry in \
    "com.microsoft.deviceintegrationservice:system/product/priv-app/DeviceIntegrationService/DeviceIntegrationService.apk" \
    "com.microsoft.appmanager:system/product/priv-app/LinkToWindows/LinkToWindows.apk" \
    "com.microsoftsdk.crossdeviceservicebroker:system/system_ext/app/CrossDeviceServiceBroker/CrossDeviceServiceBroker.apk"; do
    pkg="${entry%%:*}"
    apk="${entry#*:}"
    if pm list packages | grep -q "^package:${pkg}$"; then
        ui_print "- $pkg already installed, skipping…"
    else
        if [ -f "$MODPATH/$apk" ]; then
            ui_print "- Installing $pkg…"
            size=$(stat -c%s "$MODPATH/$apk")
            result=$(pm install -r -d -S "$size" < "$MODPATH/$apk" 2>&1) || ui_print "  ! $result"
        else
            ui_print "- Warning: $apk not found in module"
        fi
    fi
done

ui_print "- Installation complete. System will be more stable."
ui_print "- Module requires reboot to activate."
