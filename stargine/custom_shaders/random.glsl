#shader vertex

#version 450 core

layout (location = 0) in vec3 a_Position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform float seed;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}


vec3 randomVec3(float seed) {
    return vec3(
        hash(seed + 1.0),
        hash(seed + 2.0),
        hash(seed + 3.0)
    );
}

vec3 randomDirection(float seed) {
    vec3 v = randomVec3(seed) * 2.0 - 1.0; // Map to [-1, 1]
    return normalize(v);
}

void main()
{
    vec3 v = randomDirection(seed+a_Position.x*4+a_Position.y*2 + a_Position.z)*0.1;
    gl_Position = projection * view * model * vec4(v+a_Position, 1.0);
}

#shader fragment

#version 450 core

uniform vec4 color;
uniform vec4 light;
out vec4 FragColor;

void main()
{
    FragColor = color*light;
}
