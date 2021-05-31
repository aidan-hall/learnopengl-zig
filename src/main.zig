const c = @cImport({
    @cInclude("sigl.h");
});

const std = @import("std");

const vertexShaderSource = @embedFile("vertex.glsl");
const fragmentShaderSource = @embedFile("fragment.glsl");

const shaderError = error{
    CreateShader,
    Compile,
    CreateProgram,
    Link,
};

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    var vertices = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Setup.
    var win = c.setup(200, 200, "Nice GLFW", null, null) orelse return error.SiglInit;
    defer c.cleanup(win);

    // shader program
    var shaderProgram: c.GLuint = try makeShaderProgram(vertexShaderSource, fragmentShaderSource);
    c.glUseProgram(shaderProgram);

    // vertex array object
    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vao);
    c.glBindVertexArray(vao);
    // vertex buffer object
    var vbo: c_uint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    // vertex attributes
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    c.glClearColor(0.2, 0.3, 0.3, 1.0);
    c.glBindVertexArray(vao);

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        // std.time.sleep(std.time.ns_per_s / 60);
        // Input
        processInput(win);

        // Rendering
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // Events and Buffers
        c.glfwSwapBuffers(win);
        c.glfwPollEvents();
    }
}

fn processInput(window: *c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

fn initShader(source: []const u8, shaderType: c.GLenum) shaderError!c.GLuint {
    // init
    var shader: c.GLuint = c.glCreateShader(shaderType);

    if (shader == 0) {
        return shaderError.CreateShader;
    }

    {
        // compile
        c.glShaderSource(shader, 1, @ptrCast([*c]const [*c]const u8, &source), null);
        c.glCompileShader(shader);

        var success: c.GLuint = undefined;
        c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, @ptrCast([*c]c.GLint, &success));

        // log failure
        if (success != c.GL_TRUE) {
            var infoLog: [512]u8 = undefined;
            c.glGetShaderInfoLog(shader, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
            std.log.err("Shader compilation failed: {}", .{infoLog});
            return shaderError.Compile;
        }
    }

    return shader;
}

fn makeShaderProgram(vertexSource: []const u8, fragmentSource: []const u8) shaderError!c.GLuint {
    // shaders
    var vertexShader: c.GLuint = try initShader(vertexSource, c.GL_VERTEX_SHADER);
    var fragmentShader: c.GLuint = try initShader(fragmentSource, c.GL_FRAGMENT_SHADER);

    var shaderProgram: c.GLuint = c.glCreateProgram();
    if (shaderProgram == 0) {
        return shaderError.CreateProgram;
    }

    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);

    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);
    c.glLinkProgram(shaderProgram);

    // check for errors
    var success: c.GLint = undefined;
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, @ptrCast([*c]c.GLint, &success));
    if (success != c.GL_TRUE) {
        var infoLog: [512]u8 = undefined;
        c.glGetProgramInfoLog(shaderProgram, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
        std.log.err("Shader program linking failed: {}", .{infoLog});
        return shaderError.Link;
    }

    return shaderProgram;
}
