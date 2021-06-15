const c = @cImport({
    @cInclude("sigl.h");
    @cInclude("farbfeld.h");
});

const std = @import("std");
usingnamespace @import("utilgl.zig");
usingnamespace @import("shader.zig");

// const Image = struct {
//     width: i32,
//     height: i32,
//     nrChannels: i32,
//     data: *u8,
// };

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});

    // zig fmt: off
    const vertices = [_]f32{
        1.0, 1.0, 0.0,
        1.0, -1.0, 0.0,
        -1.0, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        // 0.0, -1.0, 0.0, 0.0, 0.9, 0.9, // bottom middle
    };
    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
        // 1, 2, 4, // third triangle
    };
    // const textureCoords = [_]f32{
    //     0.0, 0.0, // lower-left
    //     1.0, 0.0, // lower-right
    //     0.5, 1.0, // top-center
    // };
    // zig fmt: on

    // Setup.
    var win = c.setup(1000, 1000, "Nice GLFW", null, null) orelse return error.SiglInit;
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

    // texture loading
    // var boxTexture = try loadFarbfeldImage("wall.ff", c.GL_TEXTURE0);
    // var wallTexture = try loadFarbfeldImage("face.ff", c.GL_TEXTURE1);

    // vertex array object: Stores attributes for a vbo.
    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);
    // c.glGenBuffers(1, &vao);
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
    c.glVertexAttribPointer(0, 3, try glTypeID(f32), glBool(false), 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // colour
    // c.glVertexAttribPointer(1, 3, try glTypeID(f32), glBool(false), 8 * @sizeOf(f32), @intToPtr(*const c_void, 3 * @sizeOf(f32)));
    // c.glEnableVertexAttribArray(1);
    // c.glVertexAttribPointer(2, 2, try glTypeID(f32), glBool(false), 8 * @sizeOf(f32), @intToPtr(*const c_void, 6 * @sizeOf(f32)));
    // c.glEnableVertexAttribArray(2);

    //...

    // preparation
    c.glClearColor(0.2, 0.3, 0.3, 1.0);
    // c.glBindTexture(c.GL_TEXTURE_2D, wallTexture);
    c.glBindVertexArray(vao);

    var zoom_size: f32 = 2.0;
    var position = [2]f32{ 0.0, 0.0 };
    var max_count: i32 = 300;
    var shade_scale: f32 = 5;

    // try shaderProgram.setUniform(i32, "boxTexture", 0);
    // try shaderProgram.setUniform(i32, "wallTexture", 1);

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        var time = @floatCast(f32, c.glfwGetTime());

        if (c.glfwGetKey(win, c.GLFW_KEY_C) == c.GLFW_PRESS) {
            max_count += 5;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_V) == c.GLFW_PRESS) {
            max_count -= 5;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_Z) == c.GLFW_PRESS) {
            zoom_size *= 0.99;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_X) == c.GLFW_PRESS) {
            zoom_size *= 1.01;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_A) == c.GLFW_PRESS) {
            shade_scale *= 0.99;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_S) == c.GLFW_PRESS) {
            shade_scale *= 1.01;
        }

        if (c.glfwGetKey(win, c.GLFW_KEY_UP) == c.GLFW_PRESS) {
            position[1] += 0.01 * zoom_size;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_DOWN) == c.GLFW_PRESS) {
            position[1] -= 0.01 * zoom_size;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS) {
            position[0] += 0.01 * zoom_size;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_LEFT) == c.GLFW_PRESS) {
            position[0] -= 0.01 * zoom_size;
        }

        if (c.glfwGetKey(win, c.GLFW_KEY_R) == c.GLFW_PRESS) {
            position = [2]f32{ 0, 0 };
            zoom_size = 2.0;
            max_count = 300;
            shade_scale = 5;
        }

        try shaderProgram.setUniform(f32, "size", zoom_size);
        try shaderProgram.setUniform([2]f32, "position", position);
        try shaderProgram.setUniform(i32, "max_count", max_count);
        try shaderProgram.setUniform(f32, "shade_scale", shade_scale);

        // var green = (std.math.sin(time / 3) / 2.0) + 0.5;
        // try shaderProgram.setUniform([3]f32, "ourColour", [3]f32{ 0.0, green, 0.0 });
        // var ourColourLoc = c.glGetUniformLocation(shaderProgram, "ourColour");
        // var timeLoc = try shaderProgram.getUniform("glfwTime");
        // c.glUniform4f(ourColourLoc, 0.0, green, 0.0, 1.0);
        // try shaderProgram.setUniform(f32, "glfwTime", time);

        // Rendering
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glDrawElements(c.GL_TRIANGLES, 6, try glTypeID(@TypeOf(indices[0])), null);
        // c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        // std.time.sleep(std.time.ns_per_s / 60);
        // Events and Buffers
        c.glfwSwapBuffers(win);
        c.glfwPollEvents();
    }
}

fn loadFarbfeldImage(name: [:0]const u8, textureUnit: c.GLenum) !c.GLuint {
    var texture: c.GLuint = undefined;
    var image: *c.farb_Image = c.farb_load(name) orelse return error.ImageLoadFailed;
    defer c.farb_destroy(image);

    std.log.info("Loaded image of width {} and height {}", .{ image.width, image.height });

    c.glGenTextures(1, &texture);
    c.glActiveTexture(textureUnit);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, image.width, image.height, 0, c.GL_RGBA, c.GL_UNSIGNED_SHORT, image.data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return texture;
}
