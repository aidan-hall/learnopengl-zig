const std = @import("std");

const mat = @import("matmaths.zig");

fn coordSystem(A: mat.vec(3), B: mat.vec(3), C: mat.vec(3)) mat.mat(4) {
    return .{
        A[0], A[1], A[2], 0,
        B[0], B[1], B[2], 0,
        C[0], C[1], C[2], 0,
        0,    0,    0,    1,
    };
}

pub const Camera = struct {
    pos: mat.vec(3),
    front: mat.vec(3),

    up: mat.vec(3),

    right: mat.vec(3),
    spaceUp: mat.vec(3),

    /// Use to update the values of right and spaceUp basis vectors if up or front change.
    pub fn updateBases(self: *Camera) void {
        self.right = mat.norm(mat.cross(self.up, self.front));
        self.spaceUp = mat.cross(self.front, self.right);
    }

    pub fn lookAt(self: *Camera, target: mat.vec(3)) void {
        self.front = mat.norm(self.pos - target);
        self.updateBases();
    }

    pub fn lookMatrix(self: *Camera) mat.mat(4) {
        return mat.matProd(&.{
            mat.translateMatrix(-self.pos),
            // Converting between LH and RH? TODO: Understand before this gets too complicated.
            coordSystem(self.right, self.spaceUp, -self.front),
        });
    }

    pub fn move(self: *Camera, direction: mat.vec(3), dist: f32) void {
        self.pos += mat.vecScaled(direction, dist);
    }

    pub fn lookEuler(self: *Camera, pitch: f32, yaw: f32) void {
        self.front[0] = std.math.cos(yaw) * std.math.cos(pitch);
        self.front[1] = std.math.sin(pitch);
        self.front[2] = std.math.sin(yaw) * std.math.cos(pitch);
        self.front = mat.norm(self.front);
        self.updateBases();
    }
};

pub fn NiceCamera(pos: mat.vec(3), front: mat.vec(3)) Camera {
    var theCam = Camera{
        .pos = pos,
        .up = .{ 0, 1, 0 },
        .front = front,
        .right = undefined,
        .spaceUp = undefined,
    };
    theCam.updateBases();
    return theCam;
}
