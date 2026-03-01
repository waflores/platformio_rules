"""
Breaking out the modules in their own files
"""

load("//platformio/private:defs.bzl", "COPY_COMMAND", "SHELL_HEADER")

# Command that makes a directory
_MAKE_DIR_COMMAND = "mkdir -p {dirname}"

# Command that executed the PlatformIO system to upload data files to the
# device's FS
_FS_UPLOAD_COMMAND = "{platformio} run -s -d {project_dir} -t uploadfs"


def _emit_upload_fs_ini_file_action(ctx, platformio_ini):
    """Emits a Bazel action that generates the PlatformIO configuration file.

    Args:
      ctx: The Starlark context.
      platformio_ini: Declared output for the platformio.ini file.
    """
    substitutions = json.encode(struct(
        board = ctx.attr.board,
        platform = ctx.attr.platform,
        framework = ctx.attr.framework,
        environment_kwargs = [],
        build_flags = [],
        programmer = ctx.attr.programmer,
        port = ctx.attr.port,
        lib_ldf_mode = "deep+",
        lib_deps = [],
    ))
    ctx.actions.run(
        outputs = [platformio_ini],
        inputs = [ctx.file._platformio_ini_tmpl],
        executable = ctx.executable._template_renderer,
        arguments = [
            ctx.file._platformio_ini_tmpl.path,
            platformio_ini.path,
            substitutions,
        ],
    )

def _emit_upload_fs_copy_action(ctx, fs_dir):
    """Emits a Bazel action that creates the folder with data to upload to the FS

    Args:
      ctx: The Starlark context.
      fs_dir: Directory where the files to be copied to the filesystem are to be
        copied.
    """
    commands = []
    commands.append(
        _MAKE_DIR_COMMAND.format(dirname = fs_dir.path),
    )
    fs_files = depset(transitive = [
        ctx.attr.data[DefaultInfo].default_runfiles.files,
    ]).to_list()
    input_files = []
    for file in fs_files:
        input_files.append(file)
        commands.append(
            COPY_COMMAND.format(
                source = file.path,
                destination = fs_dir.path,
            ),
        )
    ctx.actions.run_shell(
        outputs = [fs_dir],
        inputs = input_files,
        command = "\n".join(commands),
    )

def _emit_upload_fs_executable_action(ctx, project_dir):
    """Emits a Bazel action that produces executable script.

    When the script is executed, the compiled firmware gets uploaded to the
    Arduino device.

    Args:
      ctx: The Starlark context.
      project_dir: A string, the main directory of the PlatformIO project.
        This is where the zip files will be extracted.
    """
    commands = [SHELL_HEADER]
    commands.append(_FS_UPLOAD_COMMAND.format(platformio = ctx.executable.tool.path, project_dir = project_dir))
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join(commands),
        is_executable = True,
    )

def _platformio_fs_impl(ctx):
    dirname = "%s_workdir" % ctx.attr.name
    platformio_ini = ctx.actions.declare_file("%s/platformio.ini" % dirname)
    fs_dir = ctx.actions.declare_directory("%s/data/" % dirname)
    _emit_upload_fs_ini_file_action(ctx, platformio_ini)
    _emit_upload_fs_copy_action(ctx, fs_dir)
    _emit_upload_fs_executable_action(
        ctx,
        "./%s" % platformio_ini.dirname[len(platformio_ini.root.path) + 1:],
    )
    return DefaultInfo(
        default_runfiles = ctx.runfiles(files = [ctx.outputs.executable, platformio_ini, fs_dir]),
    )

platformio_fs = rule(
    implementation = _platformio_fs_impl,
    executable = True,
    attrs = {
        "_platformio_ini_tmpl": attr.label(
            default = Label("//platformio:platformio_ini_tmpl"),
            allow_single_file = True,
        ),
        "_template_renderer": attr.label(
            default = Label("//platformio:template_renderer"),
            executable = True,
            cfg = "exec",
        ),
        "board": attr.string(
            mandatory = True,
            doc = """
A string, name of the Arduino board to build this project for. You can
find the supported boards in the
[PlatformIO Embedded Boards Explorer](http://platformio.org/boards). This is
mandatory.
""",
        ),
        "port": attr.string(
            doc = """
Port where your microcontroller is connected. This field is mandatory if you
are using arduino_as_isp as your programmer.
""",
        ),
        "platform": attr.string(
            default = "atmelavr",
            doc = """
A string, the name of the
[development platform](
http://docs.platformio.org/en/latest/platforms/index.html#platforms) for
this project.
""",
        ),
        "framework": attr.string(
            default = "arduino",
            doc = """
A string, the name of the
[framework](
http://docs.platformio.org/en/latest/frameworks/index.html#frameworks) for
this project.
""",
        ),
        "programmer": attr.string(
            default = "direct",
            values = [
                "arduino_as_isp",
                "direct",
                "usbtinyisp",
            ],
            doc = """
Type of programmer to use:
- direct: Use the USB connection in the microcontroller deveopment board to
program it
- arduino_as_isp: Use an arduino programmed with the Arduino as ISP code to
in-circuit program another microcontroller (see
https://docs.arduino.cc/built-in-examples/arduino-isp/ArduinoISP for details).
- usbtinyisp: Use an USBTinyISP programmer, like
https://www.amazon.com/gp/product/B09DG384MK
""",
        ),
        "data": attr.label(
            default = None,
            mandatory = True,
            allow_files = None,
            allow_single_file = None,
            doc = """
Filegroup containing files to upload to the device's FS memory.
""",
        ),
        "tool": attr.label(
            default = Label("//tools:platformio"),
            executable = True,
            cfg = "exec",
            doc = """
A label to a platformio python executable to run commands against.
            """,
        ),
    },
    doc = """
Defines data that will be uploaded to the microcontroller's filesystem using
PlatformIO.

Creates, configures and runs a PlatformIO project. This is equivalent to running:

```
platformio run
```

This rule is executable and when executed, it will upload the provided data to
the connected Arduino device. This is equivalent to running:

```
platformio run -t uploadfs
```
""",
)
