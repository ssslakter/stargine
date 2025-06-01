from sdl import *
from wrappers import *
import time

alias Uint = UInt32
alias Int = Int32


@value
struct Context:
    var window: Ptr[SDL_Window]
    var device: Ptr[SDL_GPUDevice]
    var window_title: String
    var windows_size: (Int, Int)

    fn __init__(
        out self,
        windows_size: (Int, Int),
        window_title: String,
        window_flags: SDL_WindowFlags,
    ) raises:
        self.windows_size = windows_size
        self.window_title = window_title
        self.device = sdl_create_gpu_device(
            SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV,
            True,
            "vulkan",
        )
        if not self.device:
            print("Failed to create GPU device")
            raise Error("Failed to create GPU device")
        print(window_flags.value, "window_flags")
        self.window = sdl_create_window(
            self.window_title,
            self.windows_size[0],
            self.windows_size[1],
            window_flags,
        )

    fn __enter__(mut self) -> Self:
        return self

    fn __exit__(mut self):
        print("Exiting context")
        sdl_release_window_from_gpu_device(self.device, self.window)
        sdl_destroy_gpu_device(self.device)
        sdl_destroy_window(self.window)


def create_texture(dev_ptr: Ptr[SDL_GPUDevice]) -> Ptr[SDL_GPUTexture]:
    var info = SDL_GPUTextureCreateInfo(
        type=SDL_GPUTextureType(SDL_GPUTextureType.SDL_GPU_TEXTURETYPE_2D),
        format=SDL_GPUTextureFormat(
            SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM
        ),
        usage=SDL_GPUTextureUsageFlags.SDL_GPU_TEXTUREUSAGE_COLOR_TARGET,
        width=800,
        height=600,
        layer_count_or_depth=1,
        num_levels=1,
        sample_count=SDL_GPUSampleCount(
            SDL_GPUSampleCount.SDL_GPU_SAMPLECOUNT_1
        ),
        props=sdl_get_global_properties(),
    )
    var texture = sdl_create_gpu_texture(dev_ptr, Ptr(to=info))
    if not texture:
        print("Failed to create texture")
    return texture


def main():
    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)

    with Context(
        windows_size=(Int(800), Int(600)),
        window_title="Test Window",
        window_flags=SDL_WindowFlags.SDL_WINDOW_RESIZABLE,
    ) as context:
        print("Hello, World!")
        print(sdl_get_window_flags(context.window).value)

        sdl_claim_window_for_gpu_device(context.device, context.window)
        var cmd_buffer = sdl_acquire_gpu_command_buffer(context.device)
        gpu_texture, width, height = acquire_swapchain_texture(cmd_buffer, context.window)
        print(width, "width")
        print(height, "height")
        if gpu_texture:
            var color_target_info = SDL_GPUColorTargetInfo(
                texture=gpu_texture,
                clear_color=SDL_FColor(r=0.3, g=0.4, b=0.5, a=1.0),
                load_op=SDL_GPULoadOp(SDL_GPULoadOp.SDL_GPU_LOADOP_CLEAR),
                store_op=SDL_GPUStoreOp(SDL_GPUStoreOp.SDL_GPU_STOREOP_STORE),
                resolve_mip_level=0,
                mip_level=0,
                layer_or_depth_plane=0,
                resolve_texture=Ptr[SDL_GPUTexture](),
                resolve_layer=0,
                cycle=False,
                cycle_resolve_texture=False,
                padding1=0,
                padding2=0,
            )

            var render_pass = sdl_begin_gpu_render_pass(cmd_buffer, Ptr(to=color_target_info), 1, Ptr[SDL_GPUDepthStencilTargetInfo]())
            sdl_end_gpu_render_pass(render_pass)
            
        sdl_submit_gpu_command_buffer(cmd_buffer)
        time.sleep(5.0)


    sdl_quit()
    # var texture = create_texture(Ptr(to=context.device))
    # if not texture:
    #     print("Failed to create texture")
    #     raise Error("Failed to create texture")
