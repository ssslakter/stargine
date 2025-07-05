#version 330 core

in vec4 vColor;
in vec2 vTexCoord;
in vec4 vPosition;
uniform sampler2D texture1;
out vec4 FragColor;

void main()
{
    FragColor = vPosition;
    // FragColor = texture(texture1, vTexCoord);
}