from sys.info import sizeof
from sdl.gpu import *


struct GPUShader:
    var _device_ptr: Ptr[SDL_GPUDevice]
    var _handle: Ptr[SDL_GPUShader]

    fn __init__(out self, device: GPUDevice, owned info: SDL_GPUShaderCreateInfo) raises:
        self._device_ptr = device.device
        print("code_size:", info.code_size)
        # TODO Here first 8 bytes are deleted for some reason
        for i in range(UInt(info.code_size)):
            print(info.code[i])
            if i > 10: break
        self._handle = sdl_create_gpu_shader(device.device, Ptr(to=info))

    fn __del__(owned self):
        sdl_release_gpu_shader(self._device_ptr, self._handle)



fn load_shader(
    path: String,
    device: GPUDevice,
    format: SDL_GPUShaderFormat,
    stage: SDL_GPUShaderStage,
    owned entrypoint: String = "main",
    num_samplers: UInt32 = 0,
    num_storage_textures: UInt32 = 0,
    num_storage_buffers: UInt32 = 0,
    num_uniform_buffers: UInt32 = 0,
    props: SDL_PropertiesID = SDL_PropertiesID(0),
) raises -> GPUShader:
    try:
        with open(path, "rb") as file:
            code = file.read_bytes()
    except:
        raise String("Error loading shader: {}").format(path)
    
    for i in range(len(code)):
        print(code[i])
        if i > 10: break
    
    code_size = len(code)*sizeof[UInt8]()
    print("code_size:", code_size)
    
    var info = SDL_GPUShaderCreateInfo(
        code_size=code_size,
        code=code.data,
        format=format,
        stage=stage,
        entrypoint=entrypoint.unsafe_cstr_ptr(),
        num_samplers=num_samplers,
        num_storage_textures=num_storage_textures,
        num_storage_buffers=num_storage_buffers,
        num_uniform_buffers=num_uniform_buffers,
        props=props,
    )
    for i in range(UInt(len(code) * sizeof[UInt8]())):
        print(info.code[i])
        if i > 10: break

    return GPUShader(device, info^)