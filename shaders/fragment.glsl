#version 330 core

in vec4 vColor;
in vec2 vTexCoord;
uniform sampler2D texture1;
uniform sampler2D texture2;
out vec4 FragColor;

void main()
{
    FragColor = mix(texture(texture1, vTexCoord), texture(texture2, vTexCoord), 0.6);
}