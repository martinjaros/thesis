## Inertial measurement subsystem

Application needs to know its spatial orientation for rendering, there three devices which may provide such information,
gyroscope, compass (magnetometer) and accelerometer. Hardware details about these devices are in the [hardware](#hardware) chapter.

### Industrial I/O module

A relatively young kernel module `iio` has been implemented in recent kernels to provide standardized support
for sensors and analog converters typically connected by I^2^C bus. While many device drivers are still
in staging tree, to core module is ready for production code. Subsystem provides device structure mapped in `sysfs`,
typically available at `/sys/bus/iio/devices/`. Device are implemented usually on top of the `i2c-dev` driver and registered as
`/sys/bus/iio/devices/iio:deviceX`, where X is the device number and the device name may be obtained by

`cat /sys/bus/iio/devices/iio:deviceX/name`{.bash}

There are many possible channels, named by the value type they represents.
To read an immediate value, for example from an ADC channel 1

`cat /sys/bus/iio/devices/iio:deviceX/in_voltage1_raw`{.bash} \
`cat /sys/bus/iio/devices/iio:deviceX/in_voltage_scale`{.bash}

where the result value in volts is $raw \cdot scale$.
However, being easy, this is not efficient,
buffers have been implemented to stream measured data to the application.
Buffer uses device file named after the `iio` device, e.g. `/dev/iio:deviceX`.
To stream data through the buffer, driver needs to have control over the timing,
triggers have been implemented for this purpose. They are accessible as `/sys/bus/iio/devices/triggerX`,
where X is the trigger number and its name may be obtained by

`cat /sys/bus/iio/devices/triggerX/name`{.bash}

Software trigger may be created by

`echo 1 > /sys/bus/iio/iio_sysfs_trigger/add_trigger`{.bash}

and triggered by application 

`echo 1 > /sys/bus/iio/trigger0/trigger_now`{.bash}

Name of this trigger is `sysfstrigX`, where X is the trigger number.
Hardware triggers are also implemented, both GPIO and timer based triggers.
Devices may implement triggers themselves, providing for example the data ready trigger.
Device triggers are generally named as `name-devX`, where `name` is device name and `X` is device number.
To use trigger with the buffer use

`echo "triggername" > /sys/bus/iio/devices/iio:deviceX/trigger/current_trigger`{.bash}

where `triggername` is the name of the trigger, for example `adc-dev0` will be the device trigger for the ADC.
Data are measured in specific channels, they are defined in `/sys/bus/iio/devices/iio:device0/scan_elements`.
Channels must be enabled for buffering individually, for example

`echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage1_en`{.bash} \
`echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage2_en`{.bash}

will enable ADC channels 1 and 2. Buffer itself can be started by

`echo 256 > /sys/bus/iio/devices/iio:deviceX/buffer/length`{.bash} \
`echo 1 > /sys/bus/iio/devices/iio:deviceX/buffer/enabled`{.bash}

this will start streaming data to the device file. Data are formatted in packets,
each packed consists of per-channel values and is terminated by 8 byte time-stamp of the sample.
Order of the channels in the buffer can be obtained by

`cat /sys/bus/iio/devices/iio:device0/scan_elements/in_voltageX_index`{.bash}

which reads index of the specified channel. Data format of this channel is

`cat /sys/bus/iio/devices/iio:device0/scan_elements/in_voltageX_type`{.bash}

which reads encoded string, for example `le:u10/16>>0`,
where `le` means little-endian, `u` means unsigned, `10` is the number of relevant bits while `16` is the number of actual bits
and `0` is the number of right shifts needed.

Following channels are needed by the application:

- `anglvel_x`
- `anglvel_y`
- `anglvel_z`
- `accel_x`
- `accel_y`
- `accel_z`
- `magn_x`
- `magn_y`
- `magn_z`

representing measurements from gyroscope, accelerometer and magnetometer respectively.

### DCM algorithm

Gyroscope measures angular speed around device axes, it offers high differential precision and fast sampling rate,
however it suffers slight zero offset error. Device attitude can be obtained simply by integrating measured angular rates,
provided that initial attitude is known. The angular rate is defined as

$\overrightarrow{\omega_g} = \frac{\mathrm{d}}{\mathrm{d}t} \overrightarrow{\Phi}_{(t)}$,

so the angular displacement between last two samples is

$\left [\Phi_x, \Phi_y, \Phi_z \right ] = \left [ \omega_x, \omega_y, \omega_z \right ] \cdot _\Delta t$.

This can be described as a rotation

$\mathbf{R}_{gyro} =
\begin{bmatrix}
1 & 0 & 0 \\ 
0 & \cos(\Phi_x) & -\sin(\Phi_x) \\ 
0 & \sin(\Phi_x) & \cos(\Phi_x)
\end{bmatrix}
\times
\begin{bmatrix}
\cos(\Phi_y) & 0 & \sin(\Phi_y) \\ 
0 & 1 & 0 \\ 
-\sin(\Phi_y) & 0 & \cos(\Phi_y)
\end{bmatrix}
\times
\begin{bmatrix}
\cos(\Phi_z) & -\sin(\Phi_y) & 0 \\ 
\sin(\Phi_y) & \cos(\Phi_y) & 0 \\ 
0 & 0 & 1
\end{bmatrix}$.

With $_\Delta t$ close to zero a small-angle approximation may be used to simplify $\cos(x)=1$, $\sin(x)=x$

$\mathbf{R}_{gyro} \doteq
\begin{bmatrix} 1 & - \Phi_z & \Phi_y \\
\Phi_x \Phi_y + \Phi_z & 1 - \Phi_x \Phi_y \Phi_z & - \Phi_x \\
\Phi_x \Phi_z - \Phi_y & \Phi_x + \Phi_y \Phi_z & 1 \end{bmatrix}$.

Let's define the directional cosine matrix describing device attitude

$\mathbf{DCM} = \begin{bmatrix}
\widehat{\mathbf{I}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{I}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{I}}\cdot \widehat{\mathbf{z}} \\
\widehat{\mathbf{J}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{J}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{J}}\cdot \widehat{\mathbf{z}} \\ 
\widehat{\mathbf{K}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{K}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{K}}\cdot \widehat{\mathbf{z}}
\end{bmatrix} = \begin{bmatrix} \widehat{\mathbf{I}}_{xyz} \\ \widehat{\mathbf{J}}_{xyz} \\ \widehat{\mathbf{K}}_{xyz} \end{bmatrix}$,

where $\widehat{\mathbf{I}}$ points to the north, $\widehat{\mathbf{J}}$ points to the east, $\widehat{\mathbf{K}}$ points to the ground
and therefore $\widehat{\mathbf{I}} = \widehat{\mathbf{J}} \times \widehat{\mathbf{K}}$.
Roll, pitch and yaw angels in this matrix are

$\gamma = - \arctan_2 \left ( \dfrac {\mathbf{DCM}_{23}}{\mathbf{DCM}_{33}} \right )$,

$\beta = \arcsin (\mathbf{DCM}_{13})$,

$\alpha = - \arctan_2 \left ( \dfrac {\mathbf{DCM}_{12}}{\mathbf{DCM}_{11}} \right )$.

DCM can be computed by applying consecutive rotations over time

$\mathbf{DCM}_{(t)}  =  \mathbf{R}_{gyro(t)} \times \mathbf{DCM}_{(t-1)}$.

If the sampling rate is high enough (over 1kHz at least), this method is very accurate and has
good dynamics over short periods of time, but in longer runs errors integrated during processing will cause serious drift
(both numerical errors and zero offset errors). To mitigate these problems accelerometer and compass has to be used to provide the initial
attitude and to fix the drift over time. Accelerometer measures external mechanical forces applied to the device together with gravitational force.
However precision of these devices are generally worse and they have slower sampling rates.
If there are no extern forces, it will measure the gravitational vector directly, thus providing the third row of the DCM

$\overrightarrow{\mathbf{a}}_{acc} = g~ \widehat{\mathbf{K}}_{xyz} + \dfrac{\overrightarrow{\mathbf{F}}}{m}$,

$\overrightarrow{\mathbf{F}} = 0 ~\rightarrow~ \widehat{\mathbf{K}}_{xyz} = 
\dfrac {\overrightarrow{\mathbf{a}}_{acc}} {\left | \overrightarrow{\mathbf{a}}_{acc} \right |}$.

When there is an external force $\overrightarrow{\mathbf{F}}$ applied, 
which is not parallel and has significant magnitude relative to gravitational force $m\,g\,\widehat{\mathbf{K}}_{xyz}$,
measurements will degrade rapidly reaching singularity during the free fall ($\left | \overrightarrow{\mathbf{a}}_{acc} \right | = 0$).
This error may be corrected by using device speed measured by satellite navigation system with high sample rate (over 10Hz)

$\widehat{\mathbf{K}}_{xyz} = \dfrac {\overrightarrow{\mathbf{a}}_{acc} - \frac{\mathrm{d}}{\mathrm{d}t} {\overrightarrow{\mathbf{v}}_{GPS}}} {g}$.

Magnetometer has similar properties, it measures magnetic flux density of the field the device is within.
This should ideally result in a vector pointing to the north, therefore providing the first row of the DCM

$\widehat{\mathbf{I}}_{xyz} = \dfrac {\overrightarrow{\mathbf{B}}_{corr}} {\left | \overrightarrow{\mathbf{B}}_{corr} \right |}$.

Magnetometers have even slower sampling rates and far worse precision as the Earth field is distorted by nearby metal objects.
This magnetic deviation can be divided into hard-iron and soft-iron effects.
Hard-iron distortion is caused by materials that produces magnetic field, that is added to the Earth magnetic field.
Vector of this field can be subtracted to compensate this error

$\overrightarrow{\mathbf{B}}_{corr1} = \overrightarrow{\mathbf{B}}_{mag} - \frac{1}{2} \left [ \min(B_x) + \max(B_x), \min(B_y) + \max(B_y), \min(B_z) + \max(B_z) \right ]$.

The soft-iron distortion is caused by soft magnetic materials, which reshapes the field in a way that is not simply additive.
It may be observed as an ellipse when the device is rotated around and the measured values are plotted.
Compensating for these effects is involves remapping this ellipse back to the sphere.
This is computation intensive and as soft-iron effects are usually weak (up to few degrees), it may be omitted.

Further more the magnetic field of the Earth itself does not point to the geographic north, but is rotated by an angle specific to the location on the Earth surface.
Magnetic inclination is the vertical portion of this rotation causing magnetic vector to incline to the ground,
it may be fixed by using measurements from the accelerometer to make the magnetic vector perpendicular to the gravitational vector

$\overrightarrow{\mathbf{B}}_{corr2} = \widehat{\mathbf{K}}_{xyz} \times \overrightarrow{\mathbf{B}}_{mag} \times \widehat{\mathbf{K}}_{xyz}$.

Magnetic declination (sometimes referred as magnetic variation) is the horizontal portion of this rotation and is sometimes provided by the satellite navigation systems.
To correct for this error, measured values have to be rotated by the inverse angle

$\overrightarrow{\mathbf{B}}_{corr3} = \overrightarrow{\mathbf{B}}_{mag} \begin{bmatrix} \cos(var) & \sin(var) \\ - \sin(var) & \cos(var) \end{bmatrix}$.

By combination of the corrected results from accelerometer and magnetometer complete DCM can be calculated.
Weighted average should be used, in real-time this yields

$\mathbf{DCM}_{(t)}  =  W_{gyro}~ (\mathbf{R}_{gyro} \times \mathbf{DCM}_{(t-1)}) +
(1 - W_{gyro}) \begin{bmatrix} \widehat{\mathbf{I}}_{xyz} \\ \widehat{\mathbf{K}}_{xyz} \times \widehat{\mathbf{I}}_{xyz} \\ \widehat{\mathbf{K}}_{xyz} \end{bmatrix}$,

where $\widehat{\mathbf{I}}_{xyz}$ and $\widehat{\mathbf{K}}_{xyz}$ are calculated from magnetometer and accelerometer measurements.
*W~gyro~* is the weight of the gyroscope measurement, it must be estimated by trial and error to mitigate its drift but not add too much noise.

