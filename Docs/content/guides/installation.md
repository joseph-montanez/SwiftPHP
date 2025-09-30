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