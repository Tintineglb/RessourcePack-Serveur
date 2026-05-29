#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <kello:kello_util.glsl>
#define resolution 2048.

// Dégradé jaune pâle
#define grad0 vec3(1.000 , 0.753 , 0.000)
#define grad1 vec3(1.000 , 0.796 , 0.180)
#define grad2 vec3(1.000 , 0.929 , 0.722)

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

uniform vec2 ScreenSize;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

in float isTitle;
in float isCrosshairTitleBg;

in vec2 uv;
in vec2 pos;

out vec4 fragColor;



// SDF triangle YouTube (pointant à droite)
float sdTriangleYT(vec2 p) {
    vec2 v0 = vec2(0.6, 0.0);
    vec2 v1 = vec2(-0.4, 0.5);
    vec2 v2 = vec2(-0.4, -0.5);

    vec2 e0 = v1 - v0, e1 = v2 - v1, e2 = v0 - v2;
    vec2 v  = p  - v0, w  = p  - v1, u  = p  - v2;
    vec2 pq0 = v - e0*clamp(dot(v,e0)/dot(e0,e0),0.0,1.0);
    vec2 pq1 = w - e1*clamp(dot(w,e1)/dot(e1,e1),0.0,1.0);
    vec2 pq2 = u - e2*clamp(dot(u,e2)/dot(e2,e2),0.0,1.0);
    float s = sign(e0.x*e2.y - e0.y*e2.x);
    vec2 d = min(min(
        vec2(dot(pq0,pq0), s*(v.x*e0.y-v.y*e0.x)),
        vec2(dot(pq1,pq1), s*(w.x*e1.y-w.y*e1.x))),
        vec2(dot(pq2,pq2), s*(u.x*e2.y-u.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}



vec4 doWipeTriangle(float time, float rotSpeed) {
    vec2 transformedUV = ((uv/5.*ScreenSize)/ScreenSize.y);
    float accumulated_alpha = 0.0;
    float aspectScale = (ScreenSize.y > ScreenSize.x) ? ScreenSize.y/ScreenSize.x : ScreenSize.x/ScreenSize.y * 1.325;

    float colFactor = 0.0;
    float originTime = time;

    if(time > .5) {
        time -= 0.485;
        colFactor = 1.;
    }
    time *= 0.5;

    // Rotation qui suit la progression (grossit ET tourne)
    float angle = (cos(1.25 + time * 4.75)) * rotSpeed * 0.5;

    vec2 coord = scale2d(vec2(0.125/(1.0-cos(time*clamp(0.,5.,ScreenSize.x/ScreenSize.y))))/aspectScale)
                 * floor(transformedUV*resolution)/resolution
                 * rotate2d(angle);

    float tri = sdTriangleYT(coord);
    accumulated_alpha += 1. - step(0.05, tri);

    return vec4(mix(grad1, mix(grad2, grad0, uv.y/4.+originTime*3.-1.), uv.y/2.+originTime*3.-1.), abs(colFactor-step(1.,accumulated_alpha)));
}



void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;

    if (isTitle == 1.) {
        color = (compareColor(vertexColor.rgb, vec3(1, 25, 21))) == 1. ? vec4(doWipeTriangle(color.a,2.5)) : color;
        color = (compareColor(vertexColor.rgb, vec3(2, 25, 21))) == 1. ? vec4(doWipeTriangle(color.a,0.85)) : color;
        color = (compareColor(vertexColor.rgb, vec3(25, 25, 21))) == 1. ? texture(Sampler0, texCoord0) * ColorModulator : color;
    }
    if (isCrosshairTitleBg == 1.) {
        discard;
    }

    if (color.a < 0.003921568627451) discard;

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
