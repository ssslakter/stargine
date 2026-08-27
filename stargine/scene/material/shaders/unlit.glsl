#shader vertex

#version 450 core

layout (location = 0) in vec3 a_Position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main()
{
    gl_Position = projection * view * model * vec4(a_Position, 1.0);
}

#shader fragment

#version 450 core

uniform vec4 color;
out vec4 FragColor;

void main()
{
    FragColor = color;
}
