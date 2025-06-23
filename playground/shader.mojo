# from sys.info import sizeof
# from sdl.gpu import *


# struct GPUShader:
#     var _device_ptr: Ptr[SDL_GPUDevice]
#     var _handle: Ptr[SDL_GPUShader]

#     fn __init__(out self, device: GPUDevice, owned info: SDL_GPUShaderCreateInfo) raises:
#         self._device_ptr = device.device
#         self._handle = sdl_create_gpu_shader(device.device, Ptr(to=info))

#     fn __del__(owned self):
#         sdl_release_gpu_shader(self._device_ptr, self._handle)



# fn load_shader(
#     path: String,
#     device: GPUDevice,
#     format: SDL_GPUShaderFormat,
#     stage: SDL_GPUShaderStage,
#     owned entrypoint: String = "main",
#     num_samplers: UInt32 = 0,
#     num_storage_textures: UInt32 = 0,
#     num_storage_buffers: UInt32 = 0,
#     num_uniform_buffers: UInt32 = 0,
#     props: SDL_PropertiesID = SDL_PropertiesID(0),
# ) raises -> GPUShader:
#     with open(path, "rb") as file:
#         code = file.read_bytes()
    
#     code_size = len(code)*sizeof[UInt8]()
    
#     var info = SDL_GPUShaderCreateInfo(
#         code_size=code_size,
#         code=code.steal_data(),
#         format=format,
#         stage=stage,
#         entrypoint=entrypoint.unsafe_cstr_ptr(),
#         num_samplers=num_samplers,
#         num_storage_textures=num_storage_textures,
#         num_storage_buffers=num_storage_buffers,
#         num_uniform_buffers=num_uniform_buffers,
#         props=props,
#     )


#     return GPUShader(device, info^)