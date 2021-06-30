const std = @import("std");

const ElemT = f32;

pub fn vec(len: usize) type {
    return std.meta.Vector(len, ElemT);
}

pub inline fn dot(a: vec(3), b: vec(3)) f32 {
    const prod = a * b;
    return prod[0] + prod[1] + prod[2];
}

pub fn magSquared(x: vec(3)) f32 {
    return dot(x, x);
}

pub fn norm(x: vec(3)) vec(3) {
    const mag = std.math.sqrt(magSquared(x));
    return .{ x[0] / mag, x[1] / mag, x[2] / mag };
}

// pub const vec4 = vec(4);
// pub const vec3 = vec(3);

pub fn mat(sideLen: usize) type {
    return std.meta.Vector(sideLen * sideLen, ElemT);
}

// pub const mat4 = mat(4);

pub const Identity = mat(4){
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0,
};

pub inline fn mat4Coord(x: usize, y: usize) usize {
    // x: column
    // y: row
    return x + y * 4;
}

pub inline fn matProd(matrices: []const mat(4)) mat(4) {
    var product = matrices[matrices.len - 1];
    var index: usize = matrices.len - 1;

    while (index > 0) {
        index -= 1;
        product = new_prod_blk: {
            const next = matrices[index];
            var new_product = mat(4){};

            var next_col: usize = 0;
            while (next_col < 4) : (next_col += 1) {
                var product_row: usize = 0;
                while (product_row < 4) : (product_row += 1) {
                    var current_item: usize = 0;
                    while (current_item < 4) : (current_item += 1) {
                        new_product[mat4Coord(next_col, product_row)] += next[mat4Coord(next_col, current_item)] * product[mat4Coord(current_item, product_row)];
                    }
                }
            }

            break :new_prod_blk new_product;
        };
    }
    return product;
}

pub inline fn cross(a: vec(3), b: vec(3)) vec(3) {
    // return .{
    //     a[1] * b[2] - a[2] * b[1],
    //     a[2] * b[0] - a[0] * b[2],
    //     a[0] * b[1] - a[1] * b[0],
    // };
    var prod: vec(3) = undefined;

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        prod[i] = a[(i + 1) % 3] * b[(i + 2) % 3] - a[(i + 2) % 3] * b[(i + 1) % 3];
    }

    return prod;
}

fn vecCmp(a: vec(3), b: vec(3)) bool {
    return a[0] == b[0] and a[1] == b[1] and a[2] == b[2];
}

test "cross product" {
    std.debug.assert(vecCmp(cross(.{ 1, 0, 0 }, .{ 0, 1, 0 }), .{ 0, 0, 1 }));
}
