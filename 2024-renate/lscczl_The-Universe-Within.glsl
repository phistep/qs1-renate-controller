// https://www.shadertoy.com/view/lscczl

// id: lscczl
// date: 1529463361
// viewed: 133568
// name: The Universe Within
// username: BigWIngs
// description: Been reading up on psychedelics and got inspired. Put fullscreen, make sure sure you have sound and stare at it until the end! Use mouse to move.
// likes: 723
// published: 3
// flags: 64
// usePreview: 1
// tags: ['psychedelic', 'universe', 'brain', 'trip', 'flythrough', 'neurons', 'network', 'blockchain', 'consciousness', 'spiritual', 'mystic', 'multiverse']
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

// The Universe Within - by Martijn Steinrucken aka BigWings 2018
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// After listening to an interview with Michael Pollan on the Joe Rogan
// podcast I got interested in mystic experiences that people seem to
// have when using certain psycoactive substances.
//
// For best results, watch fullscreen, with music, in a dark room.
//
// I had an unused 'blockchain effect' lying around and used it as
// a base for this effect. Uncomment the SIMPLE define to see where
// this came from.
//
// Use the mouse to get some 3d parallax.

// Music - Terrence McKenna Mashup - Jason Burruss Remixes
// https://soundcloud.com/jason-burruss-remixes/terrence-mckenna-mashup
//
// YouTube video of this effect:
// https://youtu.be/GAhu4ngQa48
//
// YouTube Tutorial for this effect:
// https://youtu.be/3CycKKJiwis

#define S(a, b, t) smoothstep(a, b, t)

// TODO no full black

bool simple = false; // =False
uniform float glow; // =0.5 [0.,1.]
float fft = glow; //u_Microphone[2];
uniform float speed; // =0.1 [0.,2.]

uniform bool color_auto; // =True
uniform vec3 color; // <color> =(1.,1.,1.)

uniform float layer_count; // =4. [1.,10.] #102
uniform float layer_size_min; // =1. [1.,50.]
uniform float layer_size_max; // =15. [1.,50.] #103
uniform float layer_fade_min; // =0. [0.,1.]
uniform float layer_fade_max; // =0.6 [0.,1.]

uniform float displacement; // =.4 [0.,1.] #108

uniform float line_fade_min; // =0.5 [0.,5.]
uniform float line_fade_max; // =1.5 [0.,5.]
uniform float line_r1; // =0.04 [0.,.1]
uniform float line_r2; // =0.01 [0.,.1] #106

uniform float sparkle_intensity; // =.005 [0.,0.1,.001] #109
uniform float sparkle_damping; // =20. [0., 100.]
uniform float sparkle_pulse_amp; // =.4 [0.,1.]
uniform float sparkle_pulse_freq; // =.5 [0.,25.] #107

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}

vec2 GetPos(vec2 id, vec2 offs, float t) {
    float n = N21(id + offs);
    float n1 = fract(n * 10.);
    float n2 = fract(n * 100.);
    float a = t + n;
    return offs + vec2(sin(a * n1), cos(a * n2)) * displacement;
}

float GetT(vec2 ro, vec2 rd, vec2 p) {
    return dot(p - ro, rd);
}

float LineDist(vec3 a, vec3 b, vec3 p) {
    return length(cross(b - a, p - a)) / length(p - a);
}

float df_line(in vec2 a, in vec2 b, in vec2 p)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa - ba * h);
}

float line(vec2 a, vec2 b, vec2 uv) {
    float r1 = line_r1;
    float r2 = line_r2;

    float d = df_line(a, b, uv);
    float d2 = length(a - b);
    float fade = S(line_fade_max, line_fade_min, d2);

    fade += S(.05, .02, abs(d2 - .75));
    return S(r1, r2, d) * fade;
}

float NetLayer(vec2 st, float n, float t) {
    vec2 id = floor(st) + n;

    st = fract(st) - .5;

    vec2 p[9];
    int i = 0;
    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            p[i++] = GetPos(id, vec2(x, y), t);
        }
    }

    float m = 0.;
    float sparkle = 0.;

    for (int i = 0; i < 9; i++) {
        m += line(p[4], p[i], st);

        float d = length(st - p[i]);

        float s = (sparkle_intensity / (d * d));
        s *= S(1., .7, d);
        float pulse = sin((fract(p[i].x) + fract(p[i].y) + t) * sparkle_pulse_freq) * sparkle_pulse_amp + (1. - sparkle_pulse_amp);
        pulse = pow(pulse, sparkle_damping);

        s *= pulse;
        sparkle += s;
    }

    m += line(p[1], p[3], st);
    m += line(p[1], p[5], st);
    m += line(p[7], p[5], st);
    m += line(p[7], p[3], st);

    float sPhase = (sin(t + n) + sin(t * .1)) * .25 + .5;
    sPhase += pow(sin(t * .1) * .5 + .5, 50.) * 5.;
    m += sparkle * sPhase; //(*.5+.5);

    return m;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    vec2 M = iMouse.xy / iResolution.xy - .5;

    float t = iTime * speed;

    float s = sin(t);
    float c = cos(t);
    mat2 rot = mat2(c, -s, s, c);
    vec2 st = uv * rot;
    M *= rot * 2.;

    float m = 0.;
    for (float i = 0.; i < 1.; i += 1. / layer_count) {
        float z = fract(t + i);
        float size = mix(layer_size_max, layer_size_min, z);
        float fade = S(layer_fade_min, layer_fade_max, z) * S(1., .8, z);

        m += fade * NetLayer(st * size - M * z, i, iTime);
    }

    float glow = -uv.y * fft * 2.;

    vec3 baseCol = color;
    if (color_auto) {
        baseCol = vec3(s, cos(t * .4), -sin(t * .24)) * .4 + .6;
    }
    vec3 col = baseCol * m;
    col += baseCol * glow;

    if (simple) {
        uv *= 10.;
        col = vec3(1) * NetLayer(uv, 0., iTime);
        uv = fract(uv);
        //if(uv.x>.98 || uv.y>.98) col += 1.;
    } else {
        col *= 1. - dot(uv, uv);
        t = mod(iTime, 30.);
        col *= S(0., 20., t) * S(224., 200., t);
    }

    fragColor = vec4(col, 1);
}

void main() {
    vec4 frag_color;
    mainImage(frag_color, gl_FragCoord.xy);
    FragColor = frag_color;
}
