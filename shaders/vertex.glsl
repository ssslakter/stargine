#version 330 core

layout (location = 0) in vec4 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aTexCoord;

out vec4 vColor;
uniform vec4 myColor;
out vec2 vTexCoord;
out vec4 vPosition;

void main()
{
    gl_Position = vec4(aPosition.x, aPosition.y, 0.0, 1.0);
    vPosition = aPosition;
    vColor = aColor;
    vTexCoord = aTexCoord;
}