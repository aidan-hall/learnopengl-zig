const std = @import("std");

const ElemT = f32;

pub fn vec(len: usize) type {
    return [len]ElemT;
}

// pub const vec4 = vec(4);
// pub const vec3 = vec(3);

pub fn mat(sideLen: usize) type {
    return [sideLen][sideLen]ElemT;
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
            var new_product: mat(4) = undefined;

            var next_col: usize = 0;
            while (next_col < 4) : (next_col += 1) {
                var product_row: usize = 0;
                while (product_row < 4) : (product_row += 1) {
                    var current_item: usize = 0;
                    while (current_item < 4) : (current_item += 1) {
                        new_product[product_row][next_col] += next[current_item][next_col] * product[product_row][current_item];
                    }
                }
            }

            break :new_prod_blk new_product;
        };
    }
    return product;
}

pub inline fn newMatProd(matrices: []const mat(4)) mat(4) {
    std.debug.assert(matrices.len >= 1);
    var product = matrices[0];
    for (matrices) |next| {}

    return product;
}
