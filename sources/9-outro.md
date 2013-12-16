# Conclusion

Theoretical grounds have been made for the application development.
Application has been implemented with sources available at [@ARNav].
The basic functionality has been established,
the graphical output works just fine even on less resourceful systems such as Sitara AM3358.
Only USB camera has been tested in RGB and YUV formats.
The H.264 capability showed promise for both video input and output,
however limited to the OMAP4460.
The MPU-9150 has been successfully implemented,
however the DCM algorithm needs to be specifically adapted to its sensors.
The gyroscope has little jitter, low-pass filters seems to fix this,
but software filtering should be also implemented.
Accelerometer and magnetometer readings were very unstable,
averaging ratios over 1:10 needs to be used.
Overall, the application proved the concept,
leaving space for further enhancements and hardware design.

