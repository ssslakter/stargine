struct Material { 
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
    };

struct DirLight {
    bool enabled;
    vec3 direction; 
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    }; 


struct PointLight { 
    bool enabled;
    vec3 position;
    float constant;
    float linear;
    float quadratic;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};


uniform Material material;
uniform PointLight pointLight;
uniform DirLight dirLight;


uniform vec3 cameraPos;

out vec4 FragColor;
in vec2 TexCoords;
in vec3 Normal;
in vec3 FragPos;

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir);
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);


void main() {  
    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(cameraPos - FragPos);
    vec3 result = vec3(0.0);
    // phase 1: Directional lighting
    if (dirLight.enabled) {
        result += CalcDirLight(dirLight, norm, viewDir);
    }
    // phase 2: Point lights 
    if (pointLight.enabled) {
        result += CalcPointLight(pointLight, norm, FragPos, viewDir);
    }
    // phase 3: Spot light
    //result += CalcSpotLight(spotLight, norm, FragPos, viewDir);
    FragColor = vec4(result, 1.0);
}