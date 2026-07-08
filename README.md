# KillAll — Dev Process Monitor

一个 macOS 菜单栏小工具，专治 AI coding 留在后台没结束的开发进程（`node` / `python` / `vite` /
`webpack` / `uvicorn` …）。列表展示、运行超 1 小时标红、一键 Kill 单个或 Kill All。

## 特性
- 🧭 **菜单栏常驻**，不占 Dock（`LSUIElement`）。
- 📋 **进程列表**：名称、PID、运行时长、CPU、内存、**来源目录**（哪个项目起的），按时长倒序。
- 🔴 **超 1 小时标红**，菜单栏图标变成警告三角。
- 💀 **Kill / Kill All**：默认杀掉整棵进程树（父进程 + 所有子孙），先 `SIGTERM`，2 秒后仍存活升级 `SIGKILL`。真正释放资源，不留孤儿进程。
- 📁 **来源目录**：每行显示进程的工作目录（`lsof` 取 cwd，`~` 缩写），一眼认出是哪个项目的残留进程。
- 🧩 **GUI 助手开关**（底部勾选框，默认关）：打开后连 VS Code / Cursor / Electron 派生的 Node 助手进程一起显示，带 `app` 标记提示；设置持久化。
- 🔄 每 3 秒自动刷新。

## 构建 & 运行
```bash
./build_app.sh          # 编译并打包成 KillAll.app
open ./KillAll.app      # 启动，菜单栏出现图标
```
需要 macOS 13+、已安装 Xcode / Swift 工具链。

开发调试也可直接：
```bash
swift build
swift run
```

## 只显示当前用户的开发进程
- 通过 `uid == getuid()` 过滤，只列出你能 kill 的进程。
- 自动排除 App 自身、以及位于 `.app/Contents/` 里的 GUI 助手进程（VS Code / Cursor / Electron 噪音）。

## 想调整？
- **标红阈值**：`Sources/KillAll/ViewModel/ProcessMonitor.swift` 里的 `redThresholdSeconds`。
- **刷新间隔**：同文件的 `refreshInterval`。
- **识别哪些算开发进程**：`Sources/KillAll/Core/DevProcessFilter.swift` 里的
  `devExecutables` / `devCLINames` / `scriptMarkers`。

## 项目结构
```
Sources/KillAll/
  KillAllApp.swift              # @main，MenuBarExtra 场景
  Models/DevProcess.swift       # 展示用数据模型
  Core/ProcessScanner.swift     # 调 ps，解析全量进程
  Core/DevProcessFilter.swift   # 筛出开发进程
  Core/ProcessKiller.swift      # 进程树计算 + 发信号
  ViewModel/ProcessMonitor.swift# 定时刷新 + kill 编排（@Published）
  Views/MenuPanelView.swift     # 弹出面板
  Views/ProcessRowView.swift    # 单行
Info.plist                      # LSUIElement 菜单栏 App
build_app.sh                    # 打包脚本
docs/                           # 设计文档
```

## 说明 / 限制（v1）
- 只监控当前用户的进程（杀 root/其它用户进程需要提权，暂不做）。
- 未做登录自启动、设置界面（阈值/刷新用常量，改代码即可）。
- 未做签名分发，本地 ad-hoc 签名自用。
