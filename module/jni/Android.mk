LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := linktowindows
LOCAL_SRC_FILES := \
    src/main/cpp/sepolicy_patch.c \
    src/main/cpp/module_entry.c
LOCAL_SHARED_LIBRARIES := libxposed
include $(BUILD_SHARED_LIBRARY)
