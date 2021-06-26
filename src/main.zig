const c = @cImport({
    @cInclude("sigl.h");
    @cInclude("farbfeld.h");
});

const std = @import("std");
const m = std.math;
const ut = @import("utilgl.zig");
const sha = @import("shader.zig");
const mat = @import("matmaths.zig");

const Shader = sha.Shader;

fn rotateMatrixZ(angle: f32) mat.mat(4) {
    // zig fmt: off
    return mat.mat(4) {
        m.cos(angle), -m.sin(angle), 0, 0,
        m.sin(angle), m.cos(angle), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    // zig fmt: on
}

fn rotateMatrixX(angle: f32) mat.mat(4) {
    // zig fmt: off
    return mat.mat(4) {
        1, 0, 0, 0,
        0, m.cos(angle), -m.sin(angle), 0,
        0, m.sin(angle), m.cos(angle), 0,
        0, 0, 0, 1,
    };
    // zig fmt: on
}

fn rotateMatrixY(angle: f32) mat.mat(4) {
    // zig fmt: off
    return mat.mat(4) {
        m.cos(angle), 0, m.sin(angle), 0,
        0, 1, 0, 0,
        -m.sin(angle), 0, m.cos(angle), 0,
        0, 0, 0, 1,
    };
    // zig fmt: on
}

fn translateMatrix(motion: mat.vec(3)) mat.mat(4) {
    // zig fmt: off
    return mat.mat(4){
        1, 0, 0, motion[0],
        0, 1, 0, motion[1],
        0, 0, 1, motion[2],
        0, 0, 0, 1
    };
}

inline fn scaleMatrix(scale: mat.vec(3)) mat.mat(4) {
    return mat.mat(4){
        scale[0], 0,     0,     0,
        0,     scale[1], 0,     0,
        0,     0,     scale[2], 0,
        0,     0,     0,     1,
    };
}

inline fn singleScaleMatrix(scale: f32) mat.mat(4) {
    return scaleMatrix(.{scale, scale, scale});
}

fn simpleOrthographicProjection(centre: mat.vec(3), scale: mat.vec(3)) mat.mat(4) {
    var scaledCentre = centre / scale;
    return .{
        1.0/scale[0], 0, 0, -scaledCentre[0],
        0, 1.0/scale[1], 0, -scaledCentre[1],
        0, 0, -1.0/scale[2], scaledCentre[2],
        0, 0, 0, 1.0,
    };
}

fn perspectiveProjection(l: f32, r: f32, b: f32, t: f32, n: f32, f: f32) mat.mat(4) {
    return .{
        2*n/(r-l), 0, (r+l) / (r-l), 0,
        0, 2*n/(t-b), (b+t) / (t-b), 0,
        0, 0, - (f + n)/ (f - n), -2 * f * n / (f - n),
        0, 0, -1, 0,
    };
}

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});

    // zig fmt: off
    const scale_factor = 2.0;
    const front = 0.5 / scale_factor;
    const back = 1.0 - 0.5 / scale_factor;
    const vertices = [_]f32{
        1.0, 1.0, 0.0, 0.9, 0.0, 0.0, back, back, // top right
        1.0, -1.0, 0.0, 0.0, 0.9, 0.0, back, front, // bottom right
        -1.0, -1.0, 0.0, 0.0, 0.0, 0.9, front, front, // bottom left
        -1.0, 1.0, 0.0, 0.9, 0.9, 0.0, front, back, // top left
        // 0.0, -1.0, 0.0, 0.0, 0.9, 0.9, // bottom middle
    };

    const cubeVertices = [_]f32 {
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
        // 1, 2, 4, // third triangle
    };
    const textureCoords = [_]f32{
        0.0, 0.0, // lower-left
        1.0, 0.0, // lower-right
        0.5, 1.0, // top-center
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

    var squareShader = shadProcBlk: {
        var shaderSources = [_]Shader.Source{
            .{
                .shaderType = c.GL_VERTEX_SHADER,
                .code = @embedFile("vertex.glsl"),
            },
            .{
                .shaderType = c.GL_FRAGMENT_SHADER,
                .code = @embedFile("fragment.glsl"),
            },
        };
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        break :shadProcBlk try Shader.makeProgramStrings(&shaderSources, &gpa.allocator);
    };
    squareShader.use();

    // Cube shader.
    var cubeShader = cubeShaderBlk: {
        var shaderSources = [_]Shader.Source{
            .{
                .shaderType = c.GL_VERTEX_SHADER,
                .code = @embedFile("cubeVertex.glsl"),
            },
            .{
                .shaderType = c.GL_FRAGMENT_SHADER,
                .code = @embedFile("cubeFragment.glsl"),
            },
        };
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        break :cubeShaderBlk try Shader.makeProgramStrings(&shaderSources, &gpa.allocator);
    };

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
    // position
    c.glVertexAttribPointer(0, 3, try ut.glTypeID(f32), ut.glBool(false), 8 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // colour
    c.glVertexAttribPointer(1, 3, try ut.glTypeID(f32), ut.glBool(false), 8 * @sizeOf(f32), @intToPtr(*const c_void, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribPointer(2, 2, try ut.glTypeID(f32), ut.glBool(false), 8 * @sizeOf(f32), @intToPtr(*const c_void, 6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    // cube stuff
    var cubeVao: c.GLuint = undefined;
    var cubeVbo: c.GLuint = undefined;
    c.glGenVertexArrays(1, &cubeVao);
    c.glGenBuffers(1, &cubeVbo);

    c.glBindVertexArray(cubeVao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, cubeVbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(cubeVertices)), &cubeVertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, try ut.glTypeID(f32), ut.glBool(false), 5 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(1, 2, try ut.glTypeID(f32), ut.glBool(false), 5 * @sizeOf(f32), @intToPtr(*const c_void, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

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
    var cameraRotation = [2]f32{ 0.0, 0.0 };

    // projection
    var eyeCoords = mat.vec(3){ 0.0, 0.0, -3.0 };
    // var camScales = mat.vec(3){ 1.0, 1.0, 100.0 };
    var viewportSize: [4]f32 = undefined;
    var orthographic = false;

    // Main Loop
    while (c.glfwWindowShouldClose(win) != c.GLFW_TRUE) {
        var time = @floatCast(f32, c.glfwGetTime());

        // c.glGetFloatv(c.GL_VIEWPORT, &viewportSize);
        // camScales[0] = viewportSize[2] / (1000.0);
        // camScales[1] = viewportSize[3] / (1000.0);
        // std.log.info("Viewport size: {} {}.", .{ camScales[0], camScales[1] });

        // input
        var coordsChanged = false;
        if (c.glfwGetKey(win, c.GLFW_KEY_A) == c.GLFW_PRESS) {
            eyeCoords[0] -= 0.05;
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_D) == c.GLFW_PRESS) {
            eyeCoords[0] += 0.05;
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_F) == c.GLFW_PRESS) {
            eyeCoords[1] -= 0.05;
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_R) == c.GLFW_PRESS) {
            eyeCoords[1] += 0.05;
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_W) == c.GLFW_PRESS) {
            eyeCoords[2] -= 0.05;
            coordsChanged = true;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_S) == c.GLFW_PRESS) {
            eyeCoords[2] += 0.05;
            coordsChanged = true;
        }
        if (coordsChanged) {
            std.log.info("Eye coords: {} {} {}", .{ eyeCoords[0], eyeCoords[1], eyeCoords[2] });
        }
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
        if (c.glfwGetKey(win, c.GLFW_KEY_E) == c.GLFW_PRESS) {
            cameraRotation[0] += 0.05;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_Q) == c.GLFW_PRESS) {
            cameraRotation[0] -= 0.05;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_C) == c.GLFW_PRESS) {
            cameraRotation[1] += 0.05;
        }
        if (c.glfwGetKey(win, c.GLFW_KEY_Z) == c.GLFW_PRESS) {
            cameraRotation[1] -= 0.05;
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

        // view culling
        const viewMatrix = mat.matProd(&.{
            translateMatrix(-eyeCoords),
            rotateMatrixX(cameraRotation[1]),
            rotateMatrixY(cameraRotation[0]),
        });
        squareShader.use();
        try squareShader.setUniform(*const mat.mat(4), "view", &viewMatrix);
        cubeShader.use();
        try cubeShader.setUniform(*const mat.mat(4), "view", &viewMatrix);

        // translated in positive z direction so it will always be in front.
        const squareModelMatrices = [_]mat.mat(4){
            mat.matProd(&[_]mat.mat(4){
                rotateMatrixX(-2.0 * time),
                rotateMatrixZ(time),
                translateMatrix(.{ m.sin(time), m.cos(time), 1.0 }),
            }),
            mat.matProd(&[_]mat.mat(4){
                singleScaleMatrix(0.8 + m.sin(time) / 5.0),
                translateMatrix(.{ -0.5, 0.5, m.sin(time) * 2.0 }),
            }),
        };

        // Rendering
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        // cubes

        c.glBindVertexArray(cubeVao);
        cubeShader.use();

        const cubeModelTranslations = [_]mat.mat(4){
            translateMatrix(.{ 0.0, 0.0, 0.0 }),
            translateMatrix(.{ 2.0, 5.0, -15.0 }),
            translateMatrix(.{ -1.5, -2.2, -2.5 }),
            translateMatrix(.{ -3.8, -2.0, -12.3 }),
            translateMatrix(.{ 2.4, -0.4, -3.5 }),
            translateMatrix(.{ -1.7, 3.0, -7.5 }),
            translateMatrix(.{ 1.3, -2.0, -2.5 }),
            translateMatrix(.{ 1.5, 2.0, -2.5 }),
            translateMatrix(.{ 1.5, 0.2, -1.5 }),
            translateMatrix(.{ -1.3, 1.0, -1.5 }),
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
            var thisTransform = mat.matProd(&.{ rotateMatrixZ(rotateRate), wobbleTransform, transform });

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
            c.glDrawElements(c.GL_TRIANGLES, 6, try ut.glTypeID(@TypeOf(indices[0])), null);
        }

        // First box
        c.glDrawElements(c.GL_TRIANGLES, 6, try ut.glTypeID(@TypeOf(indices[0])), null);
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
