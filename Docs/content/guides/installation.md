+++
draft = false
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

1. Download the experimental builds for PHP 8.4: https://github.com/hyh19962008/php-windows-arm64/releases/download/8.4.10/php-8.4.10-nts-Win32-vs17-arm64-experimental.7z. Source code and SDK are in the same 7zip file.

 - php-8.4.10-nts-Win32-vs17-arm64-experimental.7z

2. Edit `Scripts/win_ext.ps1` and change `$env:PHP_SRC_ROOT="D:/dev/php-src-php-8.4.10"` to where the PHP source code was unzipped to.

```powershell
# Change these to where you decompressed `php-8.4.10-nts-Win32-vs17-arm64-experimental`
$env:PHP_SRC_ROOT = "D:/dev/php-8.4.10-nts-Win32-vs17-arm64-experimental/SDK/include"
$env:PHP_LIB_ROOT = "D:/dev/php-8.4.10-nts-Win32-vs17-arm64-experimental/SDK/lib"
```

3. Run `Scripts/win_ext.ps1` to build your Native PHP extension.