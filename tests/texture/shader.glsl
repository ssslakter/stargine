#shader vertex

#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_uv;

out vec2 vTexCoord;

void main()
{
    gl_Position = vec4(a_Position-0.5, 1.0);
    vTexCoord = a_uv;
}

#shader fragment

#version 330 core

uniform sampler2D u_Texture;
in vec2 vTexCoord;

out vec4 FragColor;

void main()
{
    FragColor = texture(u_Texture, vTexCoord);
}
