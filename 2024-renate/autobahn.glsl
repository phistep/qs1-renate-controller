
uniform float LANEWIDTH; // =0.1 #102
uniform float LANESEP; // =0.02 #103
uniform float DIRSEP;// =0.01 #106

uniform float number; // =(32.0) [0.,100.,1.] #107
uniform float test; // =(0.3) [.01,2.,0.05] #108
float dLine( vec2 p, vec2 a, vec2 b )
{
  vec2 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h );
}

float sdCapsule( vec2 p, vec2 a, vec2 b, float r )
{
  vec2 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

vec2 qspline(vec2 p0, vec2 p1, vec2 p2, float t) {
    float t0 = (1.0-t);
    return t0*t0 * p0 + 2.0 * t *t0 * p1 + t*t*p2;
}

vec2 cspline(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float t0 = (1.0-t);
    vec2 q = t0 * t0 * t0 * p0;
    q += 3.0 * t * t0* t0 * p1;
    q += 3.0 * t * t * t0 * p2;
    q += t * t * t * p3;
    return q;
}


float dqspline(vec2 uv, vec2 p0, vec2 p1, vec2 p2) {
    float d = 100000.0;
    vec2 a = p0;
    for(float i = 1.0; i < number; i+= 1.0) {
        vec2 b = qspline(p0, p1, p2, i / (number-1.0));
        d = min(d, dLine(uv, a,b));
        a = b;
    }
    return d;
}

float dcspline(vec2 uv, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
    float d = 100000.0;
    vec2 a = p0;
    for(float i = 1.0; i < number; i+= 1.0) {
        vec2 b = cspline(p0, p1, p2, p3, i / (number-1.0));
        d = min(d, dLine(uv, a,b));
        a = b;
    }
    return d;
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}

float sdTurnLane(vec2 uv, vec2 x0, vec2 dir0, vec2 dir1) {

    float lw2 =LANEWIDTH/2.0;

    vec2 m0 = normalize(x0);
    vec2 m01 = dir1 * sign(dot(dir1,m0));
    float cosA = dot(m0, m01);
    float sinA = sqrt(1.0 - cosA*cosA);
    
    vec2 cc = x0 + m0 *  test / sinA;
    float circle0 = length(uv-cc) - test - lw2;
    float circle1 = length(uv-cc) - test + lw2;
    
    float a = test * cosA/sinA;
    vec2 p0 = x0 + dir0 * a;
    vec2 p1 = x0 + dir1 * a;
   
    float d1 = sdTriangle(uv, cc, 100.0 * (p0 - cc) + cc, 100.0 * (p1 - cc) + cc);
    float turn = max(-circle1, max(circle0, -d1));
    float lineA = sdCapsule(uv, 2.0 *(x0-p0)+p0, p0, lw2);
    float lineB = sdCapsule(uv, 2.0 *(x0-p1)+p1, p1, lw2);
    
    float d = min(min(lineA, lineB), turn);
    //float d = turn;
    vec2 dirM = normalize(dir0 + dir1);
    vec2 tp = cc + dirM * (test + LANESEP + LANEWIDTH);
    float td = length(tp - x0);
    float R2 = td *sinA/(1.0-sinA);
    vec2 c2 = tp + dirM * R2;
    
    float cL = length(c2 - uv)-R2 - lw2;
    float cS = length(c2 - uv)-R2 + lw2;
    float b = R2 * cosA/sinA;
    vec2 q0 = x0 + dir0 * b;
    vec2 q1 = x0 + dir1 * b;
    float clip = sdTriangle(uv, c2, 100.0 * (q0-c2)+c2, 100.0 * (q1-c2)+c2);
    float crim = max(max(cL, -cS), clip);
    d = min(d, crim);
    d = min(d, sdCapsule(uv, q0, q0 + 10.0 * dir0, lw2));
    d = min(d, sdCapsule(uv, q1, q1 + 10.0 * dir1, lw2));
    return d;
}


vec4 dTurnLanes(vec2 uv, vec2 dirA, vec2 dirB) {

    vec2 dirM = normalize(dirA + dirB);
    float rw = 3.0 * LANESEP + 2.5 * LANEWIDTH;

    float cosPhi = dot(dirA, dirM);
    float sinPhi = sqrt(1.0 - cosPhi * cosPhi);
    
    vec2 corner = dirM * rw / sinPhi;
    float d = sdTurnLane(uv, corner, dirA, dirB);
    
    float d0 = 1.0 -smoothstep(-0.02, 0.00, d);
    
    return vec4(d0,0,d0, d);
}

vec4 allTurnLanes(vec2 uv, vec2 d0, vec2 d1) {

    float cosA = dot(d0,d1);
    vec4 road0 = dTurnLanes(uv, d0, -d1);
    vec4 road1 = dTurnLanes(uv,-d1,-d0);
    vec4 road2 = dTurnLanes(uv,-d0, d1);
    vec4 road3 = dTurnLanes(uv, d1, d0);
    float r = min(min(road0.w, road1.w), min(road2.w, road3.w));
    float s0 = smoothstep(0.0,-LANESEP,r);
    vec3 col = mix(vec3(1.0), vec3(0.7), s0);
    return vec4(col,r);

}

vec4 dLanes(vec2 uv, vec2 dirA) {

    vec2 pA = 10.0 * dirA;
    vec2 roA = vec2(dirA.y, -dirA.x);
    float rw = DIRSEP + 2.0 * LANESEP + 2.0 * LANEWIDTH;
    
    float r = sdCapsule(uv, pA, -pA, rw);
    
    float s0 = smoothstep(0.0,-LANESEP,r);
    float s1 = smoothstep(-rw/2.0-LANESEP, -rw/2.0, r);
    float s2 = smoothstep(-rw/2.0+LANESEP, -rw/2.0, r);
    float s3 = smoothstep(-rw+DIRSEP/2.0, -rw+DIRSEP/2.0+0.004, r);
    vec3 col = mix(vec3(1), vec3(0.7), s0 * s3* (1.0-s1*s2));
    return vec4(col,r);
    
}

vec3 image(vec2 uv) {
    
    float t0 = 0.1231 * u_Time + 0.32;
    float t1 = t0 + (0.8 + 0.2 * (u_Time)) * 3.1415/2.0;
    vec2 dir0 = vec2(cos(t0),sin(t0));
    vec2 dir1 = vec2(cos(t1),sin(t1));
    
    vec4 d0 = allTurnLanes(uv, dir0, dir1);
    float a0 = smoothstep(0.01,0.0, d0.w);
    //return mix(vec3(0),d0.rgb, a0);
    
    vec4 d1 = dLanes(uv, dir0);
    float a1 = smoothstep(0.01,0.0, d1.w);
    
    vec4 d2 = dLanes(uv, dir1);
    float a2 = smoothstep(0.01,0.0, d2.w);
    
    vec3 c2 = mix(vec3(0), vec3(0.8*d2.rgb),a2);
    vec3 c0 = mix(c2, vec3(0.9*d0.rgb), a0);
   
    return mix(c0, vec3(d1.rgb), a1);
    //return vec3(a2);
}


void main()
{
    vec2 center = u_Resolution.xy/2.0;
    vec2 uv = (gl_FragCoord.xy - center) / min(center.x, center.y);
    
    // Output to screen
    FragColor = vec4(sqrt(3)*normalize(vec3(0.0235,0.2235,0.4431))*image(2.0 * uv),1.0);
}


