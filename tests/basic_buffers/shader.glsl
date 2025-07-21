#shader vertex

#version 330 core

layout (location = 0) in vec3 a_Position;


void main()
{
    gl_Position = vec4(a_Position-0.5, 1.0);
}

#shader fragment

#version 330 core

uniform vec4 color;
out vec4 FragColor;

void main()
{
    FragColor = color;
}
