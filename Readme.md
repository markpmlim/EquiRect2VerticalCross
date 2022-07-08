## EquiRectangular to Vertical Cross Cubemap

<br />
<br />
<br />

Instead of converting an EquiRectangular projection of a scene to a cubemap texture make up of six 2D textures, we explore the possibilty of directly rendering a vertical crossmap cubemap texture from a 2:1 EquiRectangular image.

Since a vertical cross cubemap can be rendered from an ordinary (six 2D) cubemap texture, we can use the idea of deriving a pair of texture coordinates for a given face.

Referring to the Rendermann specifications:

![screenshot](LookupTable.png)

<br />
<br />

to access one of the six 2D textures of the cubemap, we formulate a 3D vector. So, if we know the face, we just setup the vector using the Lookup table above as a guide.

As an example, when we want to access the pixels of the **+X** face, the 3D vector should be:

```metal

    float3 vector = float3(1.0, -tc, -sc);
    
```

where sc and tc are texture coordinates that are mapped to the texture coordinates of a pixel of the corresponding face of the 2D Vertical Cross cubemap. If you read Paul Reed's article, you use any mapping scheme (cf **Cubemap Layout**). The 2 important things to note is:

a) mapping a pixel's texture coordinates in a particular output cubemap layout (e.g. vertical cross) to a face of a cube, and,

b) normalize the 3D vector.


We have chosen a time-tested method by mapping a pixel of the output image to a cube of 2 units. The 3D vector must be normalized inside the if branch:

```metal

    if (dir.x != 0.0 && dir.y != 0.0) {
        dir = normalize(dir);
        uv = sampleSphericalMap(dir);
        out_color = tex.sample(textureSampler, uv);
    }

```


**Requirements:** 
<br />

XCode 9.x, Swift 4.x and macOS 10.13.4 or later.

<br />
<br />


**Web Links:**


https://cgvr.cs.uni-bremen.de/teaching/cg_literatur/Cube_map_tutorial/cube_map.html


http://paul-reed.co.uk/programming.html


