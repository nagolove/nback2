uniform float iTime;
uniform float iCount;

float drawLine (vec2 p1, vec2 p2, vec2 uv, float a)
{
    float r = 0.;
    float one_px = 1. / love_ScreenSize.x; //not really one px
    
    // get dist between points
    float d = distance(p1, p2);
    
    // get dist between current pixel and p1
    float duv = distance(p1, uv);

    //if point is on line, according to dist, it should match current uv 
    r = 1.-floor(1.-(a*one_px)+distance (mix(p1, p2, clamp(duv/d, 0., 1.)),  uv));
        
    return r;
}

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    float lines = 0.;

    //lines += drawLine(vec2(0., 0.), vec2(1., 1.), uv, 1.);

    //vec4 col = color * iTime;

    //vec4 col = color;
    //col.r = lines;
    //col.a = 1.;

    vec3 col = color.rgb;
    vec2 gv = fract(uv * iCount) - .5;
    vec2 id = floor(uv * iCount);

    //float d = length(gv);
    float m = 0.;

    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            vec2 offs = vec2(x, y);
            float d = length(gv - offs);
            float dist = length(id + offs) * 30.;
            float r = mix(0.3, 1.5, sin(iTime + dist) * 0.5 + 0.5);
            m += smoothstep(r, r * 0.9, d) * 0.3;
        }
    }

    //col.rg = gv;
    col += mod(m, 2.);
    //col += smoothstep(0.1, 0.11, uv.x);
    return vec4(col, 1.0);
}
