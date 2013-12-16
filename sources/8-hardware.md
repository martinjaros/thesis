# Hardware

![Proposed hardware][hardware]

The diagram above specifies the proposed platform realization.
The [OMAP4460][omap4460] [@OMAP4460] application processor was chosen for the project,
it features two ARM Cortex-A9 general-purpose CPUs and many specialized subsystems and peripherals.
Internal image co-processor allows direct connection of image sensor via its serial interface,
for example the [OV5640][ov5640].
For graphic acceleration, there is the SGX540 GPU, HDMI v1.3 video output is available.
The [MPU-9150][mpu9150] [@MPU9150] is a motion tracking device composed of
MPU-6050 3-axis gyroscope and accelerometer and AK8975 3-axis digital compass.
It comes with a I^2^C interface.
TWL6032 is the power companion chip designed specifically for the OMAP platform,
handling power path switching, and DC-DC voltage conversion.
It can manage Li-ion battery as well as charging with extern power adapter or USB line.
RS-232 connection is needed for external satellite navigation system as defined in NMEA 0183 specification,
it should be connected to the UART via voltage level converter such as MAX232.
USB device port allows connection to the external host, providing extra power source and generic data interface.
Ethernet or mass storage gadget may be implemented over the USB device port.
The embedded IVA 3 hardware video accelerator in the OMAP4460 is capable of encoding and decoding video streams simultaneously,
without any load on the ARM cores, this allows media streaming through the USB port (possibly over IP network).
External IP camera may also be connected. Additionally a USB host port may also be implemented for external camera connection.

There are also many development boards already available for generic testing.
The [Pandaboard ES][pandaboard] [@Pandaboard] features the OMAP4460 and provides all peripheral interfaces.
There is also a low price board the [BeagleBone Black][bbb] [@BBBlack] with a Sitara AM3358,
while being much simpler, however most of the features needed are still available.
Texas Instruments also distributes the [Sensor Hub BoosterPack][senshub] [@SensorHub] with all needed sensors.

Application may also be fully emulated on PC in Linux environment.
OpenGL ES 2.0 should run under Mesa3D natively.
For video interface, GStreamer may be used together with the *v4l2loopback* module.
Though serial interfaces needs to be emulated manually.

