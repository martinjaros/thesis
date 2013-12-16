## Graphics subsystem

Graphical output in the Linux Kernel is accessible as a framebuffer device `/dev/fb`.
This allows directly writing to a display memory from the application.
OMAP platform further extends this interface to support its DSS2 architecture
for multiplexing graphical and video systems with display outputs.
There is a framebuffer device connected to the PowerVR SGX graphical accelerator
with control interface at `/sys/class/graphics/fbX`, where `X` is the framebuffer number.
The OMAP DSS subsystem is exported at `/sys/devices/platform/omapdss` as

 * `/sys/devices/platform/omapdss/overlayX/`
 * `/sys/devices/platform/omapdss/managerX/`
 * `/sys/devices/platform/omapdss/displayX/`

where overlays may read from FB or V4L2 devices,
combined in the manager and then linked to a physical display.
Input sources can be blended by color keying to create the output image,
this is useful for rendering graphical overlays.
Individual displays (HDMI, LCD) are also configured by this interface.

### OpenGL ES 2.0 API
There is a standardized library for interfacing with graphical accelerators maintained by Khronos group
called OpenGL. Its recent version targeted for embedded systems is [OpenGL ES 2.0][opengles] [@OpenGLES2] [@OpenGLES2book],
implemented by majority of hardware developers. It is also supported by the multi-platform Mesa3D library,
so it will run also on desktop computer, either emulated by CPU or partially accelerated depending on available hardware.
OpenGL ES 2.0 is implemented in two parts, the kernel module and user-space libraries *EGL* and *GLESv2*.
Its implementation will be platform specific, however the application interface is the same.
Functions names in the API are prefixed with *gl* and suffixed by argument types, used for overloading.
EGL library is used for initialization of the OpenGL context, following function are available in the API:

**Function**               **Description**
-------------------------- ----------------
`eglGetDisplay()`          Select display
`eglInitialize()`          Initialize display
`eglBindAPI()`             Select OpenGL API version
`eglChooseConfig()`        Select configuration options
`eglCreateWindowSurface()` Create drawable surface (bound to native window)
`eglCreateContext()`       Create OpenGL context
`eglMakeCurrent()`         Activate context and surface

Table: EGL function for OpenGL ES initialization

Graphical pipeline is programmable, the program runs on the GPU,
while OpenGL API is used for communication with the application running on CPU.

![OpenGL ES pipeline][pipeline]

Programs are compiled from source and written in the GLSL language,
each program consists of vertex and fragment shader.
Following function are available in the API:

**Function**                  **Description**
----------------------------- ----------------
`glCreateShader()`            Create shader
`glShaderSource()`            Load shader source
`glCompileShader()`           Compile shader from loaded source
`glDeleteShader()`            Delete shader
`glShaderBinary()`            Load shader from binary data
`glCreateProgram()`           Create program
`glAttachShader()`            Add shader to program
`glLinkProgram()`             Link shaders in program
`glUseProgram()`              Switch between multiple programs
`glDeleteProgram()`           Delete program
`glGetUniformLocation()`      Access uniform variable defined in shader
`glGetAttribLocation()`       Access attribute variable defined in shader

Table: OpenGL functions for working with shader programs

The vertex shader processes geometry defined as array of verticies, it is executed per vertex.
Result verticies are rasterized into fragments and then fragment shader is executed per fragment.
Result fragments are then written into the framebuffer, each shader execution is done in parallel.

![OpenGL ES shader program][shaders]

GPU uses its own memory, it may be physically shared with the system memory,
but is not directly accessible by the application.
Verticies are stored in the GPU memory in vertex buffer objects (VBO),
following API function are available:

**Function**                  **Description**
----------------------------- ----------------
`glGenBuffers()`              Create vertex buffer object
`glDeleteBuffers()`           Destroy vertex buffer object
`glBufferData()`              Load vertex data into VBO
`glBindBuffer()`              Bind VBO to attribute array
`glVertexAttribPointer()`     Specify attribute array
`glEnableVertexAttribArray()` Enable attribute array

Table: OpenGL functions for working with VBOs

Shader programs have three types of variables, attributes, uniforms and varyings.
Attributes are read from the attribute array which is bound to the VBO.
Each vertex from the array is processed separately by each shader execution,
having its value accessible by the attribute variables.
Uniforms can be assigned directly by the application using `glUniform()`,
they are read-only by the shader and they are shared by each execution.
Varyings are used to pass variables from vertex shader to fragment shader,
they are interpolated between verticies during the rasterization.
Fragment shaders may use textures to to calculate fragment color,
textures are stored in the GPU memory and loaded by the application.
Following functions are available in the API:
\clearpage

**Function**                **Description**
--------------------------- ----------------
`glGenTextures()`           Create texture object
`glTexImage2D()`            Load pixel data into texture object
`glTexSubImage2D()`         Load partial pixel data
`glTexParameter()`          Set parameter
`glBindTexture()`           Bind texture to active unit
`glActiveTexture()`         Select texture unit
`glDeleteTextures()`        Delete texture

Table: OpenGL functions for working with textures

Textures are bound to the texture units which may be accessed from the shader program.
If the fragment shader needs to work with multiple textures,
each texture needs to be loaded into a different texturing unit.
The typical drawing loop is:

 * select shader program
 * assign uniform variables
 * bind textures to texturing units
 * bind VBOs to attribute arrays
 * start processing with `glDrawArrays()`
 * swap framebuffers and repeat

### OpenGL ES Shading Language

Shader programs are designed to be executed in parallel, over large blocks of data.
The language is similar to C, the minimal structure of the vertex shader is:

```{.c}
attribute vec4 vertex;
varying vec2 texcoord;

void main()
{
  gl_Position = vec4(vertex.xy, 0, 1);
  texcoord = vertex.zw;
}
```

and the fragment shader:
```{.c}
uniform sampler2D texture;
varying vec2 texcoord;

void main()
{
  gl_FragColor = texture2D(texture, texcoord);
}
```

This vertex shader takes one vertex attribute as a vector, where first two fields are display coordinates
and the second two fields are texture coordinates.
It defines varying variable to pass texture coordinates to the fragment shader.
The `gl_Position` is special variable resembling the output of the vertex shader.
The fragment shader access texturing unit passed as a uniform variable
with the interpolated texture coordinates from the vertex shader.
Result is written to `gl_FragColor` which is a special variable resembling the output of the fragment shader.
GLSL supports vector and matrix types, for example `vec4` is the four element vector and `mat3` is the 3x3 matrix.
Vectors may be combined freely for example

`vec4(vec4(0, 1, 2, 3).xy, 4, 5) * 1.5`{.c}

will create vector (0, 1, 2, 3), take its first two fields (x, y) to create vector (0, 1, 4, 5) and then multiply by scalar
resulting in vector (0, 1.5, 6, 7.5).
GLSL also features standard mathematical functions such as trigonometry, exponential, geometric, vector or matrix.
The `sampler2D` type refers to the texturing unit, to access its texture function `texture2D()` is used.
The way by which samplers calculates the texture color is determined by the parameters set through the API.
For example having two pixel texture with one black and one white pixel with setting

`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);`{.x}

will cause linear color mapping and therefore black-white color gradient.
However setting

`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);`{.x}\
`glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);`{.x}

will create chessboard pattern.
These setting are done per texture object and reflected by texturing unit to which the texture is bound.

### TrueType font rendering

In order to be able to render TrueType vector fonts, each glyph needs to be pre-rasterized first.
The best method to achieve this is to create glyph atlas texture with all glyphs needed
and then generate strings as VBOs with proper texture coordinates for each character.
To utilize unicode support, this atlas needs to be appended by newly requested characters in real-time
as there are too many glyphs to be pre-rasterized.
The [FreeType2][freetype] library can rasterize glyphs from the TrueType font file on the fly.
These glyphs are in fact alpha maps to be processed by the fragment shader:

`gl_FragColor = color * texture2D(texture, texcoord).a;`{.c}

or

`gl_FragColor = vec4(color.rgb, texture2D(texture, texcoord).a);`{.c}

if the alpha blending is enabled with

`glEnable(GL_BLEND);`{.c}\
`glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);`{.c}

where `color` is the text color.

The FreeType library loads the font faces from `.ttf` files and has following API:

**Function**                **Description**
--------------------------- ----------------
`FT_Init_FreeType()`        Initialize the library
`FT_New_Face()`             Load font face from file
`FT_Select_Charmap()`       Set encoding (Unicode)
`FT_Set_Pixel_Sizes()`      Set font size
`FT_Load_Char()`            Rasterize single glyph
`FT_Done_FreeType()`        Release resources

Table: FreeType API

The glyphs are loaded to texture with `glTexSubImage2D()`.
To change the font size it is better to rasterize new glyph with `FT_Load_Char()`,
then trying to scale the glyph in the fragment shader.
To achieve best results, there should be 1:1 mapping between glyph pixels and OpenGL fragments
and blending should be enabled. The library also supports kerning and other features
to make the result text better or to create special effects.
Special care needs to be taken into account about pixel alignment when rendering text.
Vertex shader must ensure that each glyph verticies are aligned without pixel fractions.
The typical example is the centering of text with even pixel width,
which causes verticies to be aligned with 0.5 pixel offset.
This causes major aliasing artifacts during rasterization
and can be prevented by subtracting the fragment coordinate fractional part in the vertex shader.

### Texture streaming extensions

Loading textures the standard way causes copying the pixel buffer to the texture memory,
which is very inefficient if the texture needs to be changed often.
This is typical to streaming video through the GPU.
There is a `KHR_image_base` extension for the EGL and a `OES_EGL_image` extension for the OpenGL ES
defined in `EGL/eglext.h` and `GLES2/gl2ext.h` respectively.
These extensions are platform specific, this text refers to the Texas Instruments implementation.
The `EGLImage` offers a way to map images in the EGL API to be accessed in OpenGL as `GL_TEXTURE_EXTERNAL_OES` textures.
This works as memory mapping and no copying is done whatsoever, synchronization is handled by the application.
The mapping is created by

```{.c}
EGLImageKHR img =
  eglCreateImageKHR(dpy, EGL_NO_CONTEXT, EGL_RAW_VIDEO_TI, ptr, attr);
glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES, (GLeglImageOES)img);
glBindTexture(GL_TEXTURE_EXTERNAL_OES, myTexture);
```

where `dpy` is the active EGL display, `ptr` is pointer to the video buffer and `attr` is array of configuration options.
This extension is also able to perform YUV to RGB color-space conversion in the background.

