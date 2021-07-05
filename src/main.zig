const c = @cImport({
    @cInclude("sigl.h");
    @cInclude("farbfeld.h");
});

const std = @import("std");
const m = std.math;
const ut = @import("utilgl.zig");
const sha = @import("shader.zig");
const mat = @import("matmaths.zig");
const cam = @import("camera.zig");

const Shader = sha.Shader;

var mousex: f32 = 0.0;
var mousey: f32 = 0.0;

fn vertexAttribConfig(format: []const c.GLint) void {
    var nAttributes: c.GLint = 0;
    for (format) |count| {
        nAttributes += count;
    }

    var position: c.GLuint = 0;
    for (format) |count, loc| {
        defer position += @intCast(c.GLuint, count);

        c.glVertexAttribPointer(@intCast(c.GLuint, loc), count, try ut.glTypeID(f32), ut.glBool(false), nAttributes * @sizeOf(f32), @intToPtr(?*const c_void, position * @sizeOf(f32)));
        c.glEnableVertexAttribArray(@intCast(c.GLuint, loc));
    }
}
inline fn scaleMatrix(scale: mat.vec(3)) mat.mat(4) {
    return mat.mat(4){
        scale[0], 0,        0,        0,
        0,        scale[1], 0,        0,
        0,        0,        scale[2], 0,
        0,        0,        0,        1,
    };
}

inline fn singleScaleMatrix(scale: f32) mat.mat(4) {
    return scaleMatrix(.{ scale, scale, scale });
}

fn simpleOrthographicProjection(centre: mat.vec(3), scale: mat.vec(3)) mat.mat(4) {
    var scaledCentre = centre / scale;
    return .{
        1.0 / scale[0], 0,              0,               -scaledCentre[0],
        0,              1.0 / scale[1], 0,               -scaledCentre[1],
        0,              0,              -1.0 / scale[2], scaledCentre[2],
        0,              0,              0,               1.0,
    };
}

fn perspectiveProjection(l: f32, r: f32, b: f32, t: f32, n: f32, f: f32) mat.mat(4) {
    return .{
        2 * n / (r - l), 0,               (r + l) / (r - l),  0,
        0,               2 * n / (t - b), (b + t) / (t - b),  0,
        0,               0,               -(f + n) / (f - n), -2 * f * n / (f - n),
        0,               0,               -1,                 0,
    };
}

fn lookAt(pos: mat.vec(3), target: mat.vec(3), up: mat.vec(3)) mat.mat(4) {
    const camDir = mat.norm(pos - target);
    const camRight = mat.norm(mat.cross(up, camDir));
    const camUp = mat.cross(camDir, camRight);

    return mat.matProd(&.{
        mat.translateMatrix(-pos),
        cam.coordSystem(camRight, camUp, camDir),
    });
}

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});

    const vertices = [_]f32{
        1.0, 1.0, 0.0, 0.9, 0.0, 0.0, 2.0, 2.0, // top right
        1.0, -1.0, 0.0, 0.0, 0.9, 0.0, 2.0, -1.0, // bottom right
        -1.0, -1.0, 0.0, 0.0, 0.0, 0.9, -1.0, -1.0, // bottom left
        -1.0, 1.0, 0.0, 0.9, 0.9, 0.0, -1.0, 2.0, // top left
    };

    const cubeVertices = [_]f32{
        -0.5, -0.5, -0.5, 0.0, 0.0,
        0.5,  -0.5, -0.5, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 0.0,

        -0.5, -0.5, 0.5,  0.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5, 0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,

        -0.5, 0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  -0.5, 1.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, 0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, 0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 1.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,

        -0.5, 0.5,  -0.5, 0.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  0.5,  0.0, 0.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };
    const textureCoords = [_]f32{
        0.0, 0.0, // lower-left
        1.0, 0.0, // lower-right
        0.5, 1.0, // top-center
    };

    // Setup.
    var win = c.setup(200, 200, "Nice GLFW", null, null) orelse return error.SiglInit;
    defer c.cleanup(win);
    c.glfwSetInputMode(win, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

    {
        var nAttrs: c_int = undefined;
        c.glGetIntegerv(c.GL_MAX_VERTEX_ATTRIBS, &nAttrs);
        std.log.info("Max attrs: {}", .{nAttrs});
    }

    // This is the way to use the fully generic method.
    // var squareShader = shadProcBlk: {
    //     var shaderSources = [_]Shader.Source{
    //         .{
    //             .shaderType = c.GL_VERTEX_SHADER,
    //             .code = @embedFile("vertex.glsl"),
    //         },
    //         .{
    //             .shaderType = c.GL_FRAGMENT_SHADER,
    //             .code = @embedFile("fragment.glsl"),
    //         },
    //     };
    //     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //     break :shadProcBlk try Shader.makeProgramStrings(&shaderSources, &gpa.allocator);
    // };

    var squareShader = try Shader.createBasic(@embedFile("vertex.glsl"), @embedFile("fragment.glsl"));
    var cubeShader = try Shader.createBasic(@embedFile("cubeVertex.glsl"), @embedFile("cubeFragment.glsl"));

    // texture rendering parameters:
    {
        // wrapping
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_MIRRORED_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_MIRRORED_REPEAT);

        // border
        const borderColour = [_]f32{ 1.0, 1.0, 0.0, 1.0 };
        c.glTexParameterfv(c.GL_TEXTURE_2D, c.GL_TEXTURE_BORDER_COLOR, &borderColour);

        // filtering and mipmaps
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    }

    // texture loading
    var boxTexture = try loadFarbfeldImage("wall.ff", c.GL_TEXTURE0);
    var wallTexture = try loadFarbfeldImage("face.ff", c.GL_TEXTURE1);

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
    vertexAttribConfig(&.{ 3, 3, 2 });
    // // position

    // cube stuff
    var cubeVao: c.GLuint = undefined;
    var cubeVbo: c.GLuint = undefined;
    c.glGenVertexArrays(1, &cubeVao);
    c.glGenBuffers(1, &cubeVbo);

    c.glBindVertexArray(cubeVao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, cubeVbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(cubeVertices)), &cubeVertices, c.GL_STATIC_DRAW);

    vertexAttribConfig(&.{ 3, 2 });

    // preparation
    c.glClearColor(0.2, 0.3, 0.3, 1.0);
    // c.glBindTexture(c.GL_TEXTURE_2D, wallTexture);
    c.glBindVertexArray(vao);

    squareShader.use();
    try squareShader.setUniform(i32, "boxTexture", 0);
    try squareShader.setUniform(i32, "wallTexture", 1);
    cubeShader.use();
    try cubeShader.setUniform(i32, "boxTexture", 0);
    try cubeShader.setUniform(i32, "wallTexture", 1);

    var wave_speed: f32 = 1.0;
    var faceOpacity: f32 = 0.5;

    // camera
    var camera = cam.NiceCamera(.{ 0, 0, 3 }, .{ 0, 0, -1 });
    // var camera = cam.Camera{
    //     .pos = .{ 0.0, 0.0, 3.0 },
    //     .up = .{ 0, 1, 0 },
    //     .front = .{ 0, 0, -1 },
    //     .right = undefined,
    //     .spaceUp = undefined,
    // };
    // camera.updateBases();
    // camera.lookAt(.{ 0, 0, 0 });
    // camera.updateBases();

    var viewportSize: [4]f32 = undefined;
    var orthographic = false;
    var prevTime: f32 = 0.0;
    var delta: f32 = 0.0;

    var pitch: f32 = 0.0;
    var yaw: f32 = -std.math.pi / 2.0;

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        var time = @floatCast(f32, c.glfwGetTime());
        delta = time - prevTime;
        prevTime = time;

        // input
        var coordsChanged = false;
        const speed = 2.0 * delta;
        if (c.glfwGetKey(win, c.GLFW_KEY_A) == c.GLFW_PRESS) {
            camera.move(camera.right, -speed);
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_D) == c.GLFW_PRESS) {
            camera.move(camera.right, speed);
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_F) == c.GLFW_PRESS) {
            camera.move(camera.spaceUp, -speed);
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_R) == c.GLFW_PRESS) {
            camera.move(camera.spaceUp, speed);
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_W) == c.GLFW_PRESS) {
            camera.move(camera.front, speed);
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_S) == c.GLFW_PRESS) {
            camera.move(camera.front, -speed);
            coordsChanged = true;
        }
        if (coordsChanged) {
            std.log.info("Eye coords: {} {} {}", .{ camera.pos[0], camera.pos[1], camera.pos[2] });
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_E) == c.GLFW_PRESS) {
            yaw -= 2 * delta;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_Q) == c.GLFW_PRESS) {
            yaw += 2 * delta;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_C) == c.GLFW_PRESS) {
            pitch -= 2 * delta;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_Z) == c.GLFW_PRESS) {
            pitch += 2 * delta;
        }
        camera.lookEuler(pitch, yaw);
        if (c.glfwGetKey(win, c.GLFW_KEY_LEFT) == c.GLFW_PRESS) {
            faceOpacity += 0.05;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS) {
            faceOpacity -= 0.05;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_UP) == c.GLFW_PRESS) {
            wave_speed += 0.1;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_DOWN) == c.GLFW_PRESS) {
            wave_speed -= 0.1;
        }

        if (c.glfwGetKey(win, c.GLFW_KEY_M) == c.GLFW_PRESS) {
            orthographic = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_N) == c.GLFW_PRESS) {
            orthographic = false;
        }

        // transformations

        squareShader.use();
        try squareShader.setUniform(f32, "glfwTime", time * wave_speed);
        try squareShader.setUniform(f32, "faceOpacity", faceOpacity);

        cubeShader.use();
        try cubeShader.setUniform(f32, "faceOpacity", faceOpacity);

        // projection
        const projectionShape = projectionBlock: {
            if (orthographic) {
                break :projectionBlock comptime simpleOrthographicProjection(.{ 0, 0, 0 }, .{ 10, 10, 10 });
            } else {
                break :projectionBlock comptime perspectiveProjection(-0.1, 0.1, -0.1, 0.1, 0.1, 100.0);
            }
        };
        squareShader.use();
        try squareShader.setUniform(*const mat.mat(4), "projection", &projectionShape);
        cubeShader.use();
        try cubeShader.setUniform(*const mat.mat(4), "projection", &projectionShape);

        // view culling/camera
        var viewMatrix = camera.lookMatrix();
        // var viewMatrix = lookAt(eyeCoords, .{ 0, 0, 0 }, .{ 0, 1, 0 });

        squareShader.use();
        try squareShader.setUniform(*const mat.mat(4), "view", &viewMatrix);
        cubeShader.use();
        try cubeShader.setUniform(*const mat.mat(4), "view", &viewMatrix);

        // translated in positive z direction so it will always be in front.
        const squareModelMatrices = [_]mat.mat(4){
            mat.matProd(&[_]mat.mat(4){
                mat.rotateMatrixX(-2.0 * time),
                mat.rotateMatrixZ(time),
                mat.translateMatrix(.{ m.sin(time), m.cos(time), 1.0 }),
            }),
            mat.matProd(&[_]mat.mat(4){
                singleScaleMatrix(0.8 + m.sin(time) / 5.0),
                mat.translateMatrix(.{ -0.5, 0.5, m.sin(time) * 2.0 }),
            }),
        };

        // Rendering
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        // cubes

        c.glBindVertexArray(cubeVao);
        cubeShader.use();

        const cubeModelTranslations = [_]mat.mat(4){
            mat.translateMatrix(.{ 0.0, 0.0, 0.0 }),
            mat.translateMatrix(.{ 2.0, 5.0, -15.0 }),
            mat.translateMatrix(.{ -1.5, -2.2, -2.5 }),
            mat.translateMatrix(.{ -3.8, -2.0, -12.3 }),
            mat.translateMatrix(.{ 2.4, -0.4, -3.5 }),
            mat.translateMatrix(.{ -1.7, 3.0, -7.5 }),
            mat.translateMatrix(.{ 1.3, -2.0, -2.5 }),
            mat.translateMatrix(.{ 1.5, 2.0, -2.5 }),
            mat.translateMatrix(.{ 1.5, 0.2, -1.5 }),
            mat.translateMatrix(.{ -1.3, 1.0, -1.5 }),
        };

        for (cubeModelTranslations) |transform, idx| {

            // wobble
            const wobbleCentre = 0.9;
            const wobbleMag = 0.1;
            const wobbleTransform = scaleMatrix(.{
                wobbleAbout(wobbleCentre, wobbleMag, m.sin(time * wave_speed)),
                wobbleAbout(wobbleCentre, wobbleMag, m.cos(time * wave_speed)),
                1.0,
            });

            var rotateRate: f32 = if ((idx % 3) == 0) time else @intToFloat(f32, idx);
            var thisTransform = mat.matProd(&.{ mat.rotateMatrixZ(rotateRate), wobbleTransform, transform });

            try cubeShader.setUniform(*const mat.mat(4), "model", &thisTransform);
            c.glDrawArrays(c.GL_TRIANGLES, 0, 36);
        }

        // drawing squares
        c.glBindVertexArray(vao);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        squareShader.use();
        // squares
        for (squareModelMatrices) |model| {
            try squareShader.setUniform(*const mat.mat(4), "model", &model);
            c.glDrawElements(c.GL_TRIANGLES, 6, try ut.glTypeID(u32), null);
        }

        // First box
        c.glDrawElements(c.GL_TRIANGLES, 6, try ut.glTypeID(u32), null);
        // c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        std.time.sleep(std.time.ns_per_s / 60);
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

fn wobbleAbout(centre: f32, mag: f32, pos: f32) f32 {
    return centre + mag * pos;
}

// pub export fn keyCallback(window: ?*GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
//     if (action == c.GLFW_RELEASE) {
//         switch (key) {
//             c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GLFW_TRUE),

//             c.GLFW_KEY_O => {
//                 var polyMode: c_int = undefined;
//                 c.glGetIntegerv(c.GL_POLYGON_MODE, &polyMode);
//                 if (polyMode == c.GL_LINE) {
//                     c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
//                 } else {
//                     c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
//                 }
//             },
//         }
//     }
// }

pub export fn mouseCallback(win: ?*c.GLFWwindow, x: f32, y: f32) void {
    mousex = x;
    mousey = y;
}
