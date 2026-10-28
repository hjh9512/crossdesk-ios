<#
.SYNOPSIS
    本地打包脚本（Windows）：把 CrossDeskMobile.app 打包为未签名 IPA。
.DESCRIPTION
    用法：powershell -ExecutionPolicy Bypass -File scripts/package-ipa.ps1
    可选参数：
        -AppPath  .app 路径（默认当前目录下 CrossDeskMobile.app）
        -OutDir   输出目录（默认 dist）
        -Version  版本号（默认从 Info.plist 读取，读取失败时可用此参数覆盖）
.NOTES
    依赖：Windows 10+ 自带 bsdtar（tar.exe），无需安装 Xcode。
    仅打包不签名；签名请使用 GitHub Actions 的 signed 模式。
#>
param(
    [string]$AppPath = "CrossDeskMobile.app",
    [string]$OutDir  = "dist",
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $AppPath)) {
    throw "找不到应用包：$AppPath"
}
$appFull = (Resolve-Path -LiteralPath $AppPath).Path
$appName = (Split-Path -Leaf $appFull) -replace '\.app$', ''

# ---------- 读取版本号 ----------
if (-not $Version) {
    $python = $null
    foreach ($cmd in @("python", "python3", "py")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $python = $cmd; break }
    }
    if ($python) {
        # 多行代码经 -c 传给 python 在 Windows PowerShell 5.1 下会被破坏，
        # 因此写入临时 .py 文件再执行。
        $pyFile = Join-Path $env:TEMP ("read_version_" + [guid]::NewGuid().ToString("N") + ".py")
        try {
            [IO.File]::WriteAllText($pyFile, @'
import plistlib, sys
try:
    with open(sys.argv[1], "rb") as f:
        p = plistlib.load(f)
    print(p.get("CFBundleShortVersionString", ""))
except Exception:
    pass
'@, (New-Object Text.UTF8Encoding($false)))
            $plistPath = Join-Path $appFull "Info.plist"
            $v = & $python $pyFile $plistPath
            if ($LASTEXITCODE -eq 0 -and $v) {
                $Version = ($v | Select-Object -First 1).ToString().Trim()
            }
        } catch {
            $Version = ""
        } finally {
            if (Test-Path -LiteralPath $pyFile) { Remove-Item -LiteralPath $pyFile -Force }
        }
    }
    if (-not $Version) {
        Write-Warning "无法从 Info.plist 读取版本号，请用 -Version 参数手动指定"
        $Version = "0.0.0"
    }
}

# ---------- 打包 ----------
$staging = Join-Path $env:TEMP ("ipa_" + [guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path (Join-Path $staging "Payload") -Force | Out-Null
    Copy-Item -LiteralPath $appFull -Destination (Join-Path $staging "Payload") -Recurse

    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    $outAbs = (Resolve-Path -LiteralPath $OutDir).Path
    $name = "$appName-$Version-arm64-unsigned"
    $zip  = Join-Path $outAbs "$name.zip"
    $ipa  = Join-Path $outAbs "$name.ipa"

    # bsdtar 以 Payload 为归档根目录、正斜杠路径打包成 zip，再改名为 .ipa
    Push-Location $staging
    try {
        tar -a -cf $zip "Payload"
        if ($LASTEXITCODE -ne 0) { throw "tar 打包失败（exit=$LASTEXITCODE）" }
    } finally {
        Pop-Location
    }
    Move-Item -LiteralPath $zip -Destination $ipa -Force

    # ---------- 校验 ----------
    $entries = @(tar -tf $ipa)
    if ($entries.Count -eq 0) { throw "IPA 内容为空" }
    $first = $entries[0]
    if ($first -notlike "Payload/*") {
        throw "IPA 结构异常：首个条目应为 Payload/...，实际为 [$first]"
    }
    Write-Host ""
    Write-Host "✅ 已生成：$ipa"
    Write-Host "   归档条目数：$($entries.Count)，首条：$first"
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
