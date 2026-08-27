#version 450 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_TexCoord;
layout (location = 2) in vec3 a_Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 normalMatrix;

out vec3 Normal;
out vec3 FragPos;
out vec2 TexCoords;

void main()
{
    gl_Position = projection * view * model * vec4(a_Position, 1.0);
    FragPos = vec3(model * vec4(a_Position, 1.0));
    Normal = mat3(normalMatrix) * a_Normal;
    TexCoords = a_TexCoord;
}
