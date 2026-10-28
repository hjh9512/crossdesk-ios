# CrossDesk iOS IPA 打包仓库

基于已编译的**未签名 iOS 应用包**（arm64）搭建的 GitHub 仓库，内置 GitHub Actions 工作流，
一键产出 `.ipa` 文件：默认不签名直接打包；配置证书后可选签名模式，产出可直接安装 /
上传 TestFlight / 提交 App Store 的 IPA。

## 应用信息

| 项目 | 值 |
|---|---|
| 应用名 | CrossDesk |
| Bundle ID | `cn.crossdesk.mobile` |
| 版本 | 1.7.3（build 3，以 `Info.plist` 为准，工作流自动读取） |
| 架构 | arm64 |
| 最低系统 | iOS 16.0 |
| 签名状态 | 未签名（本包） |
| 源码 | [github.com/kunkundi/crossdesk](https://github.com/kunkundi/crossdesk)（tag `v1.7.3-1-20261026`） |

## 目录结构

```
├── .github/workflows/build-ipa.yml   # GitHub Actions 打包工作流
├── CrossDeskMobile.app/              # 预编译的 iOS 应用包（未签名）
├── CrossDeskMobile.app.dSYM/         # 崩溃符号（用于 Crash 日志符号化，随 CI 一并产出）
├── scripts/
│   ├── package-ipa.ps1               # Windows 本地打包脚本
│   └── package-ipa.sh                # macOS / Linux 本地打包脚本
├── signing/
│   ├── entitlements.plist            # entitlements 参考模板（CI 从描述文件自动提取）
│   └── README.md                     # 签名 Secrets 配置指南
├── SourceMetadata.json               # 源码元信息（原包自带）
├── ThirdPartySources.json            # 第三方源码清单（原包自带）
├── OPEN_SOURCE_NOTICE.txt            # 开源声明（原包自带）
├── .gitignore
└── README.md
```

## 快速开始（GitHub Actions）

1. 在 GitHub 新建仓库，将本目录内容推上去（见「推送到 GitHub」）。
2. 打开仓库 **Actions** 页 → 选择 **Build IPA** → **Run workflow**。
3. 等待约 1~2 分钟，在运行记录页 **Artifacts** 下载 `ipa-unsigned`（含 `.ipa` 文件）。

## 两种打包模式

| 模式 | 说明 | 产物用途 |
|---|---|---|
| `unsigned`（默认） | 不签名，直接将 `.app` 按 `Payload/` 标准结构打成 IPA | 用 Sideloadly / AltStore / TrollStore 等工具自签后侧载；或作为二次签名输入 |
| `signed` | 使用仓库 Secrets 中的 Apple 证书 + 描述文件签名 | 可直接安装到设备、上传 TestFlight / App Store |

推送 `v*` 标签（如 `v1.7.3`）会自动触发打包，并把 IPA 与 dSYM 上传到对应 GitHub Release。
手动运行 **Run workflow** 时若勾选「同时发布到 GitHub Release」，也会自动创建 `v<版本号>` 标签并发布产物。

## 配置签名（signed 模式）

需要 3 个 Secrets：`IOS_CERT_P12_BASE64`、`IOS_CERT_PASSWORD`、`IOS_PROVISIONING_PROFILE_BASE64`。
完整步骤见 [signing/README.md](signing/README.md)。

## 本地打包（不依赖 GitHub）

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/package-ipa.ps1
```

macOS / Linux：

```bash
bash scripts/package-ipa.sh
```

产物输出到 `dist/`，命名如 `CrossDeskMobile-1.7.3-3-arm64-unsigned.ipa`。

## 推送到 GitHub

```bash
git init
git add .
git commit -m "init: crossdesk ios ipa build"
git branch -M main
git remote add origin https://github.com/<用户名>/<仓库名>.git
git push -u origin main
```

## 说明与注意

- 本仓库**不含 Xcode 工程**：`.app` 为已编译产物，工作流只做「签名（可选）+ 打包」，不重新编译。
- 最大单文件约 22 MB（主程序二进制），仓库总大小约 38 MB，均在 GitHub 单文件 100 MB 限制内，
  **无需 Git LFS**。
- `unsigned` 的 IPA **无法直接安装**到未越狱设备，需先用 Sideloadly / AltStore 等工具重签。
- 工作流在 `macos-latest` 上运行：unsigned 模式只打包（1 分钟左右），signed 模式包含签名与校验。
