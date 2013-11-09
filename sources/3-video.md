## Video subsystem

Video support in Linux kernel is maintained by the LinuxTV[^linuxtv] project,
it implements the *videodev2* kernel module and defines the *V4L2* interface.
Modules are part of the mainline kernel at `drivers/media/video/*` with header `linux/videodev2.h`.
The core module is enabled by the *VIDEO_V4L2* configuration option,
specific device drivers should be enabled by their respective options.
*V4L2* is the latest revision and is the most widespread video interface throughout Linux,
drives are available from most hardware manufactures and usually mainlined or available as patches.
The Linux Media Infrastructure API[^v4l2api] is a well documented interface shared by all devices.
It provides abstraction layer for various device implementations,
separating the platform details from the applications. Each video device has its device file
and is controlled via *ioctl* calls. For streaming standard I/O functions are supported,
but the memory mapping is preferred, this allows passing only pointers between the application and the kernel,
instead of unnecessary copying the data around.

**Name**                       **Description**
------------------------------ ----------------
[VIDIOC_QUERYCAP][querycap]    Query device capabilities
[VIDIOC_G_FMT][gfmt]           Get the data format
[VIDIOC_S_FMT][gfmt]           Set the data format
[VIDIOC_REQBUFS][reqbufs]      Initiate memory mapping
[VIDIOC_QUERYBUF][querybuf]    Query the status of a buffer
[VIDIOC_QBUF][qbuf]            Enqueue buffer to the kernel
[VIDEOC_DQBUF][qbuf]           Dequeue buffer from the kernel
[VIDIOC_STREAMON][streamon]    Start streaming
[VIDIOC_STREAMOFF][streamon]   Stop streaming

Table: ioctl calls defined in `linux/videodev2.h`

Application sets the format first, then requests and maps buffers from the kernel.
Buffers are exchanged between the kernel and the application.
When the buffer is enqueued, it will be available for the kernel to capture data to it.
When the buffer is dequeued, kernel will not access the buffer and application may read the data.
After all buffer are enqueued application starts the stream.
Polling is used to wait for the kernel until it fills the buffer, buffer should not be accessed simultaneously
by the kernel and the application. After processing the buffer, application should return it back to the kernel queue.
Note that buffers should be properly unmapped by the application after stopping the stream.

![V4L2 capture][v4l2capture]

**Source example for simple video capture**

~~~{.c .numberLines}
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

int main()
{
    // Open device
    int fd = open("/dev/video0", O_RDWR | O_NONBLOCK);

    // Set video format
    struct v4l2_format format =
    {
        .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
        .fmt =
        {
            .pix =
            {
                .width = 320,
                .height = 240,
                .pixelformat = V4L2_PIX_FMT_RGB32,
                .field = V4L2_FIELD_NONE,
            },
        },
    };
    ioctl(fd, VIDIOC_S_FMT, &format);

    // Request buffers
    struct v4l2_requestbuffers requestbuffers =
    {
        .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
        .memory = V4L2_MEMORY_MMAP,
        .count = 4,
    };
    ioctl(fd, VIDIOC_REQBUFS, &requestbuffers);
    void *pbuffers[requestbuffers.count];

    // Map and enqueue buffers
    int i;
    for(i = 0; i < requestbuffers.count; i++)
    {
        struct v4l2_buffer buffer = 
        {
            .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
            .memory = V4L2_MEMORY_MMAP,
            .index = i,
        };
        ioctl(fd, VIDIOC_QUERYBUF, &buffer);
        pbuffers[i] = mmap(NULL, buffer.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, buffer.m.offset);
        ioctl(fd, VIDIOC_QBUF, &buffer);
    }

    // Start stream
    enum v4l2_buf_type buf_type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(fd, VIDIOC_STREAMON, &buf_type);

    while(1)
    {
        // Synchronize
        struct pollfd fds = 
        {
            .fd = fd,
            .events = POLLIN
        };
        poll(&fds, 1, -1);

        // Dump buffer to stdout
        struct v4l2_buffer buffer = 
        {
            .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
            .memory = V4L2_MEMORY_MMAP,
        };
        ioctl(fd, VIDIOC_DQBUF, &buffer);
        write(1, pbuffers[buffer.index], buffer.bytesused);
        ioctl(fd, VIDIOC_QBUF, &buffer);
    }
}
~~~
<!-- -->

The image format is specified using the little-endian four-character code (FOURCC).
V4L2 defines several formats and provides `v4l2_fourcc()` macro to create a format code from four characters.
As described later in the [graphics subsystem](#graphics-subsystem) chapter, graphics uses natively the *RGB4* format.
This format is defined as a single plane with one sample per pixel and four bytes per sample.
These bytes represents red, green and blue channel values respectively. Image size is therefore $width \cdot height \cdot 4$ bytes.
Many image sensors however support *YUV* color-space, for example the *YU12* format.
This one is defined as three planes, the first plane with one luminance sample per pixel and the second and third plane with one chroma sample per four pixels
(2 pixels per row, interleaved). Each sample has one byte, this format is also referenced as *YUV 4:2:0* and its image size is $width \cdot height \cdot 1.5$ bytes.
The luminance and chroma of a pixel is defined as

(@ey) $E_Y = W_R \cdot E_R + (1-W_R-W_B) \cdot E_G + W_B \cdot E_B$

(@ecr) $E_{C_r} = \frac {0.5 (E_R - E_Y)} {1 - W_R}$

(@ecb) $E_{C_b} = \frac {0.5 (E_B - E_Y)} {1 - W_B}$

where E~R~, E~G~, E~B~ are normalized color values and W~R~, W~B~ are their weights.
ITU-R Rec. BT.601[^bt601] defines weights as 0.299 and 0.114 respectively,
it also defines how they are quantized

(@y) $Y = 219 E_Y + 16$

(@cr) $C_r = 224 E_{C_r} + 128$

(@cb) $C_b = 224 E_{C_b} + 128$

To calculate R, G, B values from Y, Cr, Cb values, inverse formulas must be used

(@eyinv) $E_Y = \frac {Y - 16} {219}$

(@ecrinv) $E_{C_r} =  \frac {C_r - 128} {224}$

(@ecbinv) $E_{C_b} = \frac {C_b - 128} {224}$

(@erinv) $E_R = E_Y + 2 E_{C_r} (1 - W_R)$

(@eginv) $E_G = E_Y - 2 E_{C_r} \frac {W_R - {W_R}^2} {W_G} - 2 E_{C_b} \frac {W_B - {W_B}^2} {W_G}$

(@ebinv) $E_B = E_Y + 2 E_{C_b} (1 - W_B)$

**GLSL implementation of the YUV to RGB conversion** (see [graphics subsystem](#graphics-subsystem) chapter for description of GLSL)

~~~{.c .numberLines}
uniform sampler2D texY, texU, texV;
varying vec2 texPos;

void main()
{
    float y = texture2D(texY, texPos).a * 1.1644 - 0.062745;
    float u = texture2D(texU, texPos / 2).a - 0.5;
    float v = texture2D(texV, texPos / 2).a - 0.5;

    gl_FragColor = vec4(
        y + 1.596 * v,
        y - 0.39176 * v - 0.81297 * u,
        y + 2.0172 * u,
        1.0);
}
~~~

> v4l2 loopback, H.264 decode
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\
\

