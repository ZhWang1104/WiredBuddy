<p align="center">
  <img height="128" width="128" src="Resources/1024x1024px_hintergrund-128.png" alt="Wired Buddy 图标">
</p>

<h1 align="center">Wired Buddy</h1>

<p align="center">轻量、离线、可长期维护的 macOS 有线网络状态栏工具</p>

<p align="center">
  <a href="https://github.com/ZhWang1104/WiredBuddy/actions/workflows/build.yml"><img src="https://github.com/ZhWang1104/WiredBuddy/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-lightgrey" alt="macOS 13+">
  <img src="https://img.shields.io/badge/UI-SwiftUI-orange" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ZhWang1104/WiredBuddy" alt="MIT License"></a>
</p>

Wired Buddy 常驻 macOS 菜单栏，用来显示以太网接口、连接状态以及 IPv4/IPv6 地址。它能区分“有线接口可用”和“有线接口正在承担默认路由”，因此在 Wi-Fi、VPN 或其他网络优先时，也不会把仍然存在的有线连接误报为断开。

> English: Wired Buddy is a small, offline macOS menu bar utility that reports Ethernet availability, default-route preference, and IPv4/IPv6 addresses. This maintained fork focuses on correctness, reproducible builds, and long-term use.

![Wired Buddy 已连接状态](.github/active.jpeg)

## 功能

- 显示当前有线接口、IPv4 和 IPv6 地址。
- 分别报告“已连接”和“首选连接”，避免混淆物理连接与默认路由。
- 在 Wi-Fi、VPN 或其他接口优先时继续报告以太网状态。
- 支持多种菜单栏图标、状态颜色和紧凑菜单。
- 支持登录时启动，可直接打开 macOS 网络设置。
- 仅观察本机网络配置，不发送网络请求、不收集分析数据。
- 依赖固定到精确版本或 Git 提交，降低未来构建漂移风险。

## 系统要求

- macOS 13 Ventura 或更高版本。
- 从源码构建需要 Xcode 15 或更高版本。
- 本地打包脚本使用当前 Mac 的原生架构；公开发布仍需 Developer ID 签名与 Apple 公证。

## 安装与构建

### 直接下载（Apple Silicon）

[下载 Wired Buddy 0.2 Hardened](https://github.com/ZhWang1104/WiredBuddy/releases/tag/v0.2.0-hardened.1)，解压后将应用移入 `/Applications`。该附件适用于 M1、M2、M3、M4 或后续 arm64 Mac，使用临时签名且未经过 Apple 公证；具体限制和校验值见 Release 页面。

### 使用 Xcode

```sh
git clone https://github.com/ZhWang1104/WiredBuddy.git
cd WiredBuddy
open "Wired Buddy.xcodeproj"
```

在 Xcode 中选择 **Wired Buddy** target，在 **Signing & Capabilities** 中选择自己的开发团队，等待 Swift Package Manager 解析固定依赖后构建运行。

### 生成本机应用包

已安装 Swift 命令行工具时，可以运行：

```sh
Scripts/build-local-app.sh "$PWD/Wired Buddy-local.app"
```

该脚本会生成临时签名的本机架构应用，适合自用，不等同于经过 Developer ID 签名和 Apple 公证的公开发行版本。脚本不会覆盖已经存在的输出路径。

建议先将应用移动到 `/Applications`，确认安装路径固定后再启用“登录时启动”。

## 状态含义

| 显示状态 | 含义 |
| --- | --- |
| 已连接 | 存在一条受限于有线以太网、当前可用的网络路径 |
| 首选连接 | 当前系统默认网络路径使用有线以太网 |
| IPv4 / IPv6 | 选定有线接口上的首选地址；优先全局或私有地址，必要时回退到链路本地地址 |

有线网络可以处于“已连接但不是首选连接”的状态，例如系统当前选择 Wi-Fi 或另一条路由时。

## 验证

```sh
Scripts/verify-network.sh
swift build --target WiredBuddyBuildCheck
swift test
```

- `verify-network.sh` 检查状态解析以及真实 IPv4/IPv6 地址枚举。
- `WiredBuddyBuildCheck` 编译全部应用 Swift 源码与固定依赖。
- `swift test` 运行标准 XCTest，需要完整 Xcode 环境。
- GitHub Actions 还会执行关闭代码签名的 Xcode 项目构建。

长期维护和实体设备测试矩阵见 [MAINTENANCE.md](MAINTENANCE.md)。

## 隐私与权限

应用仅保留 App Sandbox 权限，不声明网络客户端、网络服务端或关闭库验证等额外 entitlement。它不包含遥测、账户系统或后台服务器通信。

## 主要加固内容

相对上游版本，本维护分支主要补充了：

- 默认路径与有线路径的双重监控。
- IPv4/IPv6 安全枚举及系统调用错误处理。
- 偏好值边界检查和统一持久化。
- 启动场景、设置窗口及紧凑模式行为修复。
- 精确依赖锁定、自动化测试和持续集成。
- 最小化沙盒权限、可复现本地打包和发行维护文档。
- Homebrew Cask 元数据修复。

## 上游与许可证

本仓库基于 [yeahitsjan/WiredBuddy](https://github.com/yeahitsjan/WiredBuddy) 维护，保留原项目历史和 MIT 许可证。欢迎通过 Issue 报告真实设备和新版 macOS 上的问题；提交问题时请附 macOS 版本、Mac 架构、有线接口名称及是否同时启用 Wi-Fi/VPN。

Wired Buddy 按 [MIT License](LICENSE) 发布，第三方依赖保留各自许可证。
