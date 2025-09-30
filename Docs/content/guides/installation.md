+++
draft = true
title = 'Installtion Guide'
+++

# Installation Guide

As of writing, this is designed for PHP 8.4 support.

## Installing on macOS

macOS is straight forward but requires brew and xcode installed.

```bash
xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Build PHP.xcframework to compile extensions against
./Scripts/build_xcframework.sh

# Build PHP CLI to test your extension with
./Scripts/build_macos.sh
```

## Installation on Windows 11 x64/ARM64

As of this time, the current Windows SDK is broken and you need to follow the guide to install Swift on Windows successfully https://forums.swift.org/t/an-unofficial-guide-to-building-the-swift-toolchain-on-windows-x64-and-arm64/81751

### Windows 11 ARM64

PHP has no official support for Windows 11 on ARM, however progress is being made and you can use the guide below.

1. Download the experimental builds for PHP 8.4: https://github.com/hyh19962008/php-windows-arm64/releases/tag/8.4.10. Source code and Binary

 - php-8.4.10-nts-Win32-vs17-arm64-experimental.7z
 - Source code (zip)

2. Copy `php-src-php-8.4.10\win32\build\config.w32.h.in` to `php-src-php-8.4.10\php\config.w32.h`

3. Edit `Scripts\win_ext.ps1` and change `$env:PHP_SRC_ROOT="D:/dev/php-src-php-8.4.10"` to where the PHP source code was unzipped to.