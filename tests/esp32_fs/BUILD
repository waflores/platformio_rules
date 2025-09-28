load("//platformio:platformio.bzl", "platformio_fs", "platformio_project")

filegroup(
    name = "fs_data",
    data = glob(["fs_data/*"]),
)

platformio_project(
    name = "fs_reader",
    src = "fs_reader.cc",
    board = "esp32-s3-devkitc-1",
    framework = "arduino",
    platform = "espressif32",
    deps = [
        "//tests/arduino:Arduino_impl",
        "//tests/arduino:Arduino_interface",
    ],
)

platformio_fs(
    name = "upload_fs",
    board = "esp32-s3-devkitc-1",
    data = ":fs_data",
    framework = "arduino",
    platform = "espressif32",
)
