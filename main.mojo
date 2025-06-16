import time
from sys import sizeof
from playground import *
from playground import utils



alias Vec3 = Tuple[Float32, Float32, Float32]
alias Vec4 = Tuple[Float32, Float32, Float32, Float32]

@value
struct Vertex(Writable):
    var position: Vec3
    var color: Vec4

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], ")")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")

alias vertices = [
    Vertex(position=Vec3(0.0, 0.5, 0.0), color=Vec4(1.0, 0.0, 0.0, 1.0)),
    Vertex(position=Vec3(0.5, -0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
    Vertex(position=Vec3(-0.5, -0.5, 0.0), color=Vec4(0.0, 0.0, 1.0, 1.0)),
]

fn app_iterate(
    window: Window,
    device: GPUDevice,
    pipeline: Ptr[SDL_GPUGraphicsPipeline],
    vertex_buffer: GPUBuffer,
    transfer_buffer: GPUTransferBuffer,
) raises:
    cmd = CommandBuffer.acquire(device)

    var swapchain_texture = cmd.wait_and_acquire_gpu_swapchain_texture(window)
    if not swapchain_texture:
        cmd^.submit()
        return
    
    var color_target_info = GPUColorTargetInfo(
        texture=swapchain_texture.value(),
        clear_color=SDL_FColor(r=0.95, g=0.95, b=0.95, a=1.0),
        load_op=SDL_GPULoadOp(SDL_GPULoadOp.SDL_GPU_LOADOP_CLEAR),
        store_op=SDL_GPUStoreOp(SDL_GPUStoreOp.SDL_GPU_STOREOP_STORE),
    )

    var render_pass = GPURenderPass.begin(cmd, color_target_info, 1)

    sdl_bind_gpu_graphics_pipeline(render_pass._render_pass, pipeline)

    buffer_bindings = List(
        SDL_GPUBufferBinding(
            buffer = vertex_buffer._handle,
            offset=0
        )
    )
    var buf_len = len(buffer_bindings)

    sdl_bind_gpu_vertex_buffers(render_pass._render_pass, 0, buffer_bindings.steal_data(), buf_len)
    sdl_draw_gpu_primitives(render_pass._render_pass, 3, 1, 0, 0)

    render_pass.end()
    
    cmd^.submit()

from pathlib import cwd
def main_loop(window: Window, device: GPUDevice):
    print(cwd())
    var vertex_shader = load_shader("shaders/vertex.spv", 
                                    device, 
                                    SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, 
                                    SDL_GPUShaderStage(SDL_GPUShaderStage.SDL_GPU_SHADERSTAGE_VERTEX))
    
    var fragment_shader = load_shader("shaders/fragment.spv", 
                                 device, 
                                 SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, 
                                 SDL_GPUShaderStage(SDL_GPUShaderStage.SDL_GPU_SHADERSTAGE_FRAGMENT))
    
    var vertex_buffer_descriptions = [SDL_GPUVertexBufferDescription(
        slot = 0,
        input_rate = SDL_GPUVertexInputRate(SDL_GPUVertexInputRate.SDL_GPU_VERTEXINPUTRATE_VERTEX),
        instance_step_rate = 0,
        pitch = sizeof[Vertex]()
    )]
    print(sizeof[Vertex]())

    var vertex_attributes = [
        # position
        SDL_GPUVertexAttribute(location=0, buffer_slot=0, format=SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3), offset=0),
        # color
        SDL_GPUVertexAttribute(location=1, buffer_slot=0, format=SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4), offset=sizeof[Vec3]()),
    ]

    print(sizeof[Vec3]())

    var color_target_descriptions = [
        SDL_GPUColorTargetDescription(
            blend_state = SDL_GPUColorTargetBlendState(
                enable_blend = True,
                color_blend_op = SDL_GPUBlendOp(SDL_GPUBlendOp.SDL_GPU_BLENDOP_ADD),
                src_color_blendfactor = SDL_GPUBlendFactor(SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_SRC_ALPHA),
                dst_color_blendfactor = SDL_GPUBlendFactor(SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA),
                alpha_blend_op = SDL_GPUBlendOp(SDL_GPUBlendOp.SDL_GPU_BLENDOP_ADD),
                src_alpha_blendfactor = SDL_GPUBlendFactor(SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE),
                dst_alpha_blendfactor = SDL_GPUBlendFactor(SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA),
                color_write_mask = SDL_GPUColorComponentFlags(0),
                enable_color_write_mask = False,
                padding1 = 0,
                padding2 = 0,
            ),
            format = sdl_get_gpu_swapchain_texture_format(device.device, window.window))
    ]

    var vb_len: UInt32 = len(vertex_buffer_descriptions)
    var va_len: UInt32 = len(vertex_attributes)
    var input_state = SDL_GPUVertexInputState(vertex_buffer_descriptions.steal_data(), vb_len, vertex_attributes.steal_data(), va_len)

    var pipeline_info = SDL_GPUGraphicsPipelineCreateInfo(
        vertex_shader=vertex_shader._handle,
        fragment_shader=fragment_shader._handle,
        primitive_type = SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST),
        vertex_input_state = input_state,
        target_info = utils.init_graphics_pipeline_target_info(color_target_descriptions^),
        rasterizer_state = utils.init_rasterizer_state(),
        multisample_state = utils.init_multi_sample_state(),
        depth_stencil_state = utils.init_depth_stencil_state(),
        props = SDL_PropertiesID(0)
    )
    var pipeline = sdl_create_gpu_graphics_pipeline(device.device, Ptr(to=pipeline_info))
    _ = vertex_shader^
    _ = fragment_shader^

    var vertices_size = sizeof[Vertex]()*len(vertices)
    var vertex_buffer = GPUBuffer(device, SDL_GPUBufferUsageFlags.SDL_GPU_BUFFERUSAGE_VERTEX, vertices_size)
    var transfer_buffer = GPUTransferBuffer(device, SDL_GPUTransferBufferUsage(SDL_GPUTransferBufferUsage.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD), vertices_size)
    var data = transfer_buffer.map_gpu_transfer_buffer[Vertex]()
    data[0] = vertices[0]
    data[1] = vertices[1]
    data[2] = vertices[2]
    print("data[0]:", data[0])
    print("data[1]:", data[1])
    print("data[2]:", data[2])

    transfer_buffer.unmap_gpu_transfer_buffer()

    var cmd = CommandBuffer.acquire(device)
    var copy_pass = cmd.begin_gpu_copy_pass()
    
    var location = SDL_GPUTransferBufferLocation (
        transfer_buffer = transfer_buffer._handle,
        offset = 0,
    )
    var region = SDL_GPUBufferRegion(
        buffer = vertex_buffer._handle,
        offset = 0,
        size = vertices_size,
    )

    sdl_upload_to_gpu_buffer(copy_pass, Ptr(to=location), Ptr(to=region), False)
    # TODO make copy pass a memory safe struct
    sdl_end_gpu_copy_pass(copy_pass)
    cmd^.submit()

    var running = True
    while running:
        var event = SDL_Event(UInt32(0))
        while sdl_poll_event(Ptr(to=event)):
            if event[SDL_CommonEvent].type == SDL_EventType.SDL_EVENT_QUIT:
                running = False
                break # Exit event polling loop
        
        if not running: # If quit event was processed
            break
        app_iterate(window, device, pipeline, vertex_buffer, transfer_buffer)

    sdl_release_gpu_graphics_pipeline(device.device, pipeline)
    

def main():
    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)
    window = Window("SDL Window", 1024, 768, SDL_WindowFlags.SDL_WINDOW_RESIZABLE)
    var device = GPUDevice(SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, True, 'vulkan')
    sdl_claim_window_for_gpu_device(device.device, window.window)

    main_loop(window, device)
    sdl_release_window_from_gpu_device(device.device, window.window)
    sdl_quit()
    # time.sleep(10.0)
