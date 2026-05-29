#version 150

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;
out float isFlaggedModel;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(Position, FogShape);

    bool isFlagged = (Color.r > 0.9 && Color.g < 0.1 && Color.b < 0.1);
    isFlaggedModel = isFlagged ? 1.0 : 0.0;

    vec3 lightNormal = isFlagged ? vec3(0.0, 0.0, 1.0) : Normal;
    vec4 renderColor = isFlagged ? vec4(1.0) : Color;
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, lightNormal, renderColor) * texelFetch(Sampler2, UV2 / 16, 0);

    texCoord0 = UV0;
    texCoord1 = UV1;
    texCoord2 = UV2;
}
