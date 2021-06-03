const c = @cImport({
    @cInclude("sigl.h");
});

const std = @import("std");

// An OpenGL 'Shader Program'.
const Shader = struct {
    id: c.GLuint,

    const Source = struct {
        code: []const u8,
        shaderType: c.GLenum,
    };

    const Error = error{
        CreateShader,
        Compile,
        CreateProgram,
        Link,
    };

    inline fn initString(source: Source) Error!c.GLuint {
        var shader = try createShaderObject(source.shaderType);

        c.glShaderSource(shader, 1, @ptrCast([*c]const [*c]const u8, &source.code), null);

        try compile(shader);

        return shader;
    }

    fn initStrings(sources: []const Source, outShaders: []c.GLuint) Error!void {
        std.debug.assert(sources.len == outShaders.len);
        for (sources) |source, idx| {
            outShaders[idx] = try initString(source);
        }
    }

    inline fn createShaderObject(shaderType: c.GLenum) Error!c.GLuint {
        // init
        var id: c.GLuint = c.glCreateShader(shaderType);

        if (id == 0) {
            return Error.CreateShader;
        }
        return id;
    }

    fn compile(self: c.GLuint) Error!void {
        c.glCompileShader(self);

        var success: c.GLuint = undefined;
        c.glGetShaderiv(self, c.GL_COMPILE_STATUS, @ptrCast([*c]c.GLint, &success));

        // log failure
        if (success != c.GL_TRUE) {
            var infoLog: [512]u8 = undefined;
            c.glGetShaderInfoLog(self, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
            std.log.err("Shader compilation failed: {}", .{infoLog});
            return Error.Compile;
        }
    }

    fn makeProgramStrings(sources: []Source, al: *std.mem.Allocator) !Shader {
        var shaders = try al.alloc(c.GLuint, sources.len);
        defer al.free(shaders);
        try initStrings(sources, shaders);
        return try makeProgram(shaders);
    }

    fn makeProgram(shaders: []c.GLuint) Error!Shader {
        // shaders
        var id: c.GLuint = c.glCreateProgram();
        if (id == 0) {
            return Error.CreateProgram;
        }

        for (shaders) |shader| {
            c.glAttachShader(id, shader);
            c.glDeleteShader(shader);
        }

        c.glLinkProgram(id);

        // check for errors
        var success: c.GLint = undefined;
        c.glGetProgramiv(id, c.GL_LINK_STATUS, @ptrCast([*c]c.GLint, &success));
        if (success != c.GL_TRUE) {
            var infoLog: [512]u8 = undefined;
            c.glGetProgramInfoLog(id, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
            std.log.err("Shader program linking failed: {}", .{infoLog});
            return Error.Link;
        }
        return Shader{ .id = id };
    }
    inline fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }
    inline fn getUniform(self: Shader, name: [*c]const u8) c.GLint {
        return c.glGetUniformLocation(self.id, name);
    }
    fn setUniform(self: Shader, name: []u8, value: anytype) void {}
};

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    // zig fmt: off
    var vertices = [_]f32{
        1.0, 1.0, 0.0, 0.9, 0.0, 0.0, // top right
        1.0, -0.8, 0.0, 0.0, 0.9, 0.0, // bottom right
        -1.0, -0.8, 0.0, 0.0, 0.0, 0.9, // bottom left
        -1.0, 1.0, 0.0, 0.9, 0.9, 0.0, // top left
        0.0, -1.0, 0.0, 0.0, 0.9, 0.9, // bottom middle
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
        var shaderSources = [_]Shader.Source{
            Shader.Source{
                .shaderType = c.GL_VERTEX_SHADER,
                .code = @embedFile("vertex.glsl"),
            },
            Shader.Source{
                .shaderType = c.GL_FRAGMENT_SHADER,
                .code = @embedFile("fragment.glsl"),
            },
        };
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        break :shadProcBlk try Shader.makeProgramStrings(&shaderSources, &gpa.allocator);
    };
    shaderProgram.use();

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
    // position
    c.glVertexAttribPointer(0, 3, try glTypeID(f32), glBool(false), 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // colour
    c.glVertexAttribPointer(1, 3, try glTypeID(f32), glBool(false), 6 * @sizeOf(f32), @intToPtr(*const c_void, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    //...

    // preparation
    c.glClearColor(0.2, 0.3, 0.3, 1.0);
    c.glBindVertexArray(vao);

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        var time = @floatCast(f32, c.glfwGetTime());
        // var green = (std.math.sin(time) / 2.0) + 0.5;
        // var ourColourLoc = c.glGetUniformLocation(shaderProgram, "ourColour");
        var timeLoc = shaderProgram.getUniform("glfwTime");
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
