$env:PHP_SRC_ROOT = "D:/dev/php-8.4.10-nts-Win32-vs17-arm64-experimental/SDK/include"
$env:PHP_LIB_ROOT = "D:/dev/php-8.4.10-nts-Win32-vs17-arm64-experimental/SDK/lib"

# swift build --configuration debug `
#     -Xcc -DZEND_WIN32=1 `
#     -Xcc -DPHP_WIN32=1 `
#     -Xcc -DWIN32=1 `
#     -Xcc -D_WINDOWS=1 `
#     -Xcc -D_WIN32=1 `
#     -Xcc -U__SSE2__ `
#     -Xlinker -shared `
#     --target SwiftPHPExtension

swift build -c debug -vv `
    -Xcc -DZEND_WIN32=1 `
    -Xcc -DPHP_WIN32=1 `
    -Xcc -DWIN32=1 `
    -Xcc -D_WINDOWS=1 `
    -Xcc -D_WIN32=1 `
    -Xcc -U__SSE2__ `
  --triple aarch64-unknown-windows-msvc `
  --product SwiftPHPExtension

# Copy-Item -Path ".build/debug/SwiftPHPExtension.dll" -Destination "SwiftPHPExtension.dll"