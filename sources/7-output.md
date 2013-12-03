## Output creation

The [output image example](#output-image-example) appendix shows the actual output image.
In the top left corner is the current speed over ground as reported by the satellite navigation,
while in the top right corner is the current altitude above mean sea level.
Speed is displayed in kilometers per hour and the altitude in meters.
In the top center is the current waypoint name and distance in kilometers, if provided by the NMEA 0183 navigation data sentence (RMB).
There is a heading ruler in the bottom, it is scaled by camera field of view and oriented to current heading.
Course to any visible object may be deducted directly from the ruler.
There are two markers, the arrow marker point to current track angle as reported by the satellite navigation.
The circle marker is the course to current waypoint if any.
The dashed horizontal line in the center of the image is the horizon line,
it follows the horizon as calculated by inertial subsystem by moving up or down and rotating around its center.
Orientation is determined by the marginal markers, they points always to the ground.
If the horizon is not visible, dashed arrow is shown instead pointing up or down to where the horizon is hidden.
Application accepts database of landmarks, following file was used in this example:

```{.python}
# Encoding ISO/IEC 8859-1
# Test landmarks (lat[rad], lon[rad], alt[m], name)
25e-5, 1e-5, 0, testA
50e-5, -1e-5, 100, testB
```

The `testA` landmark label is visible in the image, its location is centered directly above its projection.
Projections are calculated in conjunction of both navigation subsystems and graphic acceleration.
Large landmark database may be supplemented to provide spatial navigation references,
only visible landmarks will be shown.
This overlay is rendered in real time over the source video (there is none in the example),
all rendering and data gathering methods are provided by the respective subsystems.
Upon correct configuration, overlay elements (ruler, horizon and labels) should be aligned
with the real visible places in the video frame.
System allows free six degrees of freedom movement of the camera while still being able to render the overlay correctly.
Waypoint management and route planning is done solely by the external navigation system,
it is expected that it will provide its own user interface.
This allows connection for example to PDAs or other specialized devices which delivers classic 2D moving map navigation to the user
with its own controls.

