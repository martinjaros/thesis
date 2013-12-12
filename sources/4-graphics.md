## Graphics subsystem

There is a standardized library for interfacing with graphical accelerators maintained by Khronos group
called OpenGL. Its recent version targeted for embedded systems is OpenGL ES 2.0 [@OpenGLES2],
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

![OpenGL ES shader][shaders]

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

