#if __APPLE__
    #error "Use PHP.xcframework"
#elif defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
    #if __has_include("windows_generated.h")
        #include "windows_generated.h"
    #else
        #include "windows.h"
    #endif
#elif __linux__
    #include "linux.h"
#else
   #error "Unsupported platform"
#endif