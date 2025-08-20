#shader vertex

#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec3 a_Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 normalMatrix;

out vec3 Normal;
out vec3 FragPos;
void main()
{
    gl_Position = projection * view * model * vec4(a_Position, 1.0);
    FragPos = vec3(model * vec4(a_Position, 1.0));
    Normal = mat3(normalMatrix) * a_Normal;
}

#shader fragment

#version 330 core

struct Material { 
    vec3 ambient; 
    vec3 diffuse;
    vec3 specular;
    float shininess;
    };

uniform Material material;

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    }; 

uniform Light light;

uniform vec3 cameraPos;

out vec4 FragColor;
in vec3 Normal;
in vec3 FragPos;

void main()
{
    // ambient
    vec3 amb = material.ambient*light.ambient;
    // diffuse
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(light.position - FragPos);
    float diff = max(dot(norm, lightDir), 0.0); 
    vec3 diffuse = light.diffuse * (diff * material.diffuse);
    // specular
    vec3 viewDir = normalize(cameraPos - FragPos); 
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess); 
    vec3 specular = light.specular * (spec * material.specular);

    FragColor = vec4(amb + diffuse + specular, 1.0);
}
