/* TODO
 * bloated ones rotatin the background
 * gradient to the center
 * burning flames and hyperdrive start bg
 * rotates over time
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

const float FLOAT_EPSILON = 1.19209290E-07; // 2^-23

uniform int max_iterations; // =80 [1, 200, 1]

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
    float QS1_W = 0.1;

    Hit ground = Hit(p.y + 5., Material(vec3(0.), vec2(0.)));

    float sd_qs1 = 1. / 0.;
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(0, 4 * QS1_W, 0), vec3(12.75 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(2 * QS1_W, -4 * QS1_W, 0), vec3(14.75 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(-11.75 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(+11.75 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    // S (x-pos not exact)
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(-2 * QS1_W, 0, 0), vec3(QS1_W, 4 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(-0.25 * QS1_W, QS1_W, 0), vec3(0.75 * QS1_W, 2 * QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(2 * QS1_W, 0, 0), vec3(4.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(5.75 * QS1_W, -QS1_W, 0), vec3(0.75 * QS1_W, 2 * QS1_W, QS1_W)));
    // Q
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(-8.5 * QS1_W, -2 * QS1_W, 0), vec3(1.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(p - vec3(-2.5 * QS1_W, -6 * QS1_W, 0), vec3(2.5 * QS1_W, QS1_W, QS1_W)));
    sd_qs1 = min(sd_qs1, sd_cube(rot3D_z(-3.14 / 4) * (p - vec3(-6 * QS1_W, -4. * QS1_W, 0)), vec3(2.75 * QS1_W, 1.5 * QS1_W, QS1_W)));
    // TODO uv
    Hit qs1 = Hit(sd_qs1, Material(vec3(1.), vec2(0.)));

    return (ground.distance < qs1.distance) ? ground : qs1;
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2. - u_Resolution.xy) / u_Resolution.y;

    vec3 origin = vec3(0, 0, -3);
    vec3 dir = normalize(vec3(uv, 1));
    vec3 color;
    float travel = 0.;
    int step;
    for (step = 0; step < max_iterations; step++) {
        vec3 p = origin + dir * travel;
        Hit hit = f(p);
        travel += hit.distance;
        color = hit.material.color;
        if (hit.distance < .001 || travel > 80.) break;
    }
    FragColor = vec4(color, 1);
}
