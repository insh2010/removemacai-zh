# RemoveMacAI 简体中文汉化版（removemacai-zh）

基于官方 [RemoveMacAI](https://github.com/omlahore/RemoveMacAI) **v1.1.3**（MIT 开源）的完整简体中文本地化。

- GUI 与 CLI 共约 **580 处字符串**全部汉化（含三步向导、功能列表、存储清理、撤销、报错信息、`--help`）
- **功能零改动**：仅做字符串替换，未改任何逻辑
- 已在 macOS 27.0.1 + Apple Silicon（M1）上编译并验证通过

## 仓库内容

| 路径 | 说明 |
|---|---|
| `Sources/` | 汉化后的完整可编译源码（与原版结构一致） |
| `scripts/localize.py` | 汉化脚本，含完整英→中翻译映射表，可对官方新版本重跑 |
| `UPSTREAM-README.md` | 官方 v1.1.3 原版 README 归档（出处留存） |
| `Package.swift` / `LICENSE` / `.gitignore` | 工程配置与原 MIT 许可证 |

## 汉化操作流程（如何复现）

> 对官方**新版本**（如 v1.2+）汉化，或核对本仓库翻译的生成过程：

```bash
# 1. 获取官方源码
git clone https://github.com/omlahore/RemoveMacAI.git
cd RemoveMacAI

# 2. 放入汉化脚本并执行（脚本会就地修改 Sources/ 下所有 .swift）
cp /path/to/removemacai-zh/scripts/localize.py .
python3 localize.py
#   期望输出：TOTAL replacements: 573 以及 usage replaced: 1
#   573 处 = GUI/CLI 字符串；usage 整段 = 命令行帮助

# 3. 编译
swift build -c release

# 4. 组装 .app 并安装（见下）
```

汉化脚本说明：
- 基于**字符串字面量精确匹配**替换，不触碰命令参数、plist 键、bundle id、URL 等非展示文本
- 含上下文保护：`Term.green("off")` 等 CLI 状态标签走单独上下文替换，避免误伤命令判断
- 若官方新版本新增字符串，脚本会跳过未收录的新文本（保持英文），把新英文追加进 `localize.py` 的 `TR` 字典即可

## 构建与安装（macOS）

### 编译

```bash
swift build -c release          # 需要 Swift 5.10+ / Xcode，无外部依赖
```

### 方式 A：替换已安装的官方版（推荐，图标/Info.plist 完整）

```bash
# 1. 组装汉化 bundle（以官方已装版为基础）
cp -R /Applications/RemoveMacAI.app /tmp/RemoveMacAI-zh.app
cp .build/release/removemacai /tmp/RemoveMacAI-zh.app/Contents/MacOS/RemoveMacAI

# 2. 本地签名（无开发者证书，ad-hoc 即可）
codesign --force --deep --sign - /tmp/RemoveMacAI-zh.app

# 3. 备份原版（移动而非删除）
mkdir -p ~/Documents/RemoveMacAI-backup
mv /Applications/RemoveMacAI.app ~/Documents/RemoveMacAI-backup/RemoveMacAI.app

# 4. 汉化版就位并启动
cp -R /tmp/RemoveMacAI-zh.app /Applications/RemoveMacAI.app
open /Applications/RemoveMacAI.app
```

### 方式 B：全新安装（无官方版时）

按标准 macOS bundle 结构组装，`Contents/Info.plist` 可参考官方版（`CFBundleIdentifier=io.github.omlahore.removemacai.app`、`CFBundleShortVersionString=1.1.3`），资源放 `Contents/Resources/AppIcon.icns`。

### 注意

- 汉化版为 **ad-hoc 本地签名**，首次打开若提示“无法验证开发者”，到 系统设置 → 隐私与安全性 → 点 **仍然打开** 即可
- 官方版后续更新时：拉新版源码 → 重跑 `localize.py` → 重编译 → 按方式 A 替换

## 汉化范围与有意保留

**已汉化**：侧边栏、概览、Apple Intelligence、隐私、烦扰项、Apple 应用、访达、程序坞与窗口、输入、存储空间、撤销、三步向导、预设说明、安全卡片、系统报错、CLI 输出、`--help`。

**有意保留英文**：
- Apple 官方功能名：`Apple Intelligence`、`Siri`、`Genmoji`、`Image Playground`、`Writing Tools`、`Game Center` 等（中文系统下 Apple 官方同样显示英文，保留更准确）
- 标准菜单栏（Edit / View / Window / Help，系统级默认菜单，非界面文案）
- 品牌名 `RemoveMacAI`

## 验证方式

- `swift build -c release` 编译通过
- 启动 app 后通过辅助功能读取窗口树，确认界面全中文（含 `9 / 41` 徽标格式）
- 功能逻辑与官方 v1.1.3 一致（仅字符串替换）

## 版权

- 原项目：RemoveMacAI © om lahore，MIT License，<https://github.com/omlahore/RemoveMacAI>
- 本仓库为原项目的本地化衍生，保留原 MIT 许可证（`LICENSE`）
- 官方原文 README 见 `UPSTREAM-README.md`
