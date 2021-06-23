const c = @cImport({
    @cInclude("glad/glad.h");
});

const std = @import("std");
const matma = @import("matmaths.zig");

// An OpenGL 'Shader Program'.
pub const Shader = struct {
    id: c.GLuint,

    pub const Source = struct {
        code: []const u8,
        shaderType: c.GLenum,
    };

    pub const Error = error{
        CreateShader,
        Compile,
        CreateProgram,
        Link,
        UniformUnfound,
        NoUniformType,
    };

    inline fn initString(source: Source) !c.GLuint {
        var shader = try createShaderObject(source.shaderType);

        c.glShaderSource(shader, 1, @ptrCast([*c]const [*c]const u8, &source.code), null);

        try compile(shader);

        return shader;
    }

    fn initStrings(sources: []const Source, outShaders: []c.GLuint) !void {
        std.debug.assert(sources.len == outShaders.len);
        for (sources) |source, idx| {
            outShaders[idx] = try initString(source);
        }
    }

    inline fn createShaderObject(shaderType: c.GLenum) !c.GLuint {
        // init
        var id: c.GLuint = c.glCreateShader(shaderType);

        if (id == 0) {
            return Error.CreateShader;
        }
        return id;
    }

    fn compile(self: c.GLuint) !void {
        c.glCompileShader(self);

        var success: c.GLuint = undefined;
        c.glGetShaderiv(self, c.GL_COMPILE_STATUS, @ptrCast([*c]c.GLint, &success));

        // log failure
        if (success != c.GL_TRUE) {
            var infoLog: [512]u8 = undefined;
            c.glGetShaderInfoLog(self, infoLog.len, null, @ptrCast([*c]u8, &infoLog));
            std.log.err("Shader compilation failed: {s}", .{infoLog});
            return Error.Compile;
        }
    }

    pub fn makeProgramStrings(sources: []Source, al: *std.mem.Allocator) !Shader {
        var shaders = try al.alloc(c.GLuint, sources.len);
        defer al.free(shaders);
        try initStrings(sources, shaders);
        return try makeProgram(shaders);
    }

    pub fn makeProgram(shaders: []c.GLuint) !Shader {
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
            std.log.err("Shader program linking failed: {s}", .{infoLog});
            return Error.Link;
        }
        return Shader{ .id = id };
    }
    pub inline fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }
    pub inline fn getUniform(self: Shader, name: [:0]const u8) !c.GLint {
        var location = c.glGetUniformLocation(self.id, @ptrCast([*c]const u8, name));
        if (location == -1) {
            std.log.err("Uniform not found: {s}", .{name});
            return Error.UniformUnfound;
        } else {
            return location;
        }
    }
    pub inline fn setUniform(self: Shader, comptime T: type, name: [:0]const u8, value: T) !void {
        const location = try self.getUniform(name);
        switch (T) {
            f32 => c.glUniform1f(location, value),
            [2]f32 => c.glUniform2f(location, value[0], value[1]),
            [3]f32 => c.glUniform3f(location, value[0], value[1], value[2]),
            [4]f32 => c.glUniform4f(location, value[0], value[1], value[2], value[3]),
            bool => c.glUniform1i(location, @intCast(c.GLint, value)),
            i32 => c.glUniform1i(location, value),
            [2]i32 => c.glUniform2i(location, value[0], value[1]),
            [3]i32 => c.glUniform3i(location, value[0], value[1], value[2]),
            [4]i32 => c.glUniform4i(location, value[0], value[1], value[2], value[3]),
            *const matma.mat(4) => c.glUniformMatrix4fv(location, 1, c.GL_TRUE, @ptrCast([*c]const f32, value)),
            else => Error.NoUniformType,
        }
    }
};
