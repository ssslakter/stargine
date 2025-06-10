from sdl.gpu import *

fn init_rasterizer_state(
    fill_mode: SDL_GPUFillMode = SDL_GPUFillMode(SDL_GPUFillMode.SDL_GPU_FILLMODE_FILL),
    cull_mode: SDL_GPUCullMode = SDL_GPUCullMode(SDL_GPUCullMode.SDL_GPU_CULLMODE_NONE),
    front_face: SDL_GPUFrontFace = SDL_GPUFrontFace(SDL_GPUFrontFace.SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE),
    depth_bias_constant_factor: Float32 = 0.0,
    depth_bias_clamp: Float32 = 0.0,
    depth_bias_slope_factor: Float32 = 0.0,
    enable_depth_bias: Bool = False,
    enable_depth_clip: Bool = False,
) -> SDL_GPURasterizerState:
    return SDL_GPURasterizerState(
        fill_mode = fill_mode,
        cull_mode = cull_mode,
        front_face = front_face,
        depth_bias_constant_factor = depth_bias_constant_factor,
        depth_bias_clamp = depth_bias_clamp,
        depth_bias_slope_factor = depth_bias_slope_factor,
        enable_depth_bias = enable_depth_bias,
        enable_depth_clip = enable_depth_clip,
        padding1 = 0,
        padding2 = 0,
    )

fn init_multi_sample_state(
    sample_count: SDL_GPUSampleCount = SDL_GPUSampleCount(0),
    sample_mask: UInt32 = 0,
    enable_mask: Bool = False,
    enable_alpha_to_coverage: Bool = False,
) -> SDL_GPUMultisampleState:
    return SDL_GPUMultisampleState(
        sample_count = sample_count,
        sample_mask = sample_mask,
        enable_mask = enable_mask,
        padding1 = UInt8(enable_alpha_to_coverage).cast[DType.uint8](),
        padding2 = 0,
        padding3 = 0,
    )


fn init_stencil_op_state(
    fail_op: SDL_GPUStencilOp = SDL_GPUStencilOp(0),
    pass_op: SDL_GPUStencilOp = SDL_GPUStencilOp(0),
    depth_fail_op: SDL_GPUStencilOp = SDL_GPUStencilOp(0),
    compare_op: SDL_GPUCompareOp = SDL_GPUCompareOp(0),
) -> SDL_GPUStencilOpState:
    return SDL_GPUStencilOpState(
        fail_op = fail_op,
        pass_op = pass_op,
        depth_fail_op = depth_fail_op,
        compare_op = compare_op,
    )

fn init_depth_stencil_state(
    compare_op: SDL_GPUCompareOp = SDL_GPUCompareOp(0),
    back_stencil_state: SDL_GPUStencilOpState = init_stencil_op_state(),
    front_stencil_state: SDL_GPUStencilOpState = init_stencil_op_state(),
    compare_mask: UInt8 = 0,
    write_mask: UInt8 = 0,
    enable_depth_test: Bool = False,
    enable_depth_write: Bool = False,
    enable_stencil_test: Bool = False,
) -> SDL_GPUDepthStencilState:
    return SDL_GPUDepthStencilState(
        compare_op = compare_op,
        back_stencil_state = back_stencil_state,
        front_stencil_state = front_stencil_state,
        compare_mask = compare_mask,
        write_mask = write_mask,
        enable_depth_test = enable_depth_test,
        enable_depth_write = enable_depth_write,
        enable_stencil_test = enable_stencil_test,
        padding1 = 0,
        padding2 = 0,
        padding3 = 0,
    )

fn init_graphics_pipeline_target_info(
    color_target_descriptions: List[SDL_GPUColorTargetDescription],
    depth_stencil_format: SDL_GPUTextureFormat = SDL_GPUTextureFormat(0),
    has_depth_stencil_target: Bool = False,
) -> SDL_GPUGraphicsPipelineTargetInfo:
    return SDL_GPUGraphicsPipelineTargetInfo(
        color_target_descriptions = color_target_descriptions.data,
        num_color_targets = UInt32(len(color_target_descriptions)),
        depth_stencil_format = depth_stencil_format,
        has_depth_stencil_target = has_depth_stencil_target,
        padding1 = 0,
        padding2 = 0,
        padding3 = 0,
    )