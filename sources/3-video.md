## Video subsystem

Video support in Linux kernel is maintained by the [LinuxTV][linuxtv] project,
it implements the `videodev2` kernel module and defines the *V4L2* interface.
Modules are part of the mainline kernel at `drivers/media/video/*` with header `linux/videodev2.h`.
The core module is enabled by the `VIDEO_V4L2` configuration option,
specific device drivers should be enabled by their respective options.
V4L2 is the latest revision and is the most widespread video interface throughout Linux,
drives are available from most hardware manufactures and usually mainlined or available as patches.
The [Linux Media Infrastructure API][v4l2api] [@LinuxTV] is a well documented interface shared by all devices.
It provides abstraction layer for various device implementations,
separating the platform details from the applications. Each video device has its device file
and is controlled via *ioctl* calls. For streaming, standard I/O functions are supported,
but the memory mapping is preferred, this allows passing only pointers between the application and the kernel,
instead of unnecessary copying the data around.
Available *ioctl* calls are:

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

Table: V4L2 ioctl calls defined in `linux/videodev2.h`

Application sets the format first, then requests and maps buffers from the kernel.
Buffers are exchanged between the kernel and the application.
When the buffer is enqueued, it will be available for the kernel to capture data to it.
When the buffer is dequeued, kernel will not access the buffer and application may read the data.
After all buffers are enqueued, application starts the stream.
Polling is used to wait for the kernel until it fills the buffer, buffer should not be accessed simultaneously
by the kernel and the application. After processing the buffer, application should return it back to the kernel queue.
Note that buffers should be properly unmapped by the application after stopping the stream.
The video capture process is described in the following diagram.

![V4L2 capture][v4l2capture]

Source code for simple video capture is in [video capture example](#video-capture-example) appendix.
The image format is specified using the little-endian four-character code (FOURCC).
V4L2 defines several formats and provides `v4l2_fourcc()` macro to create a format code from four characters.
As described later in the [graphics subsystem (2.3)](#graphics-subsystem) chapter, graphics uses natively the RGB4 format.
This format is defined as a single plane with one sample per pixel and four bytes per sample.
These bytes represents red, green and blue channel values respectively. Image size is therefore $width \cdot height \cdot 4$ bytes.
Many image sensors however support YUV color-space, for example the YU12 format.
This one is defined as three planes, the first plane with one luminance sample per pixel and the second and third plane with one chroma sample per four pixels
(2 pixels per row, interleaved). Each sample has one byte, this format is also referenced as YUV 4:2:0 and its image size is $width \cdot height \cdot 1.5$ bytes.
The luminance and chroma of a pixel is defined as

$E_Y = W_R \cdot E_R + (1-W_R-W_B) \cdot E_G + W_B \cdot E_B$,

$E_{C_r} = \dfrac {0.5 (E_R - E_Y)} {1 - W_R}$,

$E_{C_b} = \dfrac {0.5 (E_B - E_Y)} {1 - W_B}$,

where *E~R~*, *E~G~*, *E~B~* are normalized color values and *W~R~*, *W~B~* are their weights.
[ITU-R Rec. BT.601][bt601] [@BT601] defines weights as 0.299 and 0.114 respectively,
it also defines how they are quantized

$Y = 219 E_Y + 16$,

$C_r = 224 E_{C_r} + 128$,

$C_b = 224 E_{C_b} + 128$.

To calculate *R*, *G*, *B* values from *Y*, *Cr*, *Cb* values, inverse formulas must be used

$E_Y = \dfrac {Y - 16} {219}$,

$E_{C_r} =  \dfrac {C_r - 128} {224}$,

$E_{C_b} = \dfrac {C_b - 128} {224}$,

$E_R = E_Y + 2 E_{C_r} (1 - W_R)$,

$E_G = E_Y - 2 E_{C_r} \dfrac {W_R - {W_R}^2} {W_G} - 2 E_{C_b} \dfrac {W_B - {W_B}^2} {W_G}$,

$E_B = E_Y + 2 E_{C_b} (1 - W_B)$.

It should be noted that not all devices may use the BT.601 recommendation,
V4L2 refers to it as `V4L2_COLORSPACE_SMPTE170M` in the `VIDIOC_S_FMT` request structure.
Implementation of the YUV to RGB color-space conversion is most efficient on graphics accelerators,
such example is included in [colorspace conversion example](#colorspace-conversion-example) appendix.
It is written in GLSL for fragment processor, see [graphics subsystem (2.3)](#graphics-subsystem) chapter for further description.

There is a kernel module `v4l2loopback` which creates a video loop-back device, similar to network loop-back, allowing piping two video applications together.
This is very useful not only for testing, but also for implementation of intermediate decoders.
[GStreamer][gstreamer] is a powerful multimedia framework widespread in Linux distributions, composed of a core infrastructure and hundreds of plug-ins.
This command will create synthetic RGB4 video stream for the application, useful for testing

`modprobe v4l2loopback`{.bash} \
`gst-launch videotestsrc pattern=solid-color foreground-color=0xE0F0E0 ! \`{.bash} \
`"video/x-raw,format=RGBx,width=800,height=600,framerate=20/1" \`{.bash} \
`! v4l2sink device=/dev/video0`

Texas Instruments distributes a [meta package][tiomap] [@TIOMAP] for their OMAP platform featuring all required modules and DSP firmware.
This includes kernel modules for *SysLink* inter-chip communication library, *Distributed Codec Engine* library and *ducati* plug-in for GStreamer.
With the meta-package installed, it is very easy and efficient to implement mainstream encoded video formats.
For example following command will create GStreamer pipeline to receive video payload over a network socket from an IP camera,
decode it and push it to the loop-back device for the application. MPEG-4 AVC (H.264) decoder of the IVA 3 is used in this example.

`modprobe v4l2loopback`{.bash} \
`gst-launch udpsrc port=5004 caps=\`{.bash} \
`"application/x-rtp,media=video,payload=96,clock-rate=90000,encoding-name=H264" \`{.bash} \
`! rtph264depay ! h264parse ! ducatih264dec ! v4l2sink device=/dev/video0`

On OMAP4460 this would consume only about 15% of the CPU time as the decoding is done by the IVA 3 video accelerator in parallel to the CPU
which only passes pointers around and handles synchronization. Output format is NV12 which is similar to YU12 format described earlier,
but there is only one chroma plane with two-byte samples, first byte being the U channel and the second byte the V channel, sampling is same 4:2:0.
The YUV to RGB color space conversion must take place here, preferably implemented on the GPU as described above.

Cortex-A9 cores on the OMAP4460 also have the NEON co-processor, capable of vector floating point math. Although not very supported by the GCC C compiler,
there are many assembly written libraries implementing coders with the NEON acceleration.
For example the [*libjpeg-turbo*][libjpeg] library is implementing the *libjpeg* interface. It is useful for USB cameras,
as the USB throughput is not high enough for raw high definition video, but is sufficient with JPEG coding (as most USB cameras supports JPEG, but does not support H.264).
1080p JPEG stream decoded with this library via its GStreamer plug-in will consume about 90% of the single CPU core time (note that there are two CPU cores available).
However, comparable to the AVC, JPEG encoding will cause visible quality degradation in the raw stream (video looks grainy).

### Implementation

The subsystem is implemented as a standalone module designed for synchronous operation within the rendering loop.
This implies a constant rendering latency as the multiple of the frame sampling time
and the number of buffers in the kernel-space to user-space queue

$latency = \dfrac{n}{f_s}$.

The minimum number of buffers is 3, however only two buffers are actively used.
The first buffer being used for the drawing in the user-space and the second buffer being used for the capture in the kernel-space.
The third extra buffer is enqueued in the kernel-space to be used after the second buffer is filled
(more than one extra buffer may be used, usually the total number of 4 buffers are used to prevent queue underflow in the case that
the rendering loop momentary lingers).
The implementation uses `select()` to wait for the kernel to fill the current buffer and then rotate the buffers in the queue.
This means that the sampling rate is the maximum value possible for the capture device hardware and the total latency is
$2\,{{f_s}_{max}}^{-1}$. The following options are configured by the implementation

 - width, height
 - format (`"RGB4"`)
 - interlacing

The video subsystem is capable of using multiple capture devices. Two interlaced video streams per device is also possible.
This allows implementation of stereoscopic and multilayer imaging.
The video resolution may differ from screen resolution, but the pixel aspect ratio must match.
