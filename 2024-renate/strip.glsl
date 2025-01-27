uniform float cub_depth; // =(0.001) [0.,2.5,.001] #102
uniform float cub_length; // =(0.001) [0.,2.5,.001] #103
uniform float z_coordinate; // =0.01 [-10.,10.,.1] #106
uniform float skalar; // =20. [0.001,50,.005] #107
uniform float color; // =1. [0.1,5.,0.2] #108
uniform float speed; // =1. [0.1,2.,0.1] #109
bool torus = false;
//uniform float cub_width; // =(0.001) [0.,.5,.001] #5
vec2 rectangular = vec2(cub_depth,cub_length);

vec3 palette(float t) {
    return .5+.5*cos(vec3(0.383,0.5,0.5)*(t+vec3(-.5,.668,.838)));
}

float lsdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-length(p)*t.y;
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_Resolution.xy) / u_Resolution.y ;
	
	float box;
	if(torus){
		box = lsdBox(uv, rectangular);
	}
	else{
		box = sdTorus( vec3(uv,z_coordinate), rectangular);
	}
	
    float value = step(fract(u_Time * speed), smoothstep(.0,1.,fract(box * skalar)));
	
	vec3 color_intern = palette( color * u_Time);

    FragColor = vec4( color_intern * value, 1.0);
}
