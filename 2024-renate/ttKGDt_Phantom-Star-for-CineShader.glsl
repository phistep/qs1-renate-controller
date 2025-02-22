// https://www.shadertoy.com/view/ttKGDt

// id: ttKGDt
// date: 1580219576
// viewed: 313892
// name: Phantom Star for CineShader
// username: kasari39
// description: https://cineshader.com/view/ttKGDt
// likes: 500
// published: 3
// flags: 0
// usePreview: 1
// tags: ['raymarching', 'ifs', 'phantommode']
// hasliked: 0

#define iResolution vec3(u_Resolution, 0.0)
#define iTime u_Time
#define iTimeDelta 0.0
#define iFrameRate 60.0
#define iFrame (60.0 * u_Time)
#define iChannelTime float[](u_Time, u_Time, u_Time, u_Time)
#define iChannelResolution float[](vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0))
#define iMouse vec4(0.0)
// uniform samplerXX iChannel0..3; // input channel. XX = 2D/Cube
#define iDate vec4(1970.0, 1.0, 1.0, 0.0)
#define iSampleRate 44100.0

precision highp float;

uniform float camera_rot_speed; // =1. [0.,6.] #102
uniform float camera_pos_speed; // =3. [0.,25.] #103

uniform vec3 box_color; // <color> =(0.01,0.011,0.012) [0.,0.25,0.01]
uniform vec3 box_dim; // =(0.4,0.8,0.3)
uniform float box_rot_xy; // =0.3
uniform float box_rot_xz; // =0.1
uniform vec3 box_offset; // =(5.,5.,16.) [0.,20.] #106

uniform vec3 flash_color; // <color> =(0.,.002,.005) [0.,.01,.001] #107
uniform float flash_intensity; // =3. [0.,10.] #108
uniform float flash_speed; // =24. [0.,50.] #109

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

const float pi = acos(-1.0);
const float pi2 = pi * 2.0;

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + pi / r;
    float n = pi2 / r;
    a = floor(a / n) * n;
    return p * rot(-a);
}

float box(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float ifsBox(vec3 p) {
    for (int i = 0; i < 5; i++) {
        p = abs(p) - 1.0;
        p.xy *= rot(iTime * box_rot_xy);
        p.xz *= rot(iTime * box_rot_xz);
    }
    p.xz *= rot(iTime);
    return box(p, box_dim);
}

float map(vec3 p, vec3 cPos) {
    vec3 p1 = p;
    p1 = mod(p1 - box_offset / 2., box_offset) - box_offset / 2.;
    p1.xy = pmod(p1.xy, 5.0);
    return ifsBox(p1);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

    vec3 cPos = vec3(0.0, 0.0, -camera_pos_speed * iTime);
    // vec3 cPos = vec3(0.3*sin(iTime*0.8), 0.4*cos(iTime*0.3), -6.0 * iTime);
    vec3 cDir = normalize(vec3(0.0, 0.0, -1.0));
    vec3 cUp = vec3(sin(iTime) * camera_rot_speed, 1.0, 0.0);
    vec3 cSide = cross(cDir, cUp);

    vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir);

    // Phantom Mode https://www.shadertoy.com/view/MtScWW by aiekick
    float acc = 0.0;
    float acc2 = 0.0;
    float t = 0.0;
    for (int i = 0; i < 99; i++) {
        vec3 pos = cPos + ray * t;
        float dist = map(pos, cPos);
        dist = max(abs(dist), 0.02);
        float a = exp(-dist * flash_intensity);
        if (mod(length(pos) + flash_speed * iTime, 30.0) < 3.0) {
            a *= 2.0;
            acc2 += a;
        }
        acc += a;
        t += dist * 0.5;
    }

    vec3 col = acc * box_color;
    col += acc2 * flash_color;
    fragColor = vec4(col, 1.0 - t * 0.03);
}

void main() {
    vec4 frag_color;
    mainImage(frag_color, gl_FragCoord.xy);
    FragColor = frag_color;
}
