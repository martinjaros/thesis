# Augmented reality

## Design goals

> Design goals and project overview

## Hardware limitations

Developing an application for an embedded device faces a basic problem, as there are big differences
between these devices it is hard to support the hardware and make the application portable.
In order to reuse code and reduce application size, libraries are generally used.
To provide enough abstraction operating system is used.
There are many kernels specially tailored for embedded applications such as
[FreeRTOS][freertos], [Linux][linux] or proprietary [VxWorks][vxworks], [Windows CE][wince].
Linux kernel has been chosen for this project because of its main advantages:

 - free and open-source, well documented
 - highly configurable and portable
 - highly standardized, POSIX compliant
 - large amount of drivers, good manufacturer support
 - great community support, many tutorials

while having only few disadvantages:

 - very large code base
 - steep learning curve
 - relatively high hardware requirements

While the application is designed to be highly portable depending only on the kernel itself,
several devices has been chosen as the reference, they are listed in the [hardware](#hardware) chapter.

