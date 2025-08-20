#version 330 core

struct Material { 
    sampler2D diffuse;
    sampler2D specular;
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
in vec2 TexCoords;
in vec3 Normal;
in vec3 FragPos;

void main()
{
    // ambient
    vec3 amb = light.ambient * vec3(texture(material.diffuse, TexCoords));
    // diffuse
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(light.position - FragPos);
    float diff = max(dot(norm, lightDir), 0.0); 
    vec3 diffuse = light.diffuse * (diff * vec3(texture(material.diffuse, TexCoords)));
    // specular
    vec3 viewDir = normalize(cameraPos - FragPos); 
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess); 
    vec3 specular = light.specular * (spec * vec3(texture(material.specular, TexCoords)));

    FragColor = vec4(amb + diffuse + specular, 1.0);
}
