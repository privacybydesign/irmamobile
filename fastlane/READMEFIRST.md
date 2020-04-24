Due to having to maintain backwards compatibility with how we did things during the react-native era, we can't use flutter's default versioning scheme for split-abi packages. Before doing a release build, edit flutters packages/flutter_tools/gradle/flutter.gradle to use 1048576 as multiplier for the abiVersionCode, instead of 1000

Furthermore, the mapping from abi to versioncode is slightly different. This should be changed to 
private static final Map ABI_VERSION = [
        (ARCH_ARM32)        : 1,
        (ARCH_ARM64)        : 3,
        (ARCH_X86)          : 2,
        (ARCH_X86_64)       : 4,
    ]

(swapping arm64 and x86)
