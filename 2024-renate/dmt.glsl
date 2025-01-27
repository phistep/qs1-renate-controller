uniform float layer;  // =1. [1.,6.,1.] #102
uniform float intensity;  // =6.28348 [1.28348,10.28348,1.] #103
uniform float speed; // =1. [0.1,2.,0.1] #107


vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);

    return a + b*cos( intensity*(c*t+d) );
}


void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_Resolution.xy) / u_Resolution.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);
    
    for (float i = 0.0; i < layer; i++) {
        uv = fract((uv * 1.5)) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        vec3 col = palette(length(uv0) + i*.4);

        d = sin(d*8. + (u_Time * speed) )/8.;
        d = abs(d);

        d = pow(0.01 / d, 1.2);
		//d = 0.01 / d;

        finalColor += col * d;
    }
        
    FragColor = vec4(finalColor, 1.0);
}
