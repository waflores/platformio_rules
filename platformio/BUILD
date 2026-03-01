load("@py_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(
    default_visibility = ["//visibility:public"],
)

py_binary(
    name = "template_renderer",
    srcs = ["template_renderer.py"],
    deps = [
        requirement("jinja2"),
    ],
)

filegroup(
    name = "platformio_ini_tmpl",
    srcs = ["platformio.ini.tmpl"],
)

exports_files(["platformio.bzl"])

bzl_library(
    name = "platformio",
    srcs = ["platformio.bzl"],
    deps = [
        "//platformio/private:defs.bzl",
        "//platformio/private:library.bzl",
        "//platformio/private:project.bzl",
        "//platformio/private:upload.bzl",
    ],
)
