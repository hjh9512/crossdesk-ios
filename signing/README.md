# 签名配置指南（signed 模式）

GitHub Actions 的 `signed` 模式需要 3 个 Secrets，全部配置后即可在 workflow 中对
`CrossDeskMobile.app`（Bundle ID：`cn.crossdesk.mobile`）做正式签名，产出可直接安装 /
上传 TestFlight / 提交 App Store 的 IPA。

> 工作流会**自动从描述文件提取 entitlements** 并签名，本目录的 `entitlements.plist`
> 仅作为参考模板，一般无需改动。

## 1. 准备证书（.p12）

1. 在 Mac 上打开「钥匙串访问」（Keychain Access）。
2. 找到你的 Apple 开发者证书：`iPhone Developer: xxx` 或 `iPhone Distribution: xxx`。
3. 右键 → 导出「xxx」→ 选择 `.p12` 格式，并**设置导出密码**（稍后要用）。

## 2. 准备描述文件（.mobileprovision）

- 登录 [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles。
- 确认 App ID 为 `cn.crossdesk.mobile`（与本包一致）。
- 生成/下载对应类型的描述文件（开发或分发，需包含目标设备的 UDID）。
- 文件后缀为 `.mobileprovision`。

## 3. 转 base64

macOS / Linux：

```bash
base64 -i cert.p12 > cert.p12.b64
base64 -i profile.mobileprovision > profile.mobileprovision.b64
```

Windows PowerShell：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) > cert.p12.b64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) > profile.mobileprovision.b64
```

## 4. 配置 GitHub Secrets

仓库 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**：

| Secret 名称 | 值 |
|---|---|
| `IOS_CERT_P12_BASE64` | 证书 .p12 的 base64 内容 |
| `IOS_CERT_PASSWORD` | 证书导出时设置的密码 |
| `IOS_PROVISIONING_PROFILE_BASE64` | 描述文件 .mobileprovision 的 base64 内容 |

## 5. 运行

Actions 页 → **Build IPA** → **Run workflow** → signing 选择 `signed` → 等待完成后在
Artifacts 下载 `ipa-signed` 产物。

## 注意事项

- 描述文件必须包含目标设备的 UDID，否则签名成功也无法安装到该设备。
- 上传 TestFlight / App Store 建议使用 **Distribution** 证书与对应描述文件。
- 工作流使用的是独立临时钥匙串，不会影响 runner 的默认钥匙串。
