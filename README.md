## macOS

./Scripts/build_xcframework.sh
PHP_SRC_ROOT=PHP.xcframework/macos-arm64/Headers swift run -Xcc -IPHP.xcframework/macos-arm64/Headers -Xcc -IPHP.xcframework/macos-arm64/Headers/main -Xcc -IPHP.xcframework/macos-arm64/Headers/Zend -Xcc -IPHP.xcframework/macos-arm64/Headers/TSRM -Xcc -DZTS -Xswiftc -DZTS SwiftPHPClient

