# LinkToWindows SukiSU Ultra Fix

## 问题分析 (Problem Analysis)

该模块在 SukiSU Ultra 上导致反复重启，主要原因包括：

### 1. **SEPolicy 不兼容**
- 原始的 SEPolicy 规则缺少 SukiSU Ultra 所需的关键权限
- `property_socket` 权限缺失导致属性访问失败
- Zygisk 模块权限声明不完整

### 2. **初始化时序问题**
- `injectrc` 执行时系统尚未完全初始化
- 无超时保护，导致无限等待
- 错误处理不完善

### 3. **Magisk 策略应用失败**
- SukiSU Ultra 不支持 `magiskpolicy` 命令
- 模块未正确检测运行环境

## 修复内容 (Fixes Applied)

### ✅ module.prop
- 更新版本号为 2.0
- 添加明确的 KPM 标记
- 更新描述信息

### ✅ sepolicy.rule
- 添加 `property_socket` 权限
- 添加 `kernel unix_stream_socket` 权限（SukiSU 兼容性）
- 添加 `dontaudit` 规则以抑制非关键权限拒绝
- 完善 uhid_device 权限

### ✅ service.sh
- 添加详细的日志记录
- 正确检测 KSU/APatch/Magisk 环境
- 添加 30 秒超时保护
- 改进错误处理
- 包名变更为 `injectrc_ltw` 以避免冲突

### ✅ customize.sh
- 添加安装日志目录
- 改进 APK 存在性检查
- 更友好的安装消息
- 添加权限设置日志

### ✅ post-fs-data.sh
- 添加清理机制
- 改进错误处理

### ✅ uninstall.sh
- 安全卸载机制
- 防止留下孤立的系统修改

## 使用方式 (Usage)

1. 在 SukiSU Ultra 中安装此固定版本
2. 重启设备
3. 检查 `/data/adb/modules/linktowindows/service.log` 了解运行状态
4. 如仍有问题，禁用模块并在 SukiSU 中进行系统恢复

## 安全保障 (Safety Features)

- ✅ 超时保护：防止无限等待
- ✅ 环境检测：正确识别运行环境
- ✅ 日志记录：完整的故障诊断
- ✅ 错误处理：优雅降级而非崩溃
- ✅ 安全卸载：防止卸载后的引导问题

## 故障排查 (Troubleshooting)

如模块仍导致重启：

1. 进入 SukiSU 恢复模式
2. 禁用所有模块
3. 重启验证
4. 逐个启用模块进行测试
5. 检查日志：`logcat | grep LinkToWindows`

## 参考文档 (References)

- SukiSU Ultra 集成指南：https://github.com/SukiSU-Ultra/SukiSU-Ultra/blob/main/docs/guide/how-to-integrate.md
- KPM 构建模板：https://github.com/udochina/KPM-Build-Anywhere
- LSPosed API：https://github.com/libxposed/api
