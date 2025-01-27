uniform float skalar; // =1. [0.,2.,.05] #102
uniform float skalar_time; // =1. [0.,2.,.05] #103
uniform float color; // =0.5 [0.,1.,.05] #106
uniform float color_r; // =0.5 [0.,1.,.05] #107
uniform float color_g; // =0.1 [0.,1.,.05] #108
uniform float color_b; // =0.5 [0.,1.,.05] #109


#define PI acos(-1.)
#define TAU (2.*PI)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define hash21(x) fract(sin(dot(x,vec2(26.4,32.87)))*467.5)
#define dt(sp) fract(u_Time*sp)

float hexa (vec2 p)
{
    p=abs(p);
    return max(p.x,dot(p,normalize(vec2(1.,sqrt(3.)))));
	//return max(p.x,dot(p,normalize(vec2(1.,sqrt(3.)))));
}

float torus (vec3 p, vec2 rs)
{
    vec2 q = vec2(hexa(p.xy)-rs.x,p.z);
    float a = atan(p.y, p.x);
    q *= rot(a+(u_Time*skalar_time));
    q = abs(abs(q)-.6)-0.3;
    
    return hexa(q)-rs.y;
}

float g1=0.;
float SDF (vec3 p)
{
    p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz*=rot(PI/4.);
    
    float t = torus(p.xzy,vec2(3.,0.3));
    p.y -= sin(dt(skalar)*TAU)*.5+.5;
    float s = length(p)-0.8;
    g1 += 0.01/(0.01+s*s);
    
    float d = min(t,s); 
    
    return d;
}

vec3 getnorm(vec3 p)
{
    vec2 eps = vec2(0.001,0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float AO (float eps, vec3 p, vec3 n)
{return clamp(SDF(p+eps*n)/eps,0.,1.);}

float spec (vec3 n, vec3 l, vec3 rd)
{
    vec3 h = normalize(l-rd);
    return pow(max(dot(n,h),0.),35.);
}

void main()
{
    vec2 uv = (2.*gl_FragCoord.xy-u_Resolution.xy)/u_Resolution.y;
    
    float dither = hash21(uv);
    vec3 ro=vec3(uv*3.8,-50.),rd=normalize(vec3(0.,0.0,1.)),p=ro,
    col=vec3(0.),l=vec3(1.,2.,-2.);
    
    bool hit=false;
    for (float i=0.; i<100.; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit=true;break;
        }
        d *= .75+dither*0.15;
        p += d*rd;
    }
    
    if (hit)
    {
        vec3 n = getnorm(p);
        
        float light = max(dot(n,normalize(l)),0.),
        ao=AO(0.1,p,n)+AO(0.25,p,n)+AO(0.65,p,n),
        s = spec(n,l,rd);
        
        col = mix(vec3(color_r,color_g,color_b),vec3(0.,0.3,0.8),light)*ao/3.+s*vec3(0.,0.8,0.2);
    }
    col += g1*color;
    
	//FragColor = vec4(col,1.0);
    FragColor = vec4(sqrt(col),1.0);
}
