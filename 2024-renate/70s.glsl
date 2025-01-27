vec2 rectangular = vec2(1.7,0.9);
uniform float offset; // =12. [0.,100.,5.] #102
uniform float amplitude; // =10. [1.,100.,1.] #103
uniform float gamm;// =1.1 [0.1,2.5,0.1] #106

//BOX_distanzfunktion
float lsdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}


//Farbpallete: https://www.shadertoy.com/view/mtyGWy
vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);

    return a + b*cos( 6.28348*(c*t+d));
}

void main(){

//normalisieren des Koordinatensystems auf [-1;+1]^2
vec2 uv= gl_FragCoord.xy / u_Resolution.xy * 3 -1.41;

//passe die x-Koordinate an die Apsketratio an
uv.x *= u_Resolution.x / u_Resolution.y;

//fixiere die absolute Bildmitte
vec2 uv_0 = uv - vec2(0.20,0.25);

//stellt es als Polarikoordinaten dar
//float d = length(uv)-0.5;

//Was passiert, wenn man sin(x)*sin(y) macht?
float d = sin((uv.x*2)-0.5)*cos((uv.y*2)-0.5)*(amplitude*sin(0.1*u_Time)+offset);

//wiederholt den Kreis durch die Periode des Sinus
d = sin(2.*(d- u_Time))/2.;

//Spiegelt es an der Kreiskante
d = abs(d);

//Invertieren für den Neoneffekt
d = 0.05 / d;

//Macht den Uebergang blury
//d = smoothstep(0.0, 0.4, d);

//stelle die Farben abhängig zur Mitte dar als Rechteckt
vec3 col = palette(lsdBox((uv_0), rectangular)+u_Time * 0.1);

//stelle die Farben abhängig zur Mitte dar als Kreis
//vec3 col = palette(u_Time * 0.1);

//multipliziere color*d
col *= pow(d,gamm);

FragColor = vec4(col, 1.);
}
