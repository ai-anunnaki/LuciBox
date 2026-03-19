# Igigi工具箱 IgigiBox

一个功能强大的 macOS 系统工具箱应用，提供进程管理、文件管理、剪贴板管理和系统监控功能。

## 功能特性

### ✅ 进程管理
- 📊 查看所有系统进程（PID、进程名称、监听端口）
- 🔍 实时搜索过滤进程
- ⚡ 一键杀掉进程
- 🔄 实时刷新进程列表
- ⌨️ 快捷键：Cmd+1

### ✅ 文件管理
- 📁 浏览系统文件夹
- ➕ 新建文件夹
- ✏️ 重命名文件/文件夹
- 🗑️ 删除文件（移到废纸篓）
- 👁️ 打开文件/进入文件夹
- 📂 在 Finder 中显示
- 🔍 搜索文件
- ⌨️ 快捷键：Cmd+2

### ✅ 剪贴板管理
- 📋 查看当前剪贴板内容
- 📜 查看历史复制记录（最多100条）
- 🔄 一键复制历史内容
- 🗑️ 清空历史记录
- 🔍 搜索历史内容
- 💾 自动保存历史（持久化）
- ⌨️ 快捷键：Cmd+3

### ✅ 系统监控
- 💻 实时CPU使用率监控
- 🧠 内存使用率显示
- 💾 磁盘使用率统计
- 📡 网络上传/下载速度
- 📊 可视化图表展示
- ⌨️ 快捷键：Cmd+4

### ✅ 菜单栏模式
- 🎯 常驻菜单栏，快速访问
- 📊 实时显示系统状态
- 🚀 轻量级，不占用Dock空间
- ⌨️ 快捷键：Cmd+Shift+M 切换

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0 或更高版本（仅开发需要）

## 安装运行

### 方式一：从源码构建（推荐）

#### 1. 克隆仓库

```bash
git clone https://github.com/ai-anunnaki/IgigiBox.git
cd IgigiBox
```

#### 2. 使用 Xcode 打开项目

```bash
# 首先需要创建 Xcode 项目文件
# 打开 Xcode，选择 File > New > Project
# 选择 macOS > App
# 填写以下信息：
#   - Product Name: IgigiBox
#   - Team: 选择你的开发团队（或选择 None）
#   - Organization Identifier: com.anunnaki
#   - Bundle Identifier: com.anunnaki.Igigibox
#   - Interface: SwiftUI
#   - Language: Swift
#   - 取消勾选 Use Core Data
#   - 取消勾选 Include Tests

# 创建项目后，将以下文件添加到项目中：
# - IgigiBoxApp.swift（替换默认生成的）
# - ContentView.swift（替换默认生成的）
# - ProcessManager.swift
# - FileManagerView.swift
# - FileManagerContentView.swift
# - ClipboardManager.swift
# - ClipboardContentView.swift
# - Info.plist
```

#### 3. 配置项目设置

在 Xcode 中：

1. **选择项目** → **TARGETS** → **IgigiBox**
2. **General** 标签页：
   - Bundle Identifier: org.igigi.Igigibox
   - Minimum Deployments: macOS 13.0
3. **Signing & Capabilities** 标签页：
   - Team: 选择你的开发团队
   - 如果没有开发者账号，选择 "Sign to Run Locally"
   - **重要**：取消勾选 "App Sandbox"（或添加必要权限）

#### 4. 运行应用

```bash
# 方式 A：在 Xcode 中运行
# 按 Cmd + R 或点击运行按钮

# 方式 B：命令行构建
xcodebuild -scheme IgigiBox -configuration Debug
```

### 方式二：使用命令行构建

如果你熟悉命令行，可以使用以下脚本快速构建：

```bash
# 创建构建脚本
cat > build.sh << 'EOF'
#!/bin/bash

# 设置变量
APP_NAME="IgigiBox"
BUNDLE_ID="com.anunnaki.Igigibox"
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
    IgigiBoxApp.swift \
    ContentView.swift \
    ProcessManager.swift \
    FileManagerView.swift \
    FileManagerContentView.swift \
    ClipboardManager.swift \
    ClipboardContentView.swift

echo "构建完成: $APP_PATH"
echo "运行: open $APP_PATH"
EOF

chmod +x build.sh
./build.sh
```

## 打包发布

### 方式一：Xcode Archive（推荐）

1. **在 Xcode 中选择菜单**：Product > Archive
2. **等待归档完成**
3. **在 Organizer 窗口中**：
   - 选择刚才创建的 Archive
   - 点击 "Distribute App"
   - 选择 "Copy App"
   - 选择导出位置
4. **生成的 .app 文件**可以直接分发

### 方式二：命令行打包

```bash
# 创建打包脚本
cat > package.sh << 'EOF'
#!/bin/bash

APP_NAME="IgigiBox"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"

# 清理并创建目录
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 构建 Release 版本
xcodebuild -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build

# 复制 .app 到 dist 目录
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$DIST_DIR/"

# 创建 DMG 镜像（可选）
echo "创建 DMG 镜像..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DIST_DIR/$APP_NAME.app" \
    -ov -format UDZO \
    "$DIST_DIR/$APP_NAME-$VERSION.dmg"

echo "打包完成！"
echo "应用位置: $DIST_DIR/$APP_NAME.app"
echo "DMG 位置: $DIST_DIR/$APP_NAME-$VERSION.dmg"
EOF

chmod +x package.sh
./package.sh
```

### 方式三：创建 DMG 安装包

```bash
# 手动创建 DMG
# 1. 创建临时文件夹
mkdir -p dmg_temp
cp -R build/IgigiBox.app dmg_temp/

# 2. 创建 DMG
hdiutil create -volname "Igigi工具箱" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    IgigiBox-1.0.0.dmg

# 3. 清理
rm -rf dmg_temp

echo "DMG 创建完成: IgigiBox-1.0.0.dmg"
```

## 代码签名（可选）

如果你有 Apple Developer 账号，可以对应用进行代码签名：

```bash
# 查看可用的签名身份
security find-identity -v -p codesigning

# 签名应用
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    build/IgigiBox.app

# 验证签名
codesign --verify --verbose build/IgigiBox.app
spctl --assess --verbose build/IgigiBox.app
```

## 公证（Notarization）

如果要在 macOS 10.15+ 上分发，需要进行公证：

```bash
# 1. 创建 ZIP 包
ditto -c -k --keepParent build/IgigiBox.app IgigiBox.zip

# 2. 上传公证
xcrun notarytool submit IgigiBox.zip \
    --apple-id "your-apple-id@example.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# 3. 装订公证票据
xcrun stapler staple build/IgigiBox.app

# 4. 验证
spctl --assess -vv --type install build/IgigiBox.app
```

## 使用说明

### 进程管理
1. 启动应用后，默认显示所有系统进程
2. 使用搜索框可以按进程名或 PID 过滤
3. 点击"杀掉"按钮可以终止进程（需要确认）
4. 点击"刷新"按钮更新进程列表
5. 快捷键：Cmd+1 切换到此标签页

### 文件管理
1. 切换到"文件管理"标签页（Cmd+2）
2. 默认显示用户主目录
3. 双击文件夹可以进入
4. 点击"新建文件夹"创建文件夹
5. 使用操作按钮可以重命名、删除文件
6. 点击文件夹图标可以在 Finder 中显示

### 剪贴板管理
1. 切换到"剪贴板"标签页（Cmd+3）
2. 顶部显示当前剪贴板内容
3. 下方显示历史复制记录
4. 点击复制图标可以将历史内容复制到剪贴板
5. 支持搜索和清空历史

### 系统监控
1. 切换到"系统监控"标签页（Cmd+4）
2. 实时显示CPU、内存、磁盘使用率
3. 显示网络上传/下载速度
4. 每2秒自动刷新数据

### 菜单栏模式
1. 使用快捷键 Cmd+Shift+M 或菜单"视图 > 菜单栏模式"启用
2. 应用图标将出现在菜单栏
3. 点击图标查看快速系统信息
4. 关闭主窗口后应用继续在后台运行
5. 再次点击图标可以打开主窗口

### 快捷键列表
- Cmd+1：进程管理
- Cmd+2：文件管理
- Cmd+3：剪贴板管理
- Cmd+4：系统监控
- Cmd+Shift+M：切换菜单栏模式
- Cmd+,：打开设置

## 注意事项

⚠️ **重要提示**：

1. **进程管理**：
   - 杀掉系统关键进程可能导致系统不稳定
   - 某些进程需要管理员权限才能终止
   - 端口信息获取需要时间，首次加载可能较慢

2. **文件管理**：
   - 删除的文件会移到废纸篓，可以恢复
   - 操作系统文件需要管理员权限
   - 建议不要删除系统关键文件

3. **剪贴板管理**：
   - 历史记录保存在本地，重启应用后仍然存在
   - 最多保存 100 条历史记录
   - 敏感信息会被记录，请注意隐私

4. **权限**：
   - 应用需要完全磁盘访问权限才能管理所有文件
   - 在"系统偏好设置 > 安全性与隐私 > 隐私 > 完全磁盘访问权限"中添加应用

## 故障排除

### 无法打开应用（"已损坏"提示）

```bash
# 移除隔离属性
xattr -cr /Applications/IgigiBox.app

# 或允许任何来源的应用
sudo spctl --master-disable
```

### 无法杀掉某些进程

- 某些系统进程受保护，需要关闭 SIP（不推荐）
- 或使用 `sudo` 权限运行应用

### 文件操作失败

- 检查是否授予了"完全磁盘访问权限"
- 某些系统文件夹受保护，无法修改

## 技术栈

- **语言**：Swift 5.9+
- **框架**：SwiftUI, AppKit, Foundation
- **最低系统**：macOS 13.0 (Ventura)
- **开发工具**：Xcode 15.0+

## 项目结构

```
IgigiBox/
├── README.md                      # 本文件
├── BUILD.md                       # 构建说明（旧版）
├── Info.plist                     # 应用配置
├── IgigiBoxApp.swift              # 应用入口
├── ContentView.swift             # 进程管理视图
├── ProcessManager.swift          # 进程管理逻辑
├── FileManagerView.swift         # 文件管理逻辑
├── FileManagerContentView.swift  # 文件管理视图
├── ClipboardManager.swift        # 剪贴板管理逻辑
└── ClipboardContentView.swift    # 剪贴板管理视图
```

## 开发计划

- [x] 进程管理功能
- [x] 文件管理功能
- [x] 剪贴板管理功能
- [x] 系统监控（CPU、内存、磁盘、网络）
- [x] 快捷键支持
- [x] 菜单栏模式
- [ ] 深色模式优化
- [ ] 多语言支持（英文）
- [ ] 自定义主题
- [ ] 插件系统

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

Copyright (c) 2026 Igigi

## 联系方式

- GitHub: https://github.com/ai-anunnaki/IgigiBox
- Email: ai.anunnaki@proton.me
- Domain: igigi.org

---

**Igigi工具箱 IgigiBox** - 让 macOS 管理更简单 🚀
