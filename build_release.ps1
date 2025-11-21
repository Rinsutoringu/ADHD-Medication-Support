# ADHD 药物监测工具 - Windows Release 构建脚本
# 使用方法: .\build_release.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ADHD 药物监测工具 - Release 构建" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Flutter 是否已安装
Write-Host "[1/6] 检查 Flutter 环境..." -ForegroundColor Yellow
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未找到 Flutter。请先安装 Flutter SDK。" -ForegroundColor Red
    exit 1
}

$flutterVersion = flutter --version | Select-String "Flutter" | Out-String
Write-Host "✓ Flutter 已安装: $flutterVersion" -ForegroundColor Green

# 清理之前的构建
Write-Host ""
Write-Host "[2/6] 清理之前的构建文件..." -ForegroundColor Yellow
if (Test-Path "build") {
    flutter clean | Out-Null
    Write-Host "✓ 构建缓存已清理" -ForegroundColor Green
}

# 获取依赖
Write-Host ""
Write-Host "[3/6] 获取项目依赖..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 依赖获取失败" -ForegroundColor Red
    exit 1
}
Write-Host "✓ 依赖获取成功" -ForegroundColor Green

# 构建 Release 版本
Write-Host ""
Write-Host "[4/6] 构建 Windows Release 版本..." -ForegroundColor Yellow
Write-Host "    (这可能需要几分钟时间，请耐心等待...)" -ForegroundColor Gray
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 构建失败" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Release 版本构建成功" -ForegroundColor Green

# 创建发布目录
Write-Host ""
Write-Host "[5/6] 准备发布包..." -ForegroundColor Yellow

$releaseDir = "release_package"
$buildDir = "build\windows\x64\runner\Release"
$version = "v1.0.0"

# 删除旧的发布包
if (Test-Path $releaseDir) {
    Remove-Item $releaseDir -Recurse -Force
}

# 创建发布目录
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

# 复制必要文件
Copy-Item "$buildDir\*" -Destination $releaseDir -Recurse -Force

# 重命名主执行文件
if (Test-Path "$releaseDir\flutter_application_1.exe") {
    Rename-Item "$releaseDir\flutter_application_1.exe" "adhd_medication_tracker.exe"
}

Write-Host "✓ 发布包准备完成" -ForegroundColor Green

# 创建 ZIP 压缩包
Write-Host ""
Write-Host "[6/6] 创建 ZIP 压缩包..." -ForegroundColor Yellow

$zipFileName = "ADHD_Medication_Tracker_$version`_Windows.zip"
if (Test-Path $zipFileName) {
    Remove-Item $zipFileName -Force
}

Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipFileName -CompressionLevel Optimal

$zipSize = (Get-Item $zipFileName).Length / 1MB
$zipSizeRounded = [math]::Round($zipSize, 2)
$sizeText = "$zipSizeRounded MB"
Write-Host "✓ ZIP 压缩包创建成功: $zipFileName ($sizeText)" -ForegroundColor Green

# 显示完成信息
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  构建完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "发布文件位置:" -ForegroundColor White
Write-Host "  - 程序文件夹: .\$releaseDir\" -ForegroundColor Yellow
Write-Host "  - ZIP 压缩包: .\$zipFileName" -ForegroundColor Yellow
Write-Host ""
Write-Host "运行程序:" -ForegroundColor White
Write-Host "  .\$releaseDir\adhd_medication_tracker.exe" -ForegroundColor Cyan
Write-Host ""
Write-Host "发布到 GitHub:" -ForegroundColor White
Write-Host "  1. 在 GitHub 创建新的 Release ($version)" -ForegroundColor Gray
Write-Host "  2. 上传 $zipFileName 文件" -ForegroundColor Gray
Write-Host "  3. 填写 Release Notes" -ForegroundColor Gray
Write-Host ""
