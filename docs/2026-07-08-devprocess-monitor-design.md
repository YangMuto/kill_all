# DevProcess Monitor（KillAll）设计文档

日期：2026-07-08

## 背景 / 问题
用 AI coding 时经常在后台留下没结束的开发进程（`npm run dev` → 子 `node`、`vite`、`python` 服务器等），
越攒越多导致电脑变卡。需要一个常驻的小工具，一眼看到这些进程、快速杀掉。

## 目标
- 菜单栏常驻，随时查看当前运行的开发相关进程列表。
- 每个进程显示：名称、PID、已运行时长、CPU、内存。
- 运行超过 1 小时的进程整行标红。
- 单个 Kill，或一键 Kill All（带确认）。
- 真正释放资源：杀进程时连带杀掉其所有子孙进程（进程树）。

## 技术选型
- **原生 SwiftUI `MenuBarExtra`**（macOS 13+，本机 macOS 14 + Xcode 15/Swift 5.10）。
- 菜单栏弹出面板样式 `.menuBarExtraStyle(.window)`。
- 非沙盒运行（开发者工具需要读取并 kill 其它进程）。
- 用 SwiftPM 编译，脚本封装成 `KillAll.app`（`LSUIElement=true`，不占 Dock）。

## 架构
三层 + 视图：

| 组件 | 职责 | 依赖 |
|---|---|---|
| `ProcessScanner` | 调用 `/bin/ps` 拿到全部进程原始快照并解析 | Foundation `Process` |
| `DevProcessFilter` | 从全量进程里筛出开发相关进程；排除自身/GUI 助手/其它用户 | — |
| `ProcessKiller` | 按 ppid 递归算进程树；发送 SIGTERM/SIGKILL | Darwin `kill(2)` |
| `ProcessMonitor` (ViewModel) | 定时刷新、维护列表、编排 kill、暴露 `@Published` | 上面三者 |
| `MenuPanelView` / `ProcessRowView` | 弹出面板 UI | ProcessMonitor |

### 数据流
`Timer(3s) → ProcessScanner(ps) → 全量 RawProcess → DevProcessFilter → [DevProcess] → SwiftUI List`
Kill：`用户点击 → ProcessKiller.processTree(全量快照) → SIGTERM → 2s 后存活者 SIGKILL → 重扫`

### ps 数据源
`/bin/ps -axww -o pid=,ppid=,etimes=,pcpu=,rss=,uid=,command=`
- 空表头（`=`）省去表头解析；`command` 放最后（含空格）。
- `etimes` = 启动至今秒数，直接用于 1 小时阈值。
- 按 `uid == getuid()` 过滤，只留当前用户可 kill 的进程（数字 UID 不会被截断）。

### 开发进程识别（DevProcessFilter）
匹配任一即算开发进程：
- arg0 basename ∈ 运行时集合（node/python/ruby/java/go/deno/bun/php/cargo/gradle…）
- 任一 token basename ∈ 开发 CLI 集合（npm/pnpm/yarn/vite/webpack/tsc/jest/uvicorn/gunicorn/jupyter…）
- command 含脚本标记（manage.py / npm-cli.js / webpack / vite / uvicorn…）

排除：本 App 自身 PID、非当前用户、路径含 `.app/Contents/` 的 GUI 助手（VS Code/Cursor/Electron 噪音）。
> 显示层宽进宽出没有危险（kill 需显式点击），宁可多显示也别漏掉真正的僵尸进程。

## 关键行为
- **标红阈值**：`elapsedSeconds >= 3600`，整行红色。阈值为集中常量，易改。
- **杀进程树**：默认对「进程 + 所有子孙」发 SIGTERM，2 秒后仍存活的升级 SIGKILL。守卫 `pid > 1`、排除自身。
- **Kill All**：对当前列表所有进程树操作，二次确认弹窗。
- **自动刷新**：每 3 秒；kill 后立即重扫，已死进程从列表消失。

## 边界 / 错误处理
- `ps` 失败或解析异常 → 面板显示错误提示，不崩溃。
- kill 目标已退出 → `kill` 返回非 0，静默忽略。
- 绝不向 pid 0（进程组广播）或 pid 1（init）发信号。

## 交付
`./build_app.sh` → `swift build -c release` → 组装 `KillAll.app`（Info.plist + ad-hoc 签名）→ `open ./KillAll.app`。

## 明确不做（v1 YAGNI）
- 登录时自启动（v2）。
- 阈值/刷新间隔的设置界面（先用常量）。
- 监控其它用户 / root 进程（需要提权）。
- 持久化历史、通知中心告警。
