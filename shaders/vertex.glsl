#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;

out vec4 vColor;
uniform vec4 myColor;

void main()
{
    gl_Position = vec4(aPosition + myColor.grg, myColor.g);
    vColor = aColor;
}