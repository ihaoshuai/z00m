#version 330 core

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

out vec4 finalColor;

uniform vec2 uCenter;
uniform float uRadius;
uniform float uAspect;
uniform float uOutRadius;

void main() {
    vec4 texColor = texture(texture0, fragTexCoord);

    vec2 adjustedCoord = fragTexCoord;
    adjustedCoord.x *= uAspect;

    vec2 adjustedCenter = uCenter;
    adjustedCenter.x *= uAspect;

    float dist = distance(adjustedCoord, adjustedCenter);
    if(dist < uRadius) {
        finalColor = texColor;
    } else {
        float factor = clamp((dist-uRadius)/uOutRadius, 0.9, 1.0);
        float degree = clamp(0.9, 1.0, factor);
        finalColor = mix(texColor, vec4(0, 0, 0, 1), degree);
    }
}