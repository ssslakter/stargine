from playground import *

def main():
    # device = GPUDevice(SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, True, 'vulkan')
    device = sdl_create_gpu_device(SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, True, 'vulkan')
    print("Hello")
    print(device)
    # try:
    #     with open("shaders/vertex.spv", "rb") as file:
    #         code = file.read_bytes()
    # except:
    #     raise String("Error loading shader: {}").format("shaders/vertex.spv")
    # finally:
    #     sdl_destroy_gpu_device(device)

    print('test')
        
    # var info = SDL_GPUShaderCreateInfo(
    #     code_size=len(code) * sizeof[UInt8](),
    #     code=code.data,
    #     format=SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV,
    #     stage=SDL_GPUShaderStage(SDL_GPUShaderStage.SDL_GPU_SHADERSTAGE_VERTEX),
    #     entrypoint="main".unsafe_cstr_ptr(),
    #     num_samplers=0,
    #     num_storage_textures=0,
    #     num_storage_buffers=0,
    #     num_uniform_buffers=0,
    #     props=SDL_PropertiesID(0),
    # )