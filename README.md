# Stargine: A Mojo Game Engine Proof of Concept

 <!-- Replace with an actual screenshot or GIF -->

Stargine is a proof-of-concept game engine written entirely in [Mojo](https://www.modular.com/mojo), using OpenGL for graphics rendering. The goal of this project is to explore Mojo's potential for high-performance game development and its interoperability with existing graphics APIs.

## Current Status

The engine is in an early experimental stage. Here's what's currently implemented:
-   ✅ Window and OpenGL context creation via SDL3 bindings.
-   ✅ Rendering of basic 3D primitives (e.g., a colored cube).
-   ✅ A basic Entity-Component-System (ECS) architecture.
-   ✅ Loading and compiling GLSL shaders.

## Getting Started

To start you need to have [Pixi](https://pixi.sh/latest/) and Git installed

### Installation and Setup

1.  **Clone the required repositories:**
    Dependencies should be located inside the repository directory.

    ```
    stargine/           <-- This repository
    ├── opengl-mojo/    <-- Dependency
    └── sdl-mojo/       <-- Dependency
    ```

    ```bash
    git clone https://github.com/ssslakter/stargine.git
    cd stargine
    git clone https://github.com/ssslakter/opengl-mojo.git
    git clone https://github.com/ssslakter/sdl-mojo.git
    ```

2.  **Build dependencies:**
    ```bash
    pixi run build-deps
    ```
    This command compiles the `sdl-mojo` and `opengl-mojo` bindings into `.mojopkg` files needed by the engine.

3.  **Run the application:**
    ```bash
    pixi run app
    ```
    *Note: The `pixi.toml` file sets `SDL_VIDEODRIVER="wayland"` by default. You may need to change this depending on the desktop environment*

## Project Structure

-   `stargine/core`: Core engine modules (event handling, GPU abstractions, math, rendering, windowing).
-   `stargine/ecs`: The Entity-Component-System
-   `stargine/primitives`: Basic geometric primitives like cubes and squares
-   `stargine/custom_shaders`: GLSL shader files

## About Mojo Kernels and OpenGL

It is theoretically possible to use Mojo kernels directly with OpenGL through certain [NVIDIA driver APIs](https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__OPENGL.html), which could unlock significant performance gains and open larger possibilities, though there is a limited support for this.

The current reliance on traditional C graphics APIs is a major limitation for writing idiomatic Mojo. With OpenGL, this results in awkward workarounds like building shaders by concatenating strings.

While migrating to a modern API like Vulkan would be a significant improvement—using pre-compiled shader bytecode instead of strings—it still operates across a C-API boundary. This prevents the deep, seamless integration that Mojo's heterogeneous compute model promises. I hope this project inspires work toward a future where Mojo can target the graphics pipeline as a first-class citizen.