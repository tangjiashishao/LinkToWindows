#!/system/bin/sh
# Safely uninstall by removing module files
# This prevents bootloop by not leaving orphaned system modifications

MODDIR=${0%/*}

# Clean shutdown
echo "LinkToWindows module uninstalled safely" >> $MODDIR/uninstall.log
