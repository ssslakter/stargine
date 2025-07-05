#version 330 core

in vec4 vColor;
in vec2 vTexCoord;
uniform sampler2D texture1;
out vec4 FragColor;

void main()
{
    FragColor = texture(texture1, vTexCoord) + vColor;
}