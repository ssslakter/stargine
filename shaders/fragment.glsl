#version 330 core

in vec4 vColor;
in vec2 vTexCoord;
uniform sampler2D texture1;
uniform sampler2D texture2;
out vec4 FragColor;

void main()
{
    vec4 overlayTexture = texture(texture1, vTexCoord);
    vec4 baseTexture = texture(texture2, vTexCoord);
    float alpha = overlayTexture.a;
    vec3 resultColor = overlayTexture.rgb * alpha + baseTexture.rgb * (1.0 - alpha);
    FragColor = vec4(resultColor, 1.0);
}