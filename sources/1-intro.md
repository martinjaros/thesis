# Augmented reality

## Project overview

Main goal of this project is to develop a device capable of rendering a real time overlay over the captured video frame.
There are three external inputs, the image sensor capable of video capture feeds real-time images to the system.
The GPS receiver delivers positional information and inertial sensors supplement it with spatial orientation.
Expected setup is that the image and inertial sensors are on a single rack able to freely rotate around,
while the GPS receiver is static, relative to the whole moving platform (vehicle for example).
The overlay consists of fixed kinematic data such as speed or altitude, reference indicators such a horizon line and dynamic location markers.
These will be spatially aligned with real locations visible in the video thus providing navigation information.
They work in a way that wherever the camera is pointed to, specific landmarks will label currently visible locations.
Complex external navigation system may be also connected. This allows integration with already existing systems,
such as moving map systems, PDAs or other specialized hardware.
These provides user with classic route navigation and map projection, while this project gives spatial extension to further improve total situational awareness.
The analogy are the head up and head down displays, each delivering specific set of information.
This project focuses on visual enhancement instead of a full featured navigation device.
Overview on of the project design is in the following figure.

![Project overview][overview]

## Hardware limitations

Application is designed to run in embedded environments, where power management is very important.
While many platforms features multiple symmetrical processor cores - CPUs,
application should focus on lowest per-core usage as possible.
This can be done by delegating specific tasks to specialized hardware.
CPU is specialized in execution of single thread, integer and bitwise operations, with many branches in its code.
With vector and floating point extensions they are also very efficient in computation of difficult mathematical algorithms.
However they do not perform well in simple calculations over large amounts of data, where mass parallelization is possible.
This is the case in graphics where special graphics processors - GPUs have been deployed.
GPU consists of high number (hundreds) of simple cores, which are able to perform operations over large blocks of data.
They scale efficiently with the amount of data needed to be processed due to parallelization,
however they have problems with nonlinear code with branches.
While CPUs have long pipelines for branch optimizations, GPUs cannot employ those,
any branch in their code will be extremely inefficient and should be avoided.
[Chapter 2.3](#graphics-subsystem) focuses on this area.
There are also available specialized subsystems designed and optimized for a single purpose.
For example video accelerators, capable of video encoding and decoding, image capture systems or peripheral drivers.
They will be mentioned in specific chapters.

Developing an application for an embedded device faces a problem, as there are big differences
between these devices it is hard to support the hardware and make the application portable.
In order to reuse code and reduce application size, libraries are generally used to create an intermediary layer
between application and the hardware. However, to provide enough abstraction some sort of operating system has to be used.
Operating systems may be real-time, giving applications full control, behaving just like large libraries.
This is favorable approach in embedded systems as it allows precise timings.
There are many such systems specially tailored for embedded applications like
[FreeRTOS][freertos] [@FreeRTOS] or proprietary [VxWorks][vxworks] [@VxWorks]. On the other hand, as recent processors improved greatly in power,
efficiency and capabilities, it is possible and quite feasible to run a full featured system like [Linux][linux] or proprietary [Windows CE][wince] [@WinCE].
Linux kernel is highly portable and configurable, although it does restrict applications from real-time use (Linux RT patches also exist for real-time applications),
as all hardware dependent modules which requires full control over the hardware are part of the kernel itself, application does not need to run in real-time at all.
Other advantages are free, open and well documented sources, highly standardized and POSIX compliant application interface, large amount of drivers with good manufacturer support.
While its disadvantages are very large code base and steep learning curve, which may slow the initial development.
Nevertheless Linux kernel has been chosen for the project, more details about its interfaces are in the [chapter 2.1](#linux-kernel).
While the application is designed to be highly portable depending only on the kernel itself,
several devices has been chosen as the reference, they are listed in the [chapter 3](#hardware).

