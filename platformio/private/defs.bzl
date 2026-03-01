"""
Constants
"""

PlatformIOLibraryInfo = provider(
    "Information needed to define a PlatformIO library.",
    fields = {
        "default_runfiles": "Files needed to execute anything depending on this library.",
        "transitive_libdeps": "External platformIO libraries needed by this library.",
    },
)

# Command that copies the source to the destination.
COPY_COMMAND = "cp {source} {destination}"



# Header used in the shell script that makes platformio_project executable.
# Execution will upload the firmware to the Arduino device.
SHELL_HEADER = """#!/bin/bash"""