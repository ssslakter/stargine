#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aTexCoord;

out vec4 vColor;
uniform vec4 myColor;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
out vec2 vTexCoord;

void main()
{
    // vec4 position = vec4(aPosition.xy, 0.0, 1.0);
    gl_Position = projection * view * model * vec4(aPosition, 1.0);
    vColor = aColor;
    vTexCoord = aTexCoord;
}