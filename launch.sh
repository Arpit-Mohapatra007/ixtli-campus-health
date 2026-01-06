#!/bin/bash

# 1. Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "\033[0;31mError: Flutter is not installed.\033[0m"
    exit 1
fi

# 2. Install Dependencies
echo -e "\033[1;33m[*] Installing dependencies...\033[0m"
flutter pub get

# 3. Setup .env
if [ ! -f ".env" ]; then
    echo -e "\033[1;33m[!] Creating .env file...\033[0m"
    echo "GEMINI_API_KEY=YOUR_API_KEY_HERE" > .env
fi

# 4. Run App
echo -e "\033[0;32m[+] Running Campus Health...\033[0m"
flutter run