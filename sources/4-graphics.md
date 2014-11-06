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
called OpenGL [@OpenGLES2book]. Its recent version targeted for embedded systems is OpenGL ES 2.0 [@OpenGLES2],
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

\clearpage

Graphical pipeline is described in the diagram below.
The pipeline is programmable, the program runs on the GPU,
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
Following figure shows how data are processed by the shader program.

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

\clearpage

Following functions are available in the API:

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

\clearpage

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
The `gl_Position` is special variable resembling the output of the vertex shader (the vertex position).
The fragment shader access texturing unit passed as a uniform variable
with the interpolated texture coordinates from the vertex shader.
Result is written to `gl_FragColor` which is a special variable resembling the output of the fragment shader
(the RGBA color).
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
The FreeType2 library can rasterize glyphs from the TrueType font file on the fly.
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

### System integration

Linux distributions usually use common framework for graphical applications and user interfaces.
To integrate this project into a high level graphical user interface application,
the `eglCreateWindowSurface()` function binds the drawing surface to a specific native window.
For windowless drawing (such as when the application runs directly on top of the kernel) a `NULL` window is used.
The application is built as a plug-in object, that may be bound to higher level framework such as *XLib*, *GTK+* or *Qt*,
which defines a specific window area and pass this to the `eglCreateWindowSurface()` function.
For example, the next code snippet shows simple *XLib* integration.

```{.c}
Display *display = XOpenDisplay(NULL);
unsigned long color = BlackPixel(display, 0);
Window root = RootWindow(display, 0);
Window window =
  XCreateSimpleWindow(display, root, 0, 0, 800, 600, 0, color, color);
XMapWindow(display, window);
XFlush(display);

EGLConfig egl_config; // TODO: eglChooseConfig()
EGLDisplay egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
EGLSurface egl_surface =
  eglCreateWindowSurface(egl_display, egl_config, window, NULL);
```

The same *GTK+* application would be

```{.c}
GtkWidget *main_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
GtkWidget *video_window = gtk_drawing_area_new();
gtk_widget_set_double_buffered(video_window, FALSE);
gtk_container_add(GTK_CONTAINER(main_window), video_window);
gtk_window_set_default_size(GTK_WINDOW(main_window), 640, 480);
gtk_widget_show_all(main_window);

EGLConfig egl_config; // TODO: eglChooseConfig()
EGLDisplay egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
GdkWindow *window = gtk_widget_get_window(video_window);
EGLSurface egl_surface =
  eglCreateWindowSurface(egl_display, egl_config, GDK_WINDOW_XID(window), NULL);
```

And the the *Qt* application

```{.cpp}
QApplication app(0, NULL);
QWidget window;
window.resize(800, 600);
window.show();

EGLConfig egl_config; // TODO: eglChooseConfig()
EGLDisplay egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
EGLSurface egl_surface =
  eglCreateWindowSurface(egl_display, egl_config, window.winId(), NULL);
```

The `egl_config` structure is used to configure the OpenGL context, it is a NULL terminated list of attribute-value pairs.
The following table shows some valid attributes.

**Attribute**               **Value**
--------------------------- ------------------------
`EGL_DEPTH_SIZE`            Depth buffer size, in bits
`EGL_RED_SIZE`              Size of the red component of the color buffer, in bits
`EGL_GREEN_SIZE`            Size of the green component of the color buffer, in bits
`EGL_BLUE_SIZE`             Size of the blue component of the color buffer, in bits
`EGL_ALPHA_SIZE`            Size of the alpha component of the color buffer, in bits
`EGL_RENDERABLE_TYPE`       `EGL_OPENGL_BIT`, `EGL_OPENGL_ES_BIT`, `EGL_OPENGL_ES2_BIT`
`EGL_SURFACE_TYPE`          `EGL_PBUFFER_BIT`, `EGL_PIXMAP_BIT`, `EGL_WINDOW_BIT`

Table: EGL attributes

### Implementation

The graphics subsystem is implemented as a widget oriented drawing library.
The widget is a standalone drawable object with a common drawing interface consisting of

 - drawable type (geometry primitive, vector text, image)
 - vertex buffer object
 - vertex number
 - texture object
 - drawing mode type (lines, surfaces)
 - drawing color and texture color mask

A common drawing function is implemented for all widgets, arguments of this function are:
translation (x, y screen coordinates), scale (0-1) and rotation (0-$2\pi$).
The translation coordinates are normalized before rendering.
The following vertex shader is used to provide these calculations

```{.c}
attribute vec4 coord;
uniform vec2 offset;
uniform vec2 scale;
uniform float rot;
varying vec2 texpos;
void main()
{
  float sinrot = sin(rot);
  float cosrot = cos(rot);
  vec2 pos = vec2(coord.x * cosrot - coord.y * sinrot,
                  coord.x * sinrot + coord.y * cosrot);
  gl_Position = vec4(pos * scale + offset, 0, 1);
  texpos = coord.zw;
}
```

The respective fragment shader is

```{.c}
uniform vec4 color;
uniform vec4 mask;
uniform sampler2D tex;
varying vec2 texpos;
void main()
{
  gl_FragColor = texture2D(tex, texpos) * mask + color;
}
```

