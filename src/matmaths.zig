const std = @import("std");

const ElemT = f32;

pub fn vec(len: usize) type {
    return std.meta.Vector(len, ElemT);
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
    var prod: vec(3) = undefined;

    var i: usize = 0;
    inline while (i < a.len) : (i += 1) {
        prod[i] = a[(i + 1) % 3] * b[(i + 2) % 3] - a[(i + 2) % 3] * b[(i + 1) % 3];
    }

    return prod;
}
