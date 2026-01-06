# 1. Check for Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter is not installed." -ForegroundColor Red
    exit 1
}

# 2. Install Dependencies
Write-Host "[*] Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Setup .env
if (!(Test-Path ".env")) {
    Write-Host "[!] Creating .env file..." -ForegroundColor Yellow
    New-Item -Path . -Name ".env" -ItemType "file" -Value "GEMINI_API_KEY=YOUR_API_KEY_HERE" | Out-Null
}

# 4. Run App
Write-Host "[+] Running Campus Health..." -ForegroundColor Green
flutter run