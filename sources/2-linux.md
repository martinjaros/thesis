# Application

## Linux kernel

Programs running in Linux are divided into two groups, kernel-space and user-space.
Only kernel and its runtime modules are allowed to execute in kernel-space,
they have physical memory access and use CPU in real-time.
All other programs runs as processes in user-space, they have virtual memory access,
which means their memory addresses are translated to the physical addresses in the background.
In Linux each process runs in a sandbox, isolated from the rest of the system.
Processes access memory unique to them, they cannot access memory assigned for other processes
nor memory managed by the kernel. They may communicate with the outside environment by several means:

 - Arguments and environment variables
 - Standard input, output and error output
 - Virtual File System
 - Signals
 - Sockets
 - Memory mapping

Each process is ran with several arguments in a specific environment with three default file descriptors.
For example running

`VARIABLE=value ./executable argument1 argument2 <input 1>output 2>error`{.bash}

will execute `executable` with environment variable `VARIABLE` of value `value` with two arguments `argument1` and `argument2`.
Standard input will be read from file `input` while regular output will be written to file `output` and error output to file `error`.
This process may further communicate by accessing files in the Virtual File System, kernel may expose useful process information
for example via `procfs` file-system usually mounted at `/proc`.
Other types of communication are signals (which may be sent between processes or by kernel) and network sockets.
With internal network loop-back device, network style inter process communication is possible using standard protocols (UDP, TCP, ...).
Memory mapping is a way to request access to some part of the physical memory.

Process execution is not real-time, but they are assigned restricted processor time by the kernel.
They may run in numerous threads, each thread has preemptively scheduled execution.
Threads share memory within a process, memory access to these shared resources must done
with care to avoid race conditions and data corruption. Kernel provides *mutex* objects to lock
threads and avoid simultaneous memory access. Each shared resource should be attached to a *mutex*,
which is locked during access to this resource. Thread must not lock *mutex* while still holding lock
to this or any other *mutex* in order to avoid dead-locking. Source example on how to use threads is in the
[appendix A](#appendixa).

Linux kernel has monolithic structure, so all device drivers resides in the kernel-space.
From application point of view, this means that all peripheral access must be done
through the standard library and Virtual File System.
Individual devices are accessible as device files defined by major and minor number typically located at `/dev`.
These files could be created automatically by kernel (`devtmpfs` file-system), by daemon ([`udev(8)`][udev])),
or manually by [`mknod(1)`][mknod].
Complete kernel device model is exported as `sysfs` file-system and typically mounted at `/sys`.

**Function name**                       **Access type**  **Typical usage**
--------------------------------------- ---------------- ------------------
[`select()`][select], [`poll()`][poll]  event            Synchronization, multiplexing, event handling
[`ioctl()`][ioctl]                      structure        Configuration, register access
[`read()`][read], [`write()`][write]    stream           Raw data buffers, byte streams
[`mmap()`][mmap]                        block            High throughput data transfers

Table: Available functions for working with device file descriptors

For example let's assume a generic peripheral device connected by the I^2^C bus.
First, to tell kernel there is such a device, the `sysfs` file-system may be used

`echo $DEVICE_NAME $DEVICE_ADDRESS > /sys/bus/i2c/devices/i2c-1/new_device`{.bash}

This should create a special file in `/dev`, which should be opened by [`open()`][open] to get a file descriptor for this device.
Device driver may export some *ioctl* requests, each request is defined by a number and a structure passed between the application and the kernel.
Driver should define requests for controlling the device, maybe accessing its internal registers and configuring a data stream.
Each request is called by

`ioctl(fd, REQNUM, &data);`{.c}

where `fd` is the file descriptor, `REQNUM` is the request number defined in the driver header and `data` is the structure passed to the kernel.
This request will be synchronously processed by the kernel and the result stored in the `data` structure.
Let's assume this devices has been configured to stream an integer value every second to the application.
To synchronize with this timing application may use

`struct pollfd fds = {fd, POLLIN};`{.c} \
`poll(&fds, 1, -1);`{.c}

which will block infinitely until there is a value ready to be read. To actually read it,

`int buffer[1];`{.c} \
`ssize_t num = read(fd, buffer, sizeof(buffer));`{.c}

will copy this value to the buffer. Copying causes performance issues if there are very large amounts of data.
To access this data directly without copying them, application has to map physical memory used by the driver.
This allows for example direct access to a DMA channel, it should be noted that this memory may still be needed by kernel,
so there should be some kind of dynamic access restriction, possibly via *ioctl* requests (this would be driver specific).

