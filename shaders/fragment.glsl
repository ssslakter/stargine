#version 330 core

in vec4 vColor;
uniform vec4 myColor;
out vec4 FragColor;

void main()
{
    FragColor = vColor*myColor;
}