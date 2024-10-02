const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

const shader = @import("shaders/triangle.glsl.zig");

const max_obj: u32 = 1000;

const state = struct {
    var pass_action: sg.PassAction = .{};
    var bind: sg.Bindings = .{};
    var pipe: sg.Pipeline = .{};
    var pos: [3 * max_obj]f32 = std.mem.zeroes([3*max_obj]f32);
    var scale: [max_obj]f32 = std.mem.zeroes([max_obj]f32);
    var vs_params: shader.VsParams = .{ .aspectRatio = 0.5 };
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    sokol.time.setup();

    var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    var rng = prng.random();

    for (0..max_obj) |i| {
        const current_idx = i * 3;
        state.pos[current_idx + 0] = rng.float(f32) * 2.0 - 1.0;
        state.pos[current_idx + 1] = rng.float(f32) * 2.0 - 1.0;
        state.scale[i] = rng.float(f32) * 20.0 + 20.0;
    }

    const verts = [_]f32 {
         0.0,  2.0, 0.0,
        -1.7321, -1.0, 0.0,
         1.7321, -1.0, 0.0,
    };

    const index = [_]u16 {
        0, 1, 2,
    };

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .type = .VERTEXBUFFER,
        .data = sg.asRange(&verts),
    });

    state.bind.vertex_buffers[1] = sg.makeBuffer(.{
        .size = @sizeOf(f32) * 3 * max_obj,
        .usage = .STREAM,
    });

    state.bind.vertex_buffers[2] = sg.makeBuffer(.{
        .size = @sizeOf(f32) * max_obj,
        .usage = .STREAM,
    });

    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(&index),
    });

    var pipe_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shader.triangleShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
    };

    pipe_desc.layout.attrs[0].format = .FLOAT3;

    pipe_desc.layout.attrs[1].format = .FLOAT3;
    pipe_desc.layout.attrs[1].buffer_index = 1;
    pipe_desc.layout.buffers[1].step_func = .PER_INSTANCE;

    pipe_desc.layout.attrs[2].format = .FLOAT;
    pipe_desc.layout.attrs[2].buffer_index = 2;
    pipe_desc.layout.buffers[2].step_func = .PER_INSTANCE;

    state.pipe = sg.makePipeline(pipe_desc);

    sg.updateBuffer(state.bind.vertex_buffers[2], sg.asRange(&state.scale));
    sg.updateBuffer(state.bind.vertex_buffers[1], sg.asRange(&state.pos));

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 },
    };
}

fn timef() f32 {
    return @floatCast(sokol.time.sec(sokol.time.now()));
}

export fn frame() void {
    state.vs_params.aspectRatio = sapp.heightf() / sapp.widthf();

    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sglue.swapchain(),
    });
    sg.applyPipeline(state.pipe);
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&state.vs_params));
    sg.applyBindings(state.bind);
    sg.draw(0, 3, max_obj);
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

export fn event(ev: ?*const sapp.Event) void {
    const evnt = ev.?;
    if (evnt.type == .KEY_DOWN) {
        std.debug.print("{?}\n", .{evnt.key_code});
        switch (evnt.key_code) {
            .F => sapp.toggleFullscreen(),
            .Q => sapp.requestQuit(),
            else => {}
        }
    }
}

pub fn main() !void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "sokol with zig",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
