const c = @cImport({
    @cInclude("sigl.h");
});

const std = @import("std");
usingnamespace @import("utilgl.zig");
usingnamespace @import("shader.zig");

pub fn main() !void {
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
        // try shaderProgram.setUniform([3]f32, "ourColour", [3]f32{0.0, green, 0.0});
        // var ourColourLoc = c.glGetUniformLocation(shaderProgram, "ourColour");
        // var timeLoc = try shaderProgram.getUniform("glfwTime");
        // c.glUniform4f(ourColourLoc, 0.0, green, 0.0, 1.0);
        try shaderProgram.setUniform(f32, "glfwTime", time);

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
