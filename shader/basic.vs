#version 330 core

in vec3 vertexPosition;     // Vertex input attribute: position
in vec2 vertexTexCoord;     // Vertex input attribute: texture coordinate
in vec4 vertexColor;        // Vertex input attribute: color

out vec2 fragTexCoord;      // To-fragment attribute: texture coordinate
out vec4 fragColor;         // To-fragment attribute: color

uniform mat4 mvp;

void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}