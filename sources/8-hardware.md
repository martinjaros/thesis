# Hardware

![Proposed hardware solution][hardware]

The diagram above specifies the proposed platform realization.
The Texas Instruments [OMAP4460][omap4460] [@OMAP4460] application processor was chosen for the project,
however the portable nature of the application does not make this a requirement.
For example the AM335x family of processors was tested and works as well.

To provide flexible power supply a specialized chip such as the TWL6032 power companion for the OMAP platform should be used to

 * DC-DC voltage conversion and power routing
 * battery supply, battery charging
 * automatic switch between external power and battery
 * USB power with maximum current negotiation and limiting

Total power consumption should be below 3 Watts, depending on peripherals (without display).
The power solution should seamlessly switch between power sources to provide enough power and use external supply whenever possible.

The OMAP4 platform features two SMP ARM Cortex-A9 general-purpose CPUs with NEON vector floating point accelerator.
Application makes use of the SMP to distribute processing power between its subsystem threads.
The NEON SIMD extensions allows efficient implementation of the JPEG compression algorithm,
the performance scales up to the full HD resolution.
For more complex coders such as the MPEG4 AVC / H.264, there is a specialized IVA subsystem embedded in the OMAP4 platform.
It consists of two Cortex-M3 cores for real-time computations and a video accelerator unit,
the subsystem is capable of simultaneous real-time encoding and decoding of the video at full HD resolution.

Application has a flexible input video support, there are many possible solution for hardware implementation as
virtually any device supported by the Linux kernel should work.
The most straightforward implementation would be direct connection to the camera chip,
for this purpose there are two CSI-2 interfaces on the OMAP4 platform as a port of the embedded imaging subsystem (ISS).

The [MIPI CSI-2][mipi] [@MIPICSI2] interface is the standard serial camera interface,
consisting of clock and pixel data differential lines as shown in the diagram below.

![CSI interface][csi]

The pixel data are transmitted synchronously, there is also usually an I2C control interface.
The ISS on the OMAP side features an image signal processor capable of auto focus, auto exposure, and auto white balance computations.
The data throughput of the subsystem scales up to 200 MPix/s.
There are many supported image sensors such as the Omnivision [OV5640][ov5640], it has 5MP resolution with 1080p RGB output at 30 FPS.

External video sources are also supported, they may connect by either USB or Ethernet 
USB Video Class (UVC) driver is a part of the Linux kernel V4L2 module and works with almost any UVC device, USB devices are self descriptive.
USB ports does not have enough throughput for raw video at HD resolutions, so most cameras usually uses MJPEG compression,
USB cable length is also limited to few meters.
UVC devices features their own image processors and are configured via the USB interface by the UVC driver.

Ethernet connection is the most flexible solution, however also the most complicated,
it is supported only by high end cameras and does not have standardized control interface.
Control is usually provided via a micro HTTP server on the camera side,
video is usually streamed encapsulated in Real-time Transport Protocol (RTP) packets over the UDP socket.
The typical encapsulation process consists of MPEG4 AVC / H.264 encoder, RTP payloader and UDP / IP layers.
On the receiver side there is the RTP jitter buffer, RTP de-payloader and AVC decoder.
The best way to implement this pipeline is to use the GStreamer utility, it also supports the IVA accelerator for decoding.
On the physical layer there is no direct interface on the OMAP4 platform, either MAC-PHY or WiFi chips must be used.
Using the WiFi radio is probably the most sophisticated way of video input as it leaves the system physically isolated from the video input device.

For graphic acceleration the application fully depends on the embedded GPU, which is usually platform dependent.
There is the PoverVR SGX540 chip integrated within the OMAP4 platform supporting the OpenGL ES 2.0 framework,
any other accelerator with the same OpenGL framework and with kernel support will work.
The video is fed to the display sub-system which features an overlay manager and an integrated HDMI v1.3 output
compatible with most modern displays.
The video output may also be streamed via Ethernet in a similar way as the video input, however this is again a more complex solution.

The navigation peripherals consists of the serial interface for the NMEA 0183 protocol and the I2C interface for the IIO module.
Serial connection may be done via UART port with voltage level converter such as MAX232 which provides RS-232 compatible interface.
It consists of duplex asynchronous receive and transmit lines, and the ground line as shown in the diagram bellow.

![UART interface][uart]

Another option is the use of the USB Comunication Device Class (USB-CDC) driver which will bridge the serial line over the USB,
using UDP sockets over the Ethernet is also a possibility.

The inertial sensors are connected via the I^2^C bus, it is a master-slave synchronous bus consisting of clock and data lines, and the ground line.
The I^2^C protocol allows multiple devices to be interconnected, it supports addressing and arbitration.
The communication is simplex and is controlled and clocked by the master, each slave have a fixed address to which it responds as shown in the diagram below.

![I^2^C interface][i2c]

The I^2^C interface is typically used to directly read or write registers of the interconnected devices,
each device must have a device driver in the Linux kernel for abstraction.

The Invensense [MPU-9150][mpu9150] [@MPU9150] is an all-in-one motion tracking device composed of an embedded
MPU-6050 3-axis gyroscope and accelerometer and a AK8975 3-axis digital compass.
Many other individual devices are supported by the kernel IIO tree, such as Freescale MPL3115 barometer, Invensense ITG-3200 gyroscope or BMA180 accelerometer.

There are many development boards already available for generic testing.
The [Pandaboard ES][pandaboard] [@Pandaboard] features the OMAP4460 and provides all peripheral interfaces.
There is also a low price board the [BeagleBone Black][bbb] [@BBBlack] with a Sitara AM3358 processor.
Texas Instruments also distributes the [Sensor Hub BoosterPack][senshub] [@SensorHub] with all needed sensors.

Application may also be fully emulated on the PC in the Linux environment.
OpenGL ES 2.0 should run natively under Mesa3D library.
For video interface, GStreamer may be used together with the *v4l2loopback* module.
Though serial interfaces needs to be emulated manually.

