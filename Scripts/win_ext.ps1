# $env:PHP_SRC_ROOT="D:/dev/php-src-php-8.4.10"
# swift build --configuration debug `
#   -Xcc -DZEND_WIN32=1 `
#   -Xcc -DPHP_WIN32=1 `
#   -Xcc -DWIN32=1 `
#   -Xcc -D_WINDOWS=1 `
#   -Xcc -D_WIN32=1 `
#   -Xcc -DZTS=1 `
#   -Xcc -DZEND_DEBUG=0 `
#   -Xcc -U__SSE2__ `
#   -Xcc -fno-builtin `
#   -Xcc -ID:/dev/php-src-php-8.4.10 `
#   -Xcc -ID:/dev/php-src-php-8.4.10/main `
#   -Xcc -ID:/dev/php-src-php-8.4.10/Zend `
#   -Xcc -ID:/dev/php-src-php-8.4.10/TSRM `
#   -Xcc -ID:/dev/php-src-php-8.4.10/win32 `
#   -Xlinker /LIBPATH:D:/dev/php-src-php-8.4.10/libs

# Set the environment variable for the PHP source root.
$env:PHP_SRC_ROOT="D:/dev/php-src-php-8.4.10"
$env:PHP_LIB_ROOT="D:/dev/php-8.4.10-nts-Win32-vs17-arm64-experimental/SDK/lib"

# Clean the build directory to be safe.
Write-Host "Cleaning build artifacts..."
swift package clean

# Run the build. All flags are now in Package.swift!
Write-Host "Building with configuration from Package.swift..."
swift build --configuration debug -Xcc -DZEND_WIN32=1 -Xcc -DPHP_WIN32=1 -Xcc -DWIN32=1 -Xcc -DZEND_DEBUG=0 -Xcc -D_WINDOWS=1
# Check for success
if ($LASTEXITCODE -ne 0) {
    Write-Error "Swift build failed."
} else {
    Write-Host "Build successful!" -ForegroundColor Green
}

