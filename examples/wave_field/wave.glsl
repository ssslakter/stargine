#shader vertex

#version 450 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_TexCoord;
layout (location = 2) in vec3 a_Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float time;
uniform float amplitude;

out vec2 TexCoords;
out vec3 Normal;
out float Height;

float wave(vec2 p)
{
    return amplitude * (
        0.50 * sin(p.x * 1.3 + time * 1.6) +
        0.30 * sin(p.y * 0.9 - time * 1.1) +
        0.20 * sin((p.x + p.y) * 2.1 + time * 2.4));
}

void main()
{
    vec3 world = (model * vec4(a_Position, 1.0)).xyz;
    world.y += wave(world.xz);

    // Central differences give the surface normal without any extra geometry.
    float eps = 0.05;
    float dx = wave(world.xz + vec2(eps, 0.0)) - wave(world.xz - vec2(eps, 0.0));
    float dz = wave(world.xz + vec2(0.0, eps)) - wave(world.xz - vec2(0.0, eps));
    Normal = normalize(vec3(-dx, 2.0 * eps, -dz));

    Height = world.y;
    TexCoords = a_TexCoord;
    gl_Position = projection * view * vec4(world, 1.0);
}

#shader fragment

#version 450 core

uniform sampler2D surface;
uniform vec3 crest;
uniform vec3 trough;
uniform float amplitude;

in vec2 TexCoords;
in vec3 Normal;
in float Height;
out vec4 FragColor;

const vec3 LIGHT = vec3(0.36, 0.88, 0.31);

void main()
{
    float lambert = 0.25 + 0.75 * max(dot(normalize(Normal), normalize(LIGHT)), 0.0);
    float crestness = clamp(Height / max(amplitude, 0.001) * 0.7 + 0.5, 0.0, 1.0);
    // The grid texture is dark with bright lines, so its blue channel masks them.
    float lines = texture(surface, TexCoords).b;
    vec3 tint = mix(trough, crest, crestness) * lambert;
    FragColor = vec4(tint * (0.7 + 0.9 * lines), 1.0);
}
