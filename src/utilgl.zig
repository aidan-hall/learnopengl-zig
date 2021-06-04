const c = @cImport({
    @cInclude("glad/glad.h");
});

pub inline fn glBool(cond: bool) c.GLchar {
    if (cond == true)
        return c.GL_TRUE
    else
        return c.GL_FALSE;
}

pub fn glTypeID(comptime attrib: type) !comptime c.GLenum {
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
