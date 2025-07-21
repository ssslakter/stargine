#shader vertex

#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_TexCoord;

out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main()
{
    gl_Position = projection * view * model * vec4(a_Position, 1.0);
    TexCoord = a_TexCoord;
}

#shader fragment

#version 330 core

uniform sampler2D texture;
in vec2 TexCoord;
out vec4 FragColor;

void main()
{
    FragColor = texture(texture, TexCoord);
}
