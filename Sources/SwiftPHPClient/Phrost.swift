import Foundation

func Phrost_GetExecutablePath() -> String {
#if os(macOS) || os(iOS)
    if let path = Bundle.main.executablePath {
        return path
    }
    return ""
#elseif os(Linux)
    var buffer = [CChar](repeating: 0, count: 4096)
    let count = readlink("/proc/self/exe", &buffer, buffer.count)
    if count > 0 {
        let uInt8Buffer = buffer[..<count].map { UInt8(bitPattern: $0) }
        return String(decoding: uInt8Buffer, as: UTF8.self)
    }
    return ""
#elseif os(Windows)
    var buffer = [WCHAR](repeating: 0, count: Int(MAX_PATH))
    GetModuleFileNameW(nil, &buffer, UInt32(MAX_PATH))
    return String(decodingCString: buffer, as: UTF16.self)
#endif
}

func Phrost_GetAssetPath(assetName: String, ofType: String) -> UnsafePointer<CChar>? {
#if os(macOS) || os(iOS)
    if let path = Bundle.main.path(forResource: assetName, ofType: ofType) {
        return UnsafePointer(strdup(path))  // Duplicate the C-string for compatibility with C.
    }
    return nil
#else
    let execPath = Phrost_GetExecutablePath()
    let path = (URL(fileURLWithPath: execPath).deletingLastPathComponent().path as NSString).appendingPathComponent("\(assetName).\(ofType)")
    return UnsafePointer(strdup(path))
#endif
}