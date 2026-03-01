# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

"""PlatformIO Rules.

These are Bazel Starlark rules for building and uploading
[Arduino](https://www.arduino.cc/) programs using the
[PlatformIO](http://platformio.org/) build system.
"""

load("//platformio/private:project.bzl", _platformio_project = "platformio_project")
load("//platformio/private:upload.bzl", _platformio_fs = "platformio_fs")
load("//platformio/private:library.bzl", _platformio_library = "platformio_library")

platformio_fs = _platformio_fs
platformio_library = _platformio_library
platformio_project = _platformio_project
