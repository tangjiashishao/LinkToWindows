#!/system/bin/sh
MODDIR=${0%/*}

# Create temporary mount point
mkdir -p $MODDIR/mount_point
cp -af /system_ext/etc/selinux/system_ext_service_contexts $MODDIR/mount_point/ || exit 1

# Add service contexts if not present
grep -q "^cross_device_service[[:space:]]" $MODDIR/mount_point/system_ext_service_contexts || \
    echo "cross_device_service u:object_r:cross_device_service:s0" >> $MODDIR/mount_point/system_ext_service_contexts

grep -q "^vendor.virtual_keyboard[[:space:]]" $MODDIR/mount_point/system_ext_service_contexts || \
    echo "vendor.virtual_keyboard u:object_r:virtual_keyboard_service:s0" >> $MODDIR/mount_point/system_ext_service_contexts

# Move to module directory
mkdir -p $MODDIR/system/system_ext/etc/selinux
mv -f $MODDIR/mount_point/system_ext_service_contexts $MODDIR/system/system_ext/etc/selinux/system_ext_service_contexts || exit 1

# Set proper SELinux context
if [ -f "$MODDIR/system/system_ext/bin/virtual_keyboard" ]; then
    chcon u:object_r:virtual_keyboard_exec:s0 $MODDIR/system/system_ext/bin/virtual_keyboard || true
fi

# Cleanup
rm -rf $MODDIR/mount_point
