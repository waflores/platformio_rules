"""
Breaking out the modules in their own files
"""

load("//platformio/private:defs.bzl", "PlatformIOLibraryInfo", "COPY_COMMAND")

# The relative filename of the header file.
_HEADER_FILENAME = "lib/{dirname}/{filename}.h"

# The relative filename of the source file.
_SOURCE_FILENAME = "lib/{dirname}/{filename}.cpp"

# The relative filename of an additional file (header or source) defined for a
# platformio_library target.
_ADDITIONAL_FILENAME = "lib/{dirname}/{filename}"

# Command that zips files recursively. It enters the output directory first so
# that the zipped path starts at lib/. It will return to the original directory
# when finishing the command.
_ZIP_COMMAND = "cd {output_dir} && zip -qq -r -u {zip_filename} lib/; cd -"

def _platformio_library_impl(ctx):
    """Collects all transitive dependencies and emits the zip output.

    Outputs a zip file containing the library in the directory structure expected
    by PlatformIO.

    Args:
      ctx: The Starlark context.
    """
    name = ctx.label.name

    # Copy the header file to the desired destination.
    header_file = ctx.actions.declare_file(
        _HEADER_FILENAME.format(dirname = name, filename = name),
    )
    inputs = [ctx.file.hdr]
    outputs = [header_file]
    commands = [COPY_COMMAND.format(
        source = ctx.file.hdr.path,
        destination = header_file.path,
    )]

    # Copy all the additional header and source files.
    for additional_files in [ctx.attr.add_hdrs, ctx.attr.add_srcs]:
        for target in additional_files:
            if len(target.files.to_list()) != 1:
                fail("each target listed under add_hdrs or add_srcs must expand to " +
                     "exactly one file, this expands to %d: %s" %
                     (len(target.files), target.files))

            # The name of the label is the relative path to the file, this enables us
            # to prepend "lib/" to the path. For PlatformIO, all the library files
            # must be under lib/...
            additional_file_name = target.label.name
            additional_file_source = [f for f in target.files.to_list()][0]
            additional_file_destination = ctx.actions.declare_file(
                _ADDITIONAL_FILENAME.format(dirname = name, filename = additional_file_name),
            )
            inputs.append(additional_file_source)
            outputs.append(additional_file_destination)
            commands.append(COPY_COMMAND.format(
                source = additional_file_source.path,
                destination = additional_file_destination.path,
            ))

    # The src argument is optional, some C++ libraries might only have the header.
    if ctx.attr.src != None:
        source_file = ctx.actions.declare_file(
            _SOURCE_FILENAME.format(dirname = name, filename = name),
        )
        inputs.append(ctx.file.src)
        outputs.append(source_file)
        commands.append(COPY_COMMAND.format(
            source = ctx.file.src.path,
            destination = source_file.path,
        ))

    # Zip the entire content of the library folder.
    zip_file = ctx.actions.declare_file("%s.zip" % ctx.attr.name)
    outputs.append(zip_file)
    commands.append(_ZIP_COMMAND.format(
        output_dir = zip_file.dirname,
        zip_filename = zip_file.basename,
    ))
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = "\n".join(commands),
    )

    # Collect the zip files produced by all transitive dependancies.
    transitive_zip_files = [
        dep[PlatformIOLibraryInfo].default_runfiles
        for dep in ctx.attr.deps
    ]
    runfiles = ctx.runfiles(files = [zip_file])
    runfiles = runfiles.merge_all(transitive_zip_files)
    transitive_libdeps = []
    transitive_libdeps.extend(ctx.attr.lib_deps)
    for dep in ctx.attr.deps:
        transitive_libdeps.extend(dep[PlatformIOLibraryInfo].transitive_libdeps)
    return PlatformIOLibraryInfo(
        default_runfiles = runfiles,
        transitive_libdeps = transitive_libdeps,
    )

platformio_library = rule(
    implementation = _platformio_library_impl,
    attrs = {
        "hdr": attr.label(
            allow_single_file = [".h", ".hpp"],
            mandatory = True,
            doc = "A string, the name of the C++ header file. This is mandatory.",
        ),
        "src": attr.label(
            allow_single_file = [".c", ".cc", ".cpp"],
            doc = "A string, the name of the C++ source file. This is optional.",
        ),
        "add_hdrs": attr.label_list(
            allow_files = [".h", ".hpp"],
            allow_empty = True,
            doc = """
A list of labels, additional header files to include in the resulting zip file.
""",
        ),
        "add_srcs": attr.label_list(
            allow_files = [".c", ".cc", ".cpp"],
            allow_empty = True,
            doc = """
A list of labels, additional source files to include in the resulting zip file.
""",
        ),
        "deps": attr.label_list(
            providers = [DefaultInfo, PlatformIOLibraryInfo],
            doc = """
A list of Bazel targets, other platformio_library targets that this one depends on.
""",
        ),
        "lib_deps": attr.string_list(
            allow_empty = True,
            mandatory = False,
            default = [],
            doc = """
A list of external (PlatformIO) libraries that this library depends on. These
libraries will be added to any platformio_project() rules that directly or
indirectly link this library.
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
Defines a C++ library that can be imported in an PlatformIO project.

The PlatformIO build system requires a set project directory structure. All
libraries must be under the lib directory. Furthermore all libraries can only
consist of a single header and a single source file. The name of the library
must match the names of the header file, the source file and the subdirectory
under the lib directory.

If you have a C++ library with files my_lib.h and my_lib.cc, using this rule:

```
platformio_library(
    # Start with an uppercase letter to keep the Arduino naming style.
    name = "My_lib",
    hdr = "my_lib.h",
    src = "my_lib.cc",
)
```

Will generate a zip file containing the following structure:

```
lib/
  My_lib/
    My_lib.h
    My_lib.cpp
```

In the Arduino code, you should include this as follows. The PLATFORMIO_BUILD
will be set when the library is built by the PlatformIO build system.

```
#ifdef PLATFORMIO_BUILD
#include <My_lib.h>  // This is how PlatformIO sees and includes the library.
#else
#include "actual/path/to/my_lib.h" // This is for native C++.
#endif
```

Outputs a single zip file containing the C++ library in the directory structure
expected by PlatformIO.
""",
)
