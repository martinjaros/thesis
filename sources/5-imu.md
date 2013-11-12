## Inertial measurement subsystem

Application needs to know its spatial orientation for rendering, there three devices which may provide such information,
gyroscope, compass (magnetometer) and accelerometer. Hardware details about these devices are in the [hardware](#hardware) chapter.

### Industrial I/O module

> Industrial I/O module

### DCM algorithm

Gyroscope measures angular speed around device axes, it offers high differential precision and fast sampling rate,
however it suffers slight zero offset error. Device attitude can be obtained simply by integrating measured angular rates,
provided that initial attitude is known. The angular rate is defined as

(@anglrate) $\overrightarrow{\omega_g} = \frac{\mathrm{d}}{\mathrm{d}t} \overrightarrow{\Phi}_{(t)}$

so the angular displacement between last two samples is

(@angldisp) $\left [\Phi_x, \Phi_y, \Phi_z \right ] = \left [ \omega_x, \omega_y, \omega_z \right ] \cdot _\Delta t$

This can be described as a rotation

(@rotmat) $\mathbf{R}_{gyro} =
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
\end{bmatrix}$

With $_\Delta t$ close to zero a small-angle approximation may be used to simplify $\cos(x)=1$, $\sin(x)=x$

(@rotmatsimp) $\mathbf{R}_{gyro} \doteq
\begin{bmatrix} 1 & - \Phi_z & \Phi_y \\
\Phi_x \Phi_y + \Phi_z & 1 - \Phi_x \Phi_y \Phi_z & - \Phi_x \\
\Phi_x \Phi_z - \Phi_y & \Phi_x + \Phi_y \Phi_z & 1 \end{bmatrix}$

Let's define the directional cosine matrix describing device attitude

(@dcm1) $\mathbf{DCM} = \begin{bmatrix}
\widehat{\mathbf{I}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{I}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{I}}\cdot \widehat{\mathbf{z}} \\
\widehat{\mathbf{J}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{J}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{J}}\cdot \widehat{\mathbf{z}} \\ 
\widehat{\mathbf{K}}\cdot \widehat{\mathbf{x}} & \widehat{\mathbf{K}}\cdot \widehat{\mathbf{y}} & \widehat{\mathbf{K}}\cdot \widehat{\mathbf{z}}
\end{bmatrix} = \begin{bmatrix} \widehat{\mathbf{I}}_{xyz} \\ \widehat{\mathbf{J}}_{xyz} \\ \widehat{\mathbf{K}}_{xyz} \end{bmatrix}$

where $\widehat{\mathbf{I}}$ points to the north, $\widehat{\mathbf{J}}$ points to the east, $\widehat{\mathbf{K}}$ points to the ground
and therefore $\widehat{\mathbf{I}} = \widehat{\mathbf{J}} \times \widehat{\mathbf{K}}$.
Roll, pitch and yaw angels in this matrix are

(@gamma) $\gamma = - \arctan_2 \left ( \dfrac {\mathbf{DCM}_{23}}{\mathbf{DCM}_{33}} \right )$

(@beta) $\beta = \arcsin (\mathbf{DCM}_{13})$

(@alpha) $\alpha = - \arctan_2 \left ( \dfrac {\mathbf{DCM}_{12}}{\mathbf{DCM}_{11}} \right )$

DCM can be computed by applying consecutive rotations over time

(@dcm2) $\mathbf{DCM}_{(t)}  =  \mathbf{R}_{gyro(t)} \times \mathbf{DCM}_{(t-1)}$

If the sampling rate is high enough (over 1kHz at least), this method is very accurate and has
good dynamics over short periods of time, but in longer runs errors integrated during processing will cause serious drift
(both numerical errors and zero offset errors). To mitigate these problems accelerometer and compass has to be used to provide the initial
attitude and to fix the drift over time. Accelerometer measures external mechanical forces applied to the device together with gravitational force.
However precision of these devices are generally worse and they have slower sampling rates.
If there are no extern forces, it will measure the gravitational vector directly, thus providing the third row of the DCM.

(@acc) $\overrightarrow{\mathbf{a}}_{acc} = g~ \widehat{\mathbf{K}}_{xyz} + \dfrac{\overrightarrow{\mathbf{F}}}{m}$

Angular error is

(@accerr) $\delta_{ERR} = \arccos \left ( \dfrac {\overrightarrow{\mathbf{a}}_{acc}} { \left | \overrightarrow{\mathbf{a}}_{acc} \right |} \cdot \widehat{\mathbf{K}}_{xyz} \right )$

increasing nonlinearly with magnitude of the force $\overrightarrow{\mathbf{F}}$.
When there is an external force applied, which is significant relative to gravitational force, measurements will degrade rapidly.
There is a singularity during the free fall. This error may be corrected by using device speed measured by satellite navigation system with high sample rate (over 10Hz).

(@accgps) $\widehat{\mathbf{K}}_{xyz} = \dfrac {\overrightarrow{\mathbf{a}}_{acc} - \frac{\mathrm{d}}{\mathrm{d}t} {\overrightarrow{\mathbf{v}}_{GPS}}} {g}$

Magnetometer has similar properties, it measures magnetic flux density of the field the device is within.
This should ideally result in a vector pointing to the north, therefore providing the first row of the DCM.

(@mag) $\overrightarrow{\mathbf{I}}_{xyz} = \dfrac {\overrightarrow{\mathbf{B}}_{corr}} {\left | \overrightarrow{\mathbf{B}}_{corr} \right |}$

Magnetometers have even slower sampling rates and far worse precision, this is caused mainly by the field itself. First there are many local distortions in the Earth magnetic field,
caused by nearby metal objects, they can be divided into hard-iron and soft-iron effects. Hard-iron distortion (sometimes referred as magnetic deviation)
is caused by materials that produces magnetic field, that is added to the Earth magnetic field.
This field can be simply subtracted to compensate this error

(@maghard) $\overrightarrow{\mathbf{B}}_{corr1} = \overrightarrow{\mathbf{B}}_{mag} - \frac{1}{2} \left [ \min(B_x) + \max(B_x), \min(B_y) + \max(B_y), \min(B_z) + \max(B_z) \right ]$

The soft-iron distortion is caused by soft magnetic materials, which influences the field in a way that is not additive.
It may be observed as an ellipse when the device is turned around and the measured values are plotted.
To compensate for this error, values has to be processed in a way that transforms the ellipse back to the circle.
Further more the magnetic field of the Earth itself does not point to the geographic north, but is rotated by an angle specific to the location on the Earth surface.
Magnetic inclination is the vertical portion of this rotation causing magnetic vector to incline to the ground,
it may be fixed by using measurements from the accelerometer to make the magnetic vector perpendicular to the gravitational vector.

(@maginc) $\overrightarrow{\mathbf{B}}_{corr2} = \widehat{\mathbf{K}}_{xyz} \times \overrightarrow{\mathbf{B}}_{mag} \times \widehat{\mathbf{K}}_{xyz}$

Magnetic declination (sometimes referred as magnetic variation) is the horizontal portion of this rotation and is sometimes provided by the satellite navigation systems.
To correct for this error, measured values have to be rotated by the inverse angle.

(@magdec) $\overrightarrow{\mathbf{B}}_{corr3} = \overrightarrow{\mathbf{B}}_{mag} \begin{bmatrix} \cos(var) & \sin(var) \\ - \sin(var) & \cos(var) \end{bmatrix}$

Weighted average should be used to combine the DCM calculated by gyroscope and the DCM composed of corrected accelerometer and magnetometer measurements,
actual weights must be estimated by trial and error.

