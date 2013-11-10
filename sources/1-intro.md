# Augmented reality

## Design goals

> Design goals and project overview
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

## Hardware limitations

Developing an application for an embedded device faces a basic problem, as there are big differences
between these devices it is hard to support the hardware and make the application portable.
In order to reuse code and reduce application size, libraries are generally used.
To provide enough abstraction operating system is used.
There are many kernels specially tailored for embedded applications such as
[FreeRTOS][freertos], [Linux][linux] or proprietary [VxWorks][vxworks], [Windows CE][wince].
Linux kernel has been chosen for this project.

**Advantages of the Linux kernel**

 - free and open-source, well documented
 - highly configurable and portable
 - highly standardized, POSIX compliant
 - large amount of drivers, good manufacturer support
 - great community support, many tutorials

**Disadvantages of the Linux kernel**

 - large code base
 - steep learning curve
 - high hardware requirements


While the application is designed to be highly portable depending only on the kernel itself,
several devices has been chosen as the reference.

**[OMAP4460][omap4460] application processor**[^omap4460trm]

 - two ARM Cortex-A9 SMP general-purpose processors
 - IVA 3 video accelerator, 1080p capable
 - image signal processor, 20MP capable
 - SGX540 3D graphics accelerator, OpenGL ES 2.0 compatible
 - HDMI v1.3 video output


**[MPU-9150][mpu9150] motion tracking device**[^mpu9150ps]

 - embedded MPU-6050 3-axis gyroscope and accelerometer
 - embedded AK8975 3-axis digital compass
 - fully programmable, I^2^C interface


**[OV5640][ov5640] image sensor**[^ov5640pb]

 - 1080p, 5MP resolution
 - raw RGB or YUV output


