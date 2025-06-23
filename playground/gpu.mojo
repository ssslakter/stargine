from sdl import Ptr
from sdl import sdl_gpu as gpu


struct GPUDevice:
    var device: Ptr[gpu.GPUDevice]

    fn __init__(
        out self,
        format_flags: gpu.GPUShaderFormat,
        debug_mode: Bool,
        name: String,
    ) raises:
        self.device = gpu.create_gpu_device(format_flags, debug_mode, name)

    fn __moveinit__(out self, owned other: Self):
        self.device = other.device

    fn __del__(owned self):
        print("releasing gpu device")
        gpu.destroy_gpu_device(self.device)


struct CommandBuffer:
    var buf: Ptr[gpu.GPUCommandBuffer]
    var _submitted: Bool

    fn __init__(out self, device: GPUDevice) raises:
        self.buf = gpu.acquire_gpu_command_buffer(device.device)
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
        gpu.submit_gpu_command_buffer(self.buf)
        self._submitted = True

    fn wait_and_acquire_gpu_swapchain_texture(
        self: Self, window: Window
    ) raises -> Optional[GPUTexture]:
        var width: UInt32 = 0
        var height: UInt32 = 0
        var texture_data = Ptr[gpu.GPUTexture, mut=True]()

        gpu.wait_and_acquire_gpu_swapchain_texture(
            self.buf,
            window._handle,
            Ptr(to=texture_data),
            Ptr(to=width),
            Ptr(to=height),
        )

        if width == 0 or height == 0:
            return None

        return GPUTexture(texture_data, width, height)

    fn begin_gpu_copy_pass(self: Self, out copy_pass: Ptr[gpu.GPUCopyPass]):
        copy_pass = gpu.begin_gpu_copy_pass(self.buf)


struct GPUTexture(Copyable, Movable):
    var texture: Ptr[gpu.GPUTexture]
    var width: UInt32
    var height: UInt32

    fn __init__(
        out self, texture: Ptr[gpu.GPUTexture], width: UInt32, height: UInt32
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
    var _info: gpu.GPUColorTargetInfo

    def __init__(
        out self,
        mut texture: GPUTexture,
        clear_color: gpu.FColor,
        load_op: gpu.GPULoadOp,
        store_op: gpu.GPUStoreOp,
        resolve_texture: Optional[Ptr[gpu.GPUTexture, mut=True]] = None,
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
            resolve_texture_ptr = Ptr[gpu.GPUTexture]()
        else:
            resolve_texture_ptr = resolve_texture.value()

        self._info = gpu.GPUColorTargetInfo(
            texture=texture.texture,
            clear_color=clear_color,
            load_op=load_op,
            store_op=store_op,
            mip_level=mip_level,
            layer_or_depth_plane=layer_or_depth_plane,
            resolve_mip_level=resolve_mip_level,
            resolve_texture=resolve_texture_ptr,
            resolve_layer=resolve_layer,
            cycle=cycle,
            cycle_resolve_texture=cycle_resolve_texture,
            padding1=padding1,
            padding2=padding2,
        )


struct GPURenderPass:
    var _render_pass: Ptr[gpu.GPURenderPass]

    fn __init__(out self, render_pass: Ptr[gpu.GPURenderPass]):
        self._render_pass = render_pass

    @staticmethod
    fn begin(
        command_buffer: CommandBuffer,
        color_target_info: GPUColorTargetInfo,
        num_color_targets: UInt32,
        depth_stencil_target_info: Optional[
            gpu.GPUDepthStencilTargetInfo
        ] = None,
    ) -> Self:
        depth_stencil_target_info_ptr = Ptr(
            to=depth_stencil_target_info.value()
        ) if depth_stencil_target_info else Ptr[gpu.GPUDepthStencilTargetInfo]()

        var render_pass = gpu.begin_gpu_render_pass(
            command_buffer.buf,
            Ptr(to=color_target_info._info),
            num_color_targets,
            depth_stencil_target_info_ptr,
        )
        return GPURenderPass(render_pass)

    fn end(self: Self):
        gpu.end_gpu_render_pass(self._render_pass)

struct GPUCopyPass:
    var _pass: Ptr[gpu.GPUCopyPass]

    fn __init__(out self, command_buffer: CommandBuffer):
        self._pass = gpu.begin_gpu_copy_pass(command_buffer.buf)

    fn upload(self: Self, buffer: GPUTransferBufferLocation, src: GPUBufferRegion, cycle: Bool = False):
        gpu.upload_to_gpu_buffer(self._pass, buffer._location, src._region, cycle)

    fn end(self: Self):
        gpu.end_gpu_copy_pass(self._pass)


struct GPUBufferRegion:
    var _region: Ptr[gpu.GPUBufferRegion]
    fn __init__(out self, buffer: GPUBuffer, offset: UInt32, size: UInt32):
        self._region = Ptr(to=gpu.GPUBufferRegion(buffer._handle, offset, size))

struct GPUBuffer:
    var _device_ptr: Ptr[gpu.GPUDevice]
    var _handle: Ptr[gpu.GPUBuffer]

    fn __init__(out self,
        device: GPUDevice,
        usage: gpu.GPUBufferUsageFlags,
        size: UInt32,
        props: gpu.PropertiesID = gpu.PropertiesID(0),
    ) raises:
        info = gpu.GPUBufferCreateInfo(usage, size, props)
        self._device_ptr = device.device
        self._handle = gpu.create_gpu_buffer(device.device, Ptr(to=info))

    fn __moveinit__(out self, owned other: Self):
        self._device_ptr = other._device_ptr
        self._handle = other._handle

    fn __del__(owned self):
        print("releasing gpu buffer")
        gpu.release_gpu_buffer(self._device_ptr, self._handle)


struct GPUTransferBufferLocation:
    var _location: Ptr[gpu.GPUTransferBufferLocation]
    fn __init__(out self, buffer: GPUTransferBuffer, offset: UInt32):
        self._location = Ptr(to=gpu.GPUTransferBufferLocation(buffer._handle, offset))

struct GPUTransferBuffer:
    var _device_ptr: Ptr[gpu.GPUDevice]
    var _handle: Ptr[gpu.GPUTransferBuffer]

    fn __init__(out self, 
    device: GPUDevice, 
    usage: gpu.GPUTransferBufferUsage,
    size: UInt32,
    props: gpu.PropertiesID = gpu.PropertiesID(0),
    ) raises:
        info = gpu.GPUTransferBufferCreateInfo(usage, size, props)
        self._device_ptr = device.device
        self._handle = gpu.create_gpu_transfer_buffer(device.device, Ptr(to=info))

    fn map_gpu_transfer_buffer[T: AnyType](self: Self, cycle: Bool = False) -> Ptr[T]:
        return gpu.map_gpu_transfer_buffer(self._device_ptr, self._handle, cycle).bitcast[T]()


    fn unmap_gpu_transfer_buffer(self: Self):
        gpu.unmap_gpu_transfer_buffer(self._device_ptr, self._handle)

    fn __del__(owned self):
        print("releasing transfer buffer")
        gpu.release_gpu_transfer_buffer(self._device_ptr, self._handle)