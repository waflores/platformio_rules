load("//platformio:platformio.bzl", "platformio_project")

configs = [
    {
        "name": "attiny85",
        "board": "attiny85",
        "build_flags": ["-DTARGET_PIN=4"],
        "programmer": "arduino_as_isp",
        "port": "/dev/ttyUSB0",
    },
    {
        "name": "nano",
        "board": "nanoatmega328",
        "build_flags": [],
        "programmer": "direct",
        "port": "unused",
    },
]

[platformio_project(
    name = "blink_%s" % config["name"],
    src = "blink.cc",
    board = config["board"],
    build_flags = config["build_flags"],
    framework = "arduino",
    platform = "atmelavr",
    port = config["port"],
    programmer = config["programmer"],
    deps = [
        "//tests/arduino:Arduino_impl",
        "//tests/arduino:Arduino_interface",
    ],
) for config in configs]
