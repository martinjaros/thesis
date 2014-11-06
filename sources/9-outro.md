\clearpage

# Conclusion

The application has been implemented with its source code available under the GPL license at [@ARNav].
As a prototype, the Pandaboard development board was chosen for realization.
The complete system is highly modular and configurable, the primary video source
is either USB or WiFi connected camera and a 7-inch high contrast HDMI display panel is used for the output.
Both MJPEG and H.264 coders are functional as well as raw RGB or YUV formats.
The application is limited to 720p resolution because of the display, however it is fully capable of generating full HD video.
The navigation subsystems integrate well with existing external devices, the combination of satellite and inertial sensors results in precise positional and spatial information.
Complex filtering algorithm provides stable attitude necessary to avoid screen jittering, projections are also interpolated over time.
No sophisticated user interface was implemented as the application can share most data (waypoints, enroute navigation) with the existing systems via its serial connection
and those systems already have complex user interfaces. This means the waypoint management is centralized and not duplicated by the application.
The final device is deployable into an augmented flight navigation system.

\clearpage

# References

