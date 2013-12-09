## Graphics subsystem

There is a standardized library for interfacing with graphical accelerators maintained by Khronos group
called OpenGL. Its recent version targeted for embedded systems is OpenGL ES 2.0 [@OpenGLES2],
implemented by majority of hardware developers. It is also supported by the multi-platform *Mesa3D* library,
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
`eglCreateWindowSurface()` Create drawable surface (bind to native window)
`eglCreateContext()`       Create OpenGL context
`eglMakeCurrent()`         Activate context and surface

Table: EGL function for OpenGL ES initialization

Graphical pipeline is programmable, the program runs on GPU,
while OpenGL API is used for communication with the application running on CPU.
Programs are compiled from source and written in GLSL language described later,
each program consists of vertex and fragment shader, following function are available in the API:

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

GPU uses its own memory, it may be physically shared with the system memory,
but is not directly accessible by the application.
Drawables are defined by their geometry and textures.
Geometry is defined by verticies and stored in GPU memory in vertex buffer objects (VBO),
following API function are available:

**Function**                  **Description**
----------------------------- ----------------
`glGenBuffers()`              Create vertex buffer object
`glDeleteBuffers()`           Destroy vertex buffer object
`glBufferData()`              Load vertex data into VBO
`glBindBuffer()`              Switch between multiple VBOs
`glVertexAttribPointer()`     Assign VBO to attribute variable
`glEnableVertexAttribArray()` Enable shader attribute

Table: OpenGL functions for working with VBOs

Shader programs have three types of variables, attributes, uniforms and varyings.
Attributes are used to input geometry, they can be assigned with VBO, shaders are executed per vertex,
so their programs access single attribute only. Uniforms can be assigned directly by `glUniform()`
and they are shared by each parallel execution of the program.
Varyings are used to pass variables from vertex shader to fragment shader.
The vertex shader is executed first, per vertex, then each vertex is rasterized into fragments,
each fragment is then processed by fragment shader.
Resulting fragments resembles pixels that are written to the output framebuffer.
Fragment shaders uses textures to to calculate fragment color,
textures are stored in GPU memory and loaded by application. Following functions are available in the API:

**Function**                **Description**
--------------------------- ----------------
`glGenTextures()`           Create texture object
`glTexImage2D()`            Load pixel data into texture object
`glTexSubImage2D()`         Load partial pixel data
`glTexParameter()`          Set parameter
`glBindTexture()`           Switch between multiple texture objects
`glActiveTexture()`         Switch between texture units
`glDeleteTextures()`        Delete texture

Table: OpenGL functions for working with textures

There in limited number of texture units, if the fragment shader needs to work with multiple textures,
each texture needs to be loaded into different texturing unit.

Drawing is started by call to `glDrawArrays()`, then vertex shader is executed per each vertex defined
in currently enabled vertex attribute arrays. Each vertex attribute should be assigned with VBO to load data from.
Then result verticies are rasterized into fragments and fragment shader is executed.

