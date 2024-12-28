/// // 1
/// uniform int max_iterations;  // =80 [1,200,1]
/// uniform bool dbg_normal;  // =False
/// uniform float rot_y_speed;  // =6.619999885559082 [-10,10]
/// uniform float rot_x_speed;  // =6.849999904632568 [-10,10]
/// uniform float qs1_width;  // =0.10000000149011612 [0,1]
/// uniform float pulse_amp;  // =0.00800000037997961 [0,0.1]
/// uniform float pulse_freq;  // =0.7400000095367432 [0,1]
/// uniform vec3 color_qs1;  // <color> =(1.0,0.351190447807312,0.0) [0.0,1.0,0.01]
/// uniform float fov;  // =-3.378000020980835 [-5.0,0.0]

/* TODO
 * fov
 * bloated ones rotation the background
 * gradient to the center
 * burning flames
 * fbm noise
 * pulsate with mic
 * midi
 *   knob 1 rotation speed
 *   knob 2 rotation x
 *   knob 3 rotation y
 *   knob 4 color 1
 *   knob 5 color 2
 *   button 1 use bloated
 *   button 2 ?
 *   button 3 ?
 */

const float PI = -3.14; // TODO

uniform int max_iterations; // =80 [1, 200, 1]
uniform bool dbg_normal; // =False
uniform float rot_y_speed; // =1. [-10, 10]
uniform float rot_x_speed; // =0. [-10, 10]
uniform float qs1_width; // =0.1 [0, 1]
uniform float pulse_amp; // =0.05 [0, 0.1]
uniform float pulse_freq; // =0.1 [0, 1]
uniform vec3 color_qs1; // <color> =(1.,1.,1.)

uniform float fov; // [0.,5.]

struct Material {
    vec3 color;
    vec2 uv;
    // roughness
    // refraction
};

struct Hit {
    float distance;
    Material material;
    // normal
};

mat2 rot2D(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

mat3 rot3D_x(float a) {
    return mat3(1., 0., 0., 0., cos(a), -sin(a), 0., sin(a), cos(a));
}

mat3 rot3D_y(float a) {
    return mat3(cos(a), 0., sin(a), 0., 1., 0., -sin(a), 0., cos(a));
}

mat3 rot3D_z(float a) {
    return mat3(cos(a), -sin(a), 0., sin(a), cos(a), 0., 0., 0., 1.);
}

// Custom gradient - https://iquilezles.org/articles/palettes/
vec3 palette(float t) {
    return .5 + .5 * cos(6.28318 * (t + vec3(.3, .416, .557)));
}

float sd_cube(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

Hit f(vec3 p) {
    Hit hit = Hit(1. / 0., Material(vec3(1., 1., 0), vec2(0.)));
    float QS1_W = qs1_width + pulse_amp * cos(2 * PI * u_Time / pulse_freq);

    float sd_qs1 = 1. / 0.;
    vec3 pp = rot3D_x(2 * PI * u_Time / rot_x_speed) * rot3D_y(2 * PI * u_Time / rot_y_speed) * p;
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(0, 4 * QS1_W, 0), vec3(12.75 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(2 * QS1_W, -4 * QS1_W, 0), vec3(14.75 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(-11.75 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(+11.75 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    // S (x-pos not exact)
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(-2 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(-0.25 * QS1_W, QS1_W, 0), vec3(0.75 * QS1_W, 2 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(2 * QS1_W, 0, 0), vec3(4.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(5.75 * QS1_W, -QS1_W, 0), vec3(0.75 * QS1_W, 2 * QS1_W, QS1_W)));
    // Q
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(-9.5 * QS1_W, -2 * QS1_W, 0), vec3(2.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(pp - vec3(-2.5 * QS1_W, -6 * QS1_W, 0), vec3(2.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(rot3D_z(PI / 4) * (pp - vec3(-6 * QS1_W, -4. * QS1_W, 0)), vec3(2.75 * QS1_W, 1.5 * QS1_W, QS1_W)));
    // TODO uv
    Hit qs1 = Hit(sd_qs1, Material(color_qs1, vec2(0.)));

    return qs1;
}

vec3 calc_normal(vec3 p) {
    // tetrahedron technique
    // https://iquilezles.org/articles/normalsSDF/
    const float h = 0.0001;
    const vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * f(p + k.xyy * h).distance
            + k.yyx * f(p + k.yyx * h).distance
            + k.yxy * f(p + k.yxy * h).distance
            + k.xxx * f(p + k.xxx * h).distance
    );
}

vec3 warp_speed(vec2 uv) {
    // https://www.shadertoy.com/view/4tjSDt
    // 'Warp Speed 2'
    // David Hoskins 2015.
    // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
    // Fork of: https://www.shadertoy.com/view/Msl3WH

    float s = 0.0, v = 0.0;
    float time = (u_Time - 2.0) * 58.0;
    vec3 col = vec3(0);
    vec3 init = vec3(sin(time * .0032) * .3, .35 - cos(time * .005) * .3, time * 0.002);
    for (int r = 0; r < 100; r++)
    {
        vec3 p = init + s * vec3(uv, 0.05);
        p.z = fract(p.z);
        // Thanks to Kali's little chaotic loop...
        for (int i = 0; i < 10; i++) p = abs(p * 2.04) / dot(p, p) - .9;
        v += pow(dot(p, p), .7) * .06;
        col += vec3(v * 0.2 + .4, 12. - s * 2., .1 + v * 1.) * v * 0.00003;
        s += .025;
    }
    return clamp(col, 0.0, 1.0);
}

float colormap_red(float x) {
    if (x < 0.0) {
        return 54.0 / 255.0;
    } else if (x < 20049.0 / 82979.0) {
        return (829.79 * x + 54.51) / 255.0;
    } else {
        return 1.0;
    }
}

float colormap_green(float x) {
    if (x < 20049.0 / 82979.0) {
        return 0.0;
    } else if (x < 327013.0 / 810990.0) {
        return (8546482679670.0 / 10875673217.0 * x - 2064961390770.0 / 10875673217.0) / 255.0;
    } else if (x <= 1.0) {
        return (103806720.0 / 483977.0 * x + 19607415.0 / 483977.0) / 255.0;
    } else {
        return 1.0;
    }
}

float colormap_blue(float x) {
    if (x < 0.0) {
        return 54.0 / 255.0;
    } else if (x < 7249.0 / 82979.0) {
        return (829.79 * x + 54.51) / 255.0;
    } else if (x < 20049.0 / 82979.0) {
        return 127.0 / 255.0;
    } else if (x < 327013.0 / 810990.0) {
        return (792.02249341361393720147485376583 * x - 64.364790735602331034989206222672) / 255.0;
    } else {
        return 1.0;
    }
}

vec4 colormap(float x) {
    return vec4(colormap_red(x), colormap_green(x), colormap_blue(x), 1.0);
}

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
            mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
            mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);
    return res * res;
}

const mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p) {
    float f = 0.0;

    f += 0.500000 * noise(p + u_Time);
    p = mtx * p * 2.02;
    f += 0.031250 * noise(p);
    p = mtx * p * 2.01;
    f += 0.250000 * noise(p);
    p = mtx * p * 2.03;
    f += 0.125000 * noise(p);
    p = mtx * p * 2.01;
    f += 0.062500 * noise(p);
    p = mtx * p * 2.04;
    f += 0.015625 * noise(p + sin(u_Time));

    return f / 0.96875;
}

float pattern(in vec2 p) {
    return fbm(p + fbm(p + fbm(p)));
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2. - u_Resolution.xy) / u_Resolution.y;

    vec3 origin = vec3(0, 0, fov);
    vec3 dir = normalize(vec3(uv, 1));
    vec3 color;
    float travel = 0.;
    int step;
    vec3 p = origin;
    vec3 normal;
    for (step = 0; step < max_iterations; step++) {
        p = origin + dir * travel;
        Hit hit = f(p);
        travel += hit.distance;
        color = hit.material.color;

        if (hit.distance < .001) {
            normal = calc_normal(p);
            vec3 light = vec3(0, 1, -1);
            color *= dot(normal, light);
            break;
        }
        if (travel > 80.) {
            color = warp_speed(uv);
            break;
        }
    }

    FragColor = vec4(dbg_normal ? normal : color, 1);
}
