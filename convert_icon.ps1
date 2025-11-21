# 图标转换脚本
# 将 PNG 图标转换为 Windows ICO 格式
# 需要安装 ImageMagick: https://imagemagick.org/

param(
    [string]$InputPng = "resources\appicon.png",
    [string]$OutputIco = "windows\runner\resources\app_icon.ico"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  图标转换工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查输入文件
if (-not (Test-Path $InputPng)) {
    Write-Host "错误: 找不到输入文件 $InputPng" -ForegroundColor Red
    exit 1
}

Write-Host "输入文件: $InputPng" -ForegroundColor White

# 获取图片信息
$image = New-Object System.Drawing.Bitmap($InputPng)
$width = $image.Width
$height = $image.Height
$image.Dispose()

Write-Host "图片尺寸: $width x $height" -ForegroundColor White
Write-Host ""

# 检查是否为正方形
if ($width -ne $height) {
    Write-Host "警告: 图片不是正方形 ($width x $height)" -ForegroundColor Yellow
    Write-Host "      建议使用正方形图片以获得最佳效果" -ForegroundColor Yellow
    Write-Host ""
}

# 检查 ImageMagick
$magickCmd = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magickCmd) {
    Write-Host "ImageMagick 未安装。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "有两种方式转换图标：" -ForegroundColor White
    Write-Host ""
    Write-Host "方式 1: 安装 ImageMagick（推荐）" -ForegroundColor Cyan
    Write-Host "  1. 下载: https://imagemagick.org/script/download.php#windows" -ForegroundColor Gray
    Write-Host "  2. 安装后重新运行此脚本" -ForegroundColor Gray
    Write-Host ""
    Write-Host "方式 2: 使用在线转换工具" -ForegroundColor Cyan
    Write-Host "  1. 访问: https://convertio.co/zh/png-ico/" -ForegroundColor Gray
    Write-Host "  2. 上传 $InputPng" -ForegroundColor Gray
    Write-Host "  3. 下载转换后的 ICO 文件" -ForegroundColor Gray
    Write-Host "  4. 保存为: $OutputIco" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# 使用 ImageMagick 转换
Write-Host "正在转换图标..." -ForegroundColor Yellow

try {
    # 生成多种尺寸的 ICO 文件（16x16, 32x32, 48x48, 64x64, 128x128, 256x256）
    magick convert $InputPng -define icon:auto-resize=256,128,64,48,32,16 $OutputIco
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 图标转换成功!" -ForegroundColor Green
        Write-Host ""
        Write-Host "输出文件: $OutputIco" -ForegroundColor White
        
        $icoSize = (Get-Item $OutputIco).Length / 1KB
        Write-Host "文件大小: $([math]::Round($icoSize, 2)) KB" -ForegroundColor White
        Write-Host ""
        Write-Host "下一步: 重新构建应用以应用新图标" -ForegroundColor Cyan
        Write-Host "  flutter build windows --release" -ForegroundColor Gray
    } else {
        Write-Host "错误: 转换失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
