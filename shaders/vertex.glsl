#version 330 core

layout (location = 0) in vec4 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aTexCoord;

out vec4 vColor;
uniform vec4 myColor;
out vec2 vTexCoord;

void main()
{
    gl_Position = vec4(aPosition, 1.0);
    vColor = aColor;
    vTexCoord = aTexCoord;
}