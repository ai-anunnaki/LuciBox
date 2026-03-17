#!/bin/bash

# 设置变量
APP_NAME="LuciBox"
BUNDLE_ID="org.igigi.lucibox"
BUILD_DIR="build"

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 使用 swiftc 编译（需要手动创建 .app 包结构）
echo "正在编译..."

# 创建 .app 包结构
APP_PATH="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 复制 Info.plist
cp Info.plist "$APP_PATH/Contents/"

# 编译所有 Swift 文件
swiftc -o "$APP_PATH/Contents/MacOS/$APP_NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    LuciBoxApp.swift \
    MenuBarManager.swift \
    ContentView.swift \
    ProcessManager.swift \
    SystemMonitor.swift \
    SystemMonitorView.swift \
    FileManagerView.swift \
    FileManagerContentView.swift \
    ClipboardManager.swift \
    ClipboardContentView.swift

echo "构建完成: $APP_PATH"
echo "运行: open $APP_PATH"
