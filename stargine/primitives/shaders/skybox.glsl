#shader vertex

#version 450 core

layout (location = 0) in vec3 a_Position;

uniform mat4 view;
uniform mat4 projection;

out vec3 Direction;

void main()
{
    Direction = a_Position;
    vec4 position = projection * view * vec4(a_Position, 1.0);
    // Force z == w so the skybox always lands on the far plane.
    gl_Position = position.xyww;
}

#shader fragment

#version 450 core

uniform samplerCube skybox;

in vec3 Direction;
out vec4 FragColor;

void main()
{
    FragColor = texture(skybox, Direction);
}
