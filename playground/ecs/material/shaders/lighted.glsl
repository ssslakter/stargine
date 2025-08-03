#shader vertex

#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec3 a_Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 Normal;
out vec3 FragPos;
void main()
{
    gl_Position = projection * view * model * vec4(a_Position, 1.0);
    FragPos = vec3(model * vec4(a_Position, 1.0));
    Normal = a_Normal;
}

#shader fragment

#version 330 core

uniform float ambient;
uniform vec4 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;

out vec4 FragColor;
in vec3 Normal;
in vec3 FragPos;

void main()
{
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0); 
    vec3 diffuse = diff * lightColor;
    vec3 amb = ambient*lightColor;
    FragColor = vec4(amb + diffuse, 1.0)*objectColor;
}
