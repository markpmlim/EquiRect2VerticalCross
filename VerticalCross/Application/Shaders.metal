//
//  Shaders.metal
//  EquiRect2Crossmaps
//
//

#include <metal_stdlib>

using namespace metal;

typedef struct {
    float4 clip_pos [[position]];
    float2 uv;
} ScreenFragment;

/*
 No geometry are passed to this vertex shader; the range of vid: [0, 2]
 The position and texture coordinates attributes of 3 vertices are
 generated on the fly.
 clip_pos: (-1.0, -1.0), (-1.0,  3.0), (3.0, -1.0)
       uv: ( 0.0,  1.0), ( 0.0, -1.0), (2.0,  1.0)
 The area of the generated triangle covers the entire 2D clip-space.
 Note: any geometry rendered outside this 2D space is clipped.
 Clip-space:
 Range of position: [-1.0, 1.0]
       Range of uv: [ 0.0, 1.0]
 The origin of the uv axes starts at the top left corner of the
   2D clip space with u-axis from left to right and
   v-axis from top to bottom
 For the mathematically inclined, the equation of the line joining
 the 2 points (-1.0,  3.0), (3.0, -1.0) is
        y = -x + 2
 The point (1.0, 1.0) lie on this line. The other 3 points which make up
 the 2D clipspace lie on the lines x=-1 or x=1 or y=-1 or y=1
 */

vertex ScreenFragment
screen_vert(uint vid [[vertex_id]]) {
    // from "Vertex Shader Tricks" by AMD - GDC 2014
    ScreenFragment out;
    out.clip_pos = float4((float)(vid / 2) * 4.0 - 1.0,
                          (float)(vid % 2) * 4.0 - 1.0,
                          0.0,
                          1.0);
    out.uv = float2((float)(vid / 2) * 2.0,
                    1.0 - (float)(vid % 2) * 2.0);
    return out;
}

// Left-hand - this function is based on a DirectX Pixel Shader.
// Helper function
//constant float2 invAtan = float2(0.1591, 0.3183);         // 1/2π, 1/π
constant float2 invAtan = float2(1/(2*M_PI_F), 1/M_PI_F);   // 1/2π, 1/π

float2 sampleSphericalMap(float3 direction)
{
    // Original code:
    //      tan(θ) = dir.z/dir.x and sin(φ) = dir.y/1.0
    float2 uv = float2(atan2(direction.x, direction.z),
                       asin(-direction.y));
    
    // The range of u: [ -π,   π ] --> [-0.5, 0.5]
    // The range of v: [-π/2, π/2] --> [-0.5, 0.5]
    uv *= invAtan;
    uv += 0.5;          // [0, 1] for both u & v
    
    return uv;
}

/*
 The origin of the Metal texture coord system is at the upper-left of the quad.
 */
fragment half4
EquiRect2VerticalCross(ScreenFragment  in  [[stage_in]],
                       texture2d<half> tex [[texture(0)]]) {

    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Map the range of uv: [0.0, 1.0] ---> [3.0, 4.0]
    float2 uv = in.uv * float2(3.0, 4.0);

    int x = int(floor(uv.x));       // 0, 1, 2
    int y = int(floor(uv.y));       // 0, 1, 2, 3
    float3 dir = float3(0);

    if (x == 1) {
        // The middle column of 4 squares, each of which is 1 squared unit.
        // uv.x: [1.0, 2.0] ---> uv.x: [0.0, 1.0]
        // uv.y: [0.0, 4.0] ---> uv.y: [0.0, 1.0]
        uv = float2(uv.x - 1.0,
                    uv.y - y);
        uv = 2.0 * uv - 1.0;
        switch(y) {
            case 0:
                // +Y
                dir = float3(+uv.x,  1.0,  +uv.y);
                break;
            case 1:
                // +Z
                dir = float3(+uv.x, -uv.y,  1.0);
                break;
            case 2:
                // -Y
                dir = float3(+uv.x, -1.0, -uv.y);
               break;
            case 3:
                // -Z
                dir = float3(+uv.x, +uv.y, -1.0);
                break;
        }
    }
    else {
        // x = 0 or x = 2
        // 2nd horizontal row of 2 squares (-X, +X)
        if (y == 1) {
            // The middle row of 3 squares, each of which is 1 squared unit.
            // The square at (1, 1) which is the front face is done
            // x = 0 (-X)
            // uv.x: [0.0, 1.0] ---> uv.x: [0.0, 1.0]
            // uv.y: [1.0, 2.0] ---> uv.y: [0.0, 1.0]
            // x = 2 (+X)
            // uv.x: [2.0, 3.0] ---> uv.x: [0.0, 1.0]
            // uv.y: [1.0, 2.0] ---> uv.y: [0.0, 1.0]
            uv = float2((uv.x - x),
                        (uv.y - 1.0));
            // Convert [0.0, 1.0] ---> [-1.0, 1.0]
            uv = 2.0 * uv - 1.0;
            switch(x) {
                case 0:
                    // -X
                    dir = float3(-1.0, -uv.y,  +uv.x);
                    break;
                case 2:
                    // +X
                    dir = float3( 1.0, -uv.y, -uv.x);
                    break;
            }
        }
    }
    half4 out_color = half4(0);
    if (dir.x != 0.0 && dir.y != 0.0) {
        dir = normalize(dir);
        uv = sampleSphericalMap(dir);
        out_color = tex.sample(textureSampler, uv);
    }
    return out_color;
}
