// https://www.shadertoy.com/view/ftt3R7

// id: ftt3R7
// date: 1635883589
// viewed: 121904
// name: Starleidoscope
// username: DanielXMoore
// description: Followed some TheArtOfCodeTutorials and ended up with this!
// likes: 201
// published: 3
// flags: 0
// usePreview: 1
// tags: ['tutorial']
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

uniform float num_layers; // =10. [1, 25] #102
uniform vec2 hue_shift; // =(0.,0.)
uniform float hue_shift_a; // =2345.2 
uniform vec3 hue_shift_b; // =(.2,.3,.9)
uniform float intensity; // =0.02 [0,0.15] #103
uniform float shine; // =1000. [10, 1000] #106
uniform float scale_a; // =20. #107
uniform float scale_b; // =.5 #108
uniform float fade_a; // =1. #109
uniform float fade_b; // =.9

uniform float angle; // =0.67

mat2 Rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float Star(vec2 uv, float flare) {
    float col = 0.;
    float d = length(uv);
    float m = intensity / d;

    float rays = max(0., 1. - abs(uv.x * uv.y * shine));
    m += rays * flare;
    uv *= Rot(3.1415 / 4.);
    rays = max(0., 1. - abs(uv.x * uv.y * 1000.));
    m += rays * .3 * flare;

    m *= smoothstep(1., .2, d);

    return m;
}

float Hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);

    return fract(p.x * p.y);
}

vec3 StarLayer(vec2 uv) {
    vec3 col = vec3(0.);

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offs = vec2(x, y);

            float n = Hash21(id + offs);
            float size = fract(n * 345.32);

            vec2 p = vec2(n, fract(n * 34.));

            float star = Star(gv - offs - p + .5, smoothstep(.8, 1., size) * .6);

            // TODO mic responsive
            vec3 hueShift = fract(n * hue_shift_a + dot(uv / 420., hue_shift)) * hue_shift_b * 123.2;

            vec3 color = sin(hueShift) * .5 + .5;
            color = color * vec3(1., .25, 1. + size);

            star *= sin(iTime * 3. + n * 6.2831) * .4 + 1.;
            col += star * size * color;
        }
    }

    return col;
}

vec2 N(float angle) {
    return vec2(sin(angle), cos(angle));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 M = (iMouse.xy - iResolution.xy * .5) / iResolution.y;
    float t = iTime * .01;

    uv.x = abs(uv.x);
    uv.y += tan((5. / 6.) * 3.1415) * .5;

    vec2 n = N((5. / 6.) * 3.1415);
    float d = dot(uv - vec2(.5, 0.), n);
    uv -= n * max(0., d) * 2.;

    // col += smoothstep(.01, .0, abs(d));

    n = N(angle * 3.1415);
    float scale = 1.;
    uv.x += 1.5 / 1.25;
    for (int i = 0; i < 5; i++) {
        scale *= 1.25;
        uv *= 1.25;
        uv.x -= 1.5;

        uv.x = abs(uv.x);
        uv.x -= 0.5;
        uv -= n * min(0., dot(uv, n)) * 2.;
    }

    uv += M * 4.;

    uv *= Rot(t);
    vec3 col = vec3(0.);

    for (float i = 0.; i < 1.; i += 1. / num_layers) {
        float depth = fract(i + t);
        float scale = mix(scale_a, scale_b, depth);
        float fade = depth * smoothstep(fade_a, fade_b, depth);
        col += StarLayer(uv * scale + i * 453.2) * fade;
    }

    fragColor = vec4(col, 1.0);
}

void main() {
    vec4 frag_color;
    mainImage(frag_color, gl_FragCoord.xy);
    FragColor = frag_color;
}
