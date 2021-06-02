const c = @cImport({
    @cInclude("sigl.h");
});

const std = @import("std");

const ShaderSource = struct {
    code: []const u8,
    shaderType: c.GLenum,
};

const ShaderError = error{
    CreateShader,
    Compile,
    CreateProgram,
    Link,
};

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    // zig fmt: off
    var vertices = [_]f32{
        1.0, 1.0, 0.0, // top right
        1.0, -0.8, 0.0, // bottom right
        -1.0, -0.8, 0.0, // bottom left
        -1.0, 1.0, 0.0, // top left
        0.0, -1.0, 0.0, // bottom middle
    };
    var indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
        1, 2, 4, // third triangle
    };
    // zig fmt: on

    // Setup.
    var win = c.setup(200, 200, "Nice GLFW", null, null) orelse return error.SiglInit;
    defer c.cleanup(win);

    {
        var nAttrs: c_int = undefined;
        c.glGetIntegerv(c.GL_MAX_VERTEX_ATTRIBS, &nAttrs);
        std.log.info("Max attrs: {}", .{nAttrs});
    }

    var shaderProgram = shadProcBlk: {
        var shaderSources = [_]ShaderSource{
            ShaderSource{
                .shaderType = c.GL_VERTEX_SHADER,
                .code = @embedFile("vertex.glsl"),
            },
            ShaderSource{
                .shaderType = c.GL_FRAGMENT_SHADER,
                .code = @embedFile("fragment.glsl"),
            },
        };
        var shaders: [shaderSources.len]c.GLuint = undefined;
        try initShaderStrings(&shaderSources, &shaders);
        break :shadProcBlk try makeShaderProgram(&shaders);
    };
    c.glUseProgram(shaderProgram);

    // vertex array object: Stores attributes for a vbo.
    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vao);
    c.glBindVertexArray(vao);

    // vertex buffer object
    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    // element buffer object: which vertices to use for each triangle
    var ebo: c.GLuint = undefined;
    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

    // vertex attributes
    c.glVertexAttribPointer(0, 3, try glTypeID(f32), glBool(false), 0, null);
    c.glEnableVertexAttribArray(0);

    //...

    // preparation
    c.glClearColor(0.2, 0.3, 0.3, 1.0);
    c.glBindVertexArray(vao);

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        var time = @floatCast(f32, c.glfwGetTime());
        // var green = (std.math.sin(time) / 2.0) + 0.5;
        // var ourColourLoc = c.glGetUniformLocation(shaderProgram, "ourColour");
        var timeLoc = c.glGetUniformLocation(shaderProgram, "glfwTime");
        c.glUniform1f(timeLoc, time);
        // c.glUniform4f(ourColourLoc, 0.0, green, 0.0, 1.0);

        // Rendering
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glDrawElements(c.GL_TRIANGLES, 9, try glTypeID(@TypeOf(indices[0])), null);
        // c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        // Events and Buffers
        c.glfwSwapBuffers(win);
        c.glfwPollEvents();
    }
}

inline fn initShaderString(source: ShaderSource) ShaderError!c.GLuint {
    var shader = try createShader(source.shaderType);

    c.glShaderSource(shader, 1, @ptrCast([*c]const [*c]const u8, &source.code), null);

    try compileShader(shader);

    return shader;
}

fn initShaderStrings(sources: []const ShaderSource, outShaders: []c.GLuint) ShaderError!void {
    std.debug.assert(sources.len == outShaders.len);
    for (sources) |source, idx| {
        outShaders[idx] = try initShaderString(source);
    }
}

inline fn createShader(shaderType: c.GLenum) ShaderError!c.GLuint {
    // init
    var shader: c.GLuint = c.glCreateShader(shaderType);

    if (shader == 0) {
        return ShaderError.CreateShader;
    }
    return shader;
}

fn compileShader(shader: c.GLuint) ShaderError!void {
    c.glCompileShader(shader);

    var success: c.GLuint = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, @ptrCast([*c]c.GLint, &success));

    // log failure
    if (success != c.GL_TRUE) {
        var infoLog: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
        std.log.err("Shader compilation failed: {}", .{infoLog});
        return ShaderError.Compile;
    }
}

fn makeShaderProgram(shaders: []c.GLuint) ShaderError!c.GLuint {
    // shaders
    var shaderProgram: c.GLuint = c.glCreateProgram();
    if (shaderProgram == 0) {
        return ShaderError.CreateProgram;
    }

    for (shaders) |shader| {
        c.glAttachShader(shaderProgram, shader);
        c.glDeleteShader(shader);
    }

    c.glLinkProgram(shaderProgram);

    // check for errors
    var success: c.GLint = undefined;
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, @ptrCast([*c]c.GLint, &success));
    if (success != c.GL_TRUE) {
        var infoLog: [512]u8 = undefined;
        c.glGetProgramInfoLog(shaderProgram, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
        std.log.err("Shader program linking failed: {}", .{infoLog});
        return ShaderError.Link;
    }

    return shaderProgram;
}

inline fn glBool(cond: bool) c.GLchar {
    if (cond == true)
        return c.GL_TRUE
    else
        return c.GL_FALSE;
}

fn glTypeID(comptime attrib: type) !comptime c.GLenum {
    return switch (attrib) {
        i8 => c.GL_BYTE,
        u8 => c.GL_UNSIGNED_BYTE,
        i16 => c.GL_SHORT,
        u16 => c.GL_UNSIGNED_SHORT,
        i32 => c.GL_INT,
        u32 => c.GL_UNSIGNED_INT,
        f32 => c.GL_FLOAT,
        f64 => c.GL_DOUBLE,
        bool => c.GL_BOOL,
        else => error.NoKnownGLType,
    };
}
