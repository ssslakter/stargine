from sdl import Ptr
from sdl.gpu import *


struct GPUDevice:
    var device: Ptr[SDL_GPUDevice]

    fn __init__(
        out self,
        format_flags: SDL_GPUShaderFormat,
        debug_mode: Bool,
        name: String,
    ) raises:
        self.device = sdl_create_gpu_device(format_flags, debug_mode, name)

    fn __moveinit__(out self, owned other: Self):
        self.device = other.device

    fn __del__(owned self):
        sdl_destroy_gpu_device(self.device)


struct CommandBuffer:
    var buf: Ptr[SDL_GPUCommandBuffer]
    var _submitted: Bool

    fn __init__(out self, device: GPUDevice) raises:
        self.buf = sdl_acquire_gpu_command_buffer(device.device)
        self._submitted = False

    fn __moveinit__(out self, owned other: Self):
        self.buf = other.buf
        self._submitted = other._submitted

    @staticmethod
    fn acquire(device: GPUDevice) raises -> Self:
        var cmd = Self(device)
        return cmd^

    fn __del__(owned self):
        if not self._submitted:
            print(
                "Warning: Command buffer not submitted before destruction,"
                " leaking resources"
            )

    fn submit(owned self) raises:
        sdl_submit_gpu_command_buffer(self.buf)
        self._submitted = True

    fn wait_and_acquire_gpu_swapchain_texture(
        self: Self, window: Window
    ) raises -> Optional[GPUTexture]:
        var width: UInt32 = 0
        var height: UInt32 = 0
        var texture_data = Ptr[SDL_GPUTexture, mut=True]()

        sdl_wait_and_acquire_gpu_swapchain_texture(
            self.buf,
            window.window,
            Ptr(to=texture_data),
            Ptr(to=width),
            Ptr(to=height),
        )

        if width == 0 or height == 0:
            return None

        return GPUTexture(texture_data, width, height)


struct GPUTexture(Copyable, Movable):
    var texture: Ptr[SDL_GPUTexture]
    var width: UInt32
    var height: UInt32

    fn __init__(
        out self, texture: Ptr[SDL_GPUTexture], width: UInt32, height: UInt32
    ) raises:
        self.texture = texture
        self.width = width
        self.height = height

    fn __moveinit__(out self, owned other: Self):
        self.texture = other.texture
        self.width = other.width
        self.height = other.height

    fn __copyinit__(out self, other: Self):
        self.texture = other.texture
        self.width = other.width
        self.height = other.height


struct GPUColorTargetInfo:
    var _info: SDL_GPUColorTargetInfo

    def __init__(
        out self,
        mut texture: GPUTexture,
        clear_color: SDL_FColor,
        load_op: SDL_GPULoadOp,
        store_op: SDL_GPUStoreOp,
        resolve_texture: Optional[Ptr[SDL_GPUTexture, mut=True]] = None,
        mip_level: UInt32 = 0,
        layer_or_depth_plane: UInt32 = 0,
        resolve_mip_level: UInt32 = 0,
        resolve_layer: UInt32 = 0,
        cycle: Bool = False,
        cycle_resolve_texture: Bool = False,
        padding1: UInt8 = 0,
        padding2: UInt8 = 0,
    ):
        if not resolve_texture:
            resolve_texture = Ptr[SDL_GPUTexture]()

        self._info = SDL_GPUColorTargetInfo(
            texture=texture.texture,
            clear_color=clear_color,
            load_op=load_op,
            store_op=store_op,
            mip_level=mip_level,
            layer_or_depth_plane=layer_or_depth_plane,
            resolve_mip_level=resolve_mip_level,
            resolve_texture=resolve_texture.value(),
            resolve_layer=resolve_layer,
            cycle=cycle,
            cycle_resolve_texture=cycle_resolve_texture,
            padding1=padding1,
            padding2=padding2,
        )


struct GPURenderPass:
    var _render_pass: Ptr[SDL_GPURenderPass]

    fn __init__(out self, render_pass: Ptr[SDL_GPURenderPass]):
        self._render_pass = render_pass

    @staticmethod
    fn begin(
        command_buffer: CommandBuffer,
        color_target_info: GPUColorTargetInfo,
        num_color_targets: UInt32,
        depth_stencil_target_info: Optional[
            SDL_GPUDepthStencilTargetInfo
        ] = None,
    ) -> Self:
        depth_stencil_target_info_ptr = Ptr(
            to=depth_stencil_target_info.value()
        ) if depth_stencil_target_info else Ptr[SDL_GPUDepthStencilTargetInfo]()

        var render_pass = sdl_begin_gpu_render_pass(
            command_buffer.buf,
            Ptr(to=color_target_info._info),
            num_color_targets,
            depth_stencil_target_info_ptr,
        )
        return GPURenderPass(render_pass)

    fn end(self: Self):
        sdl_end_gpu_render_pass(self._render_pass)
