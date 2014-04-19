## Satellite navigation subsystem

### Communication

Systems such GPS uses numerous satellites orbiting Earth transmitting their position and time.
Receiver can measure its position and time with accuracy based on number of satellites in view.
GPS receivers usually communicate via serial line, Linux kernel features TTY module originally used for teletypewriters.
It handles serial lines, converters and virtual lines with devices generally called `/dev/tty*`.
Serial connections (UART, RS-232) are usually named `/dev/ttySn`, where `n` is a device number.
Emulated connection are named `/dev/ttyUSBn` for USB emulators or `/dev/ttyACMn` for modem emulators.
There are also pseudo terminals in `/dev/pts/` used for software emulation.
This devices allows standard I/O and may be controlled with functions defined in `termios.h` or by using [stty(1)][stty] utility.
Important physical interface settings are

* baud rate
* parity
* flow control

Usual settings are 4800 or 38 400 baud with no parity and no flow control,
without proper interface configuration, no communication will occur
Driver further provides line processing before passing data to the application.
Important line settings are

* newline handling
* echo mode
* canonical mode
* timeouts and buffer sizes

In canonical mode, driver uses line buffer and allows line editing.
Buffer is passed to the application (made readable) after new line is encountered.
It may be combined with echo mode, which will automatically send received characters back.
This is how standard console line works, however if application needs to be in full control,
driver may be switched to raw mode with per-character buffers and echo disabled.
Also specific control characters for canonical mode may be configured.

GPS receivers uses [NMEA 183 standard][nmea0183] [@NMEA0183]. Communication is done in sentences,
each message starts with dollar sign followed by source name and sentence type,
then there is comma separated list of data fields optionally terminated by a checksum.
Each sentence is appended with carriage return and new line. For example in sentence

`$GPGGA,000000,4914.266,N,01638.583,E,1,8,1,257,M,46.43,M,,*46`{.perl}

`GP` is source name (GPS receiver), `GGA` is sentence type (fix information), `*46` is a checksum and rest are data fields.
Checksum is delimited by asterisk and consist of two character hexadecimal number calculated as bitwise XOR of all character between dollar and asterisk.
Note that fields may be empty (as last two fields in the example) and numbers may have fractional parts.

Name  Description            Important information
----- ---------------------- ----------------------
GSA   Satellites (overall)   Visible satellites, dilution of precision
GSV   Satellites (detailed)  Satellite number, elevation, azimuth (per satellite)
GGA   Fix information        Time, latitude, longitude, altitude, fix quality
RMC   Position data          Time, latitude, longitude, speed, track
RMB   Navigation data        Destination, range, bearing
WPL   Waypoint data          Latitude, longitude, name

Table: Important NMEA 0183 sentences

The **GSA** sentence has following fields:

 * 1st field is `A` for automatic selection of 2D or 3D fix, `M` for manual
 * 2nd field is `3` for 3D fix, `2` for 2D fix or `1` for no fix
 * 3-14 fields are identification numbers (PRN) of satellites in view
 * 15-17 fields are dilution of precision and its horizontal and vertical parts

The **GSV** sentence has following fields:

 * 1-2 fields are number of partial sentences and number of current part
 * 3rd field is number of satellites in view
 * 4th field is satellite number (PRN)
 * 5th field is satellite elevation
 * 6th field is satellite azimuth
 * 7th field is satellite signal to noise ratio in decibels
 * 8-11, 12-15, 16-19 fields are for other satellites info (number, elevation, azimuth, SNR)

The **GGA** sentence has following fields:

 * 1st field resembles time of the fix in format `hhmmss.ff`, where `hh` are hours, `mm` are minutes, `ss` are seconds and `ff` are fractional seconds.
 * 2-3 fields resembles device latitude in format `ddmm.ff,[NS]`, where `dd` are degrees, `mm` are minutes, `ff` are fractional minutes, `N` means north hemisphere and `S` means south.
 * 4-5 fields resembles device longitude in format `dddmm.ff,[EW]`, where `E` means east of Greenwich and `W` means west.
 * 6th field is fix type, 1 means GPS fix
 * 7th field is number of satellites in view
 * 8th field is horizontal dilution of precision
 * 9-10 fields resembles device altitude above mean sea level, first field is the value and second field is the unit used
 * 11-12 fields resembles height of geoid above WGS84 in the same fashion
 * 13-14 fields are usually unused and refers to differential GPS

The **RMC** sentence has following fields:

 * 1-5 fields are same as in GGA sentence
 * 6th field is speed over the ground in knots
 * 7th field is track angle in degrees
 * 8th field resembles date in format `ddmmyy`, where `dd` is day, `mm` is month and `yy` is last two digits of year
 * 9-10 fields resembles magnetic variation, first field is value in degrees, second field is `E` meaning east or `W` meaning west

The **RMB** sentence has following fields:

 * 1st field is status, `A` means OK
 * 2-3 fields resembles cross-track error, first field is the value in nautical miles, second field is `E` meaning east or `W` meaning west
 * 4th field is origin waypoint name
 * 5th field is destination waypoint name
 * 6-9 fields are destination waypoint latitude and longitude with the same formatting as in the GGA sentence
 * 10th field is range to destination in nautical miles
 * 11th field is bearing to destination in degrees
 * 12th field is velocity towards destination in knots
 * 13th field is `A` for arrived or `V` for not arrived to destination

The **WPL** sentence has following fields:

 * 1-2 fields are waypoint coordinates with the same formatting as in the GGA sentence
 * 3rd field is a waypoint identifier string

Many navigation systems use proprietary sentences, they begin with the *P* prefix.
For example some Garmin products specific sentences [@Garmin] are listed in the following table.

Name  Description            Important information
----- ---------------------- ----------------------
PGRME Estimated error        Horizontal, vertical position error
PGRMF Fix data               Date, time, latitude, longitude, speed, course
PGRMH VNAV data              Vertical speed, vertical speed to waypoint, height above terrain
PGRMT Sensor status          State information, ambient temperature
PGRMV 3D velocity vector     North, east, up velocity
PGRMZ Altitude               Altitude

Table: Garmin proprietary sentences

Sending data to the device is also possible, there are two useful sentences.
The PGRMC sentence configures the device including the baud-rate,
the PGRMO sentence enables / disables specific sentences.
This is important as the data rate must fit available bandwidth and therefore limiting the sentence interval.
Typical default baudrate is only 4800, the table bellow shows approximate data rates when the baudrate is increased.

 Baudrate Sentences enabled                  Max length  Records per second
--------- --------------------------------- ----------- -------------------
     4800 GPGGA, GPRMB, GPRMC                       180                   2
     4800 PGRME, PGRMF, PGRMT                       167                   2
     4800 GPGSA, GPGSV, GPGGA, GPRMB, GPRMC         310                   1
     9600 GPGSA, GPGSV, GPGGA, GPRMB, GPRMC         310                   3
     9600 PGRME, PGRMF, PGRMT                       167                   5
    19200 GPGSA, GPGSV, GPGGA, GPRMB, GPRMC         310                   6

Table: NMEA 0183 data throughput

### Navigation

As Earth shape is very complex, there are two layers of approximation used for computing position.
Geoid is the equipotential surface, which describes mean ocean level if Earth was fully covered with water.
Most recent geoid model is EGM96 which is used together with [WGS84 reference ellipsoid][wgs84] [@WGS84].
This ellipsoid has semi-major axis of $a = 6378137$ meters and flattening $f = 1/298.257223563$.
Note that ellipsoid flattening is defined as

$f = \dfrac{a - b}{a}$,

where *b* is the semi-minor axis. The eccentricity is defined as

$e = 2f - f^2$.

Geodetic latitude $\varphi$ is the angle between normal to the reference ellipsoid and the equator,
longitude $\lambda$ is the angle between normal to the reference ellipsoid and the prime meridian.
Because of the flattening, the normal does not intersect ellipsoid center.
Geocentric latitude $\psi$ uses line running through the center instead of the normal,

$\psi = \arctan [ (1-e)^2 \tan(\varphi)]$.

Device position measured by GPS is defined by its geodetic latitude, longitude and altitude

$h_{AMSL} = h_{WGS84} - h_{EGM96}$

measured as height above mean see level, where $h_{WGS84}$ is the height above reference ellipsoid and
$h_{EGM96}$ is the height above geoid. GPS sensors usually send fix information at low rates
and with high noise. Position needs to be interpolated and filtered between fixes.
To improve precision and especially dynamic response position
information may be augmented with inertial measurements.
The current speed vector can be calculated as

$\overrightarrow{v}_{(t)} = W_{SAT} \begin{bmatrix}
v_{GND} \cos(\alpha_{TRK}) \\
v_{GND} \sin(\alpha_{TRK}) \\
h_{baro(t)} - h_{baro(t-_\Delta t)}
\end{bmatrix} + (1-W_{SAT}) \overrightarrow{v}_{(t-_\Delta t)} + \mathbf{DCM} \times \overrightarrow{\mathbf{a}}_{acc} \cdot _\Delta t$,

where $W_{SAT}$ is the weight of the satellite measurement, $v_{GND}$ and $\alpha_{TRK}$ are speed and track angle from RMC sentence,
$h_{baro}$ and $\mathbf{a}_{acc}$ are inertial measurements.
The interpolated position in the current step will be

$\varphi_{(t)} = W_{SAT} \cdot \varphi_{SAT} + (1-W_{SAT}) \cdot \varphi_{(t-_\Delta t)} + \dfrac{v_{x(t)} \cdot _\Delta t}{R_{(\varphi)}}$,

$\lambda_{(t)} = W_{SAT} \cdot \lambda_{SAT} + (1-W_{SAT}) \cdot \lambda_{(t-_\Delta t)} + \dfrac{v_{y(t)} \cdot _\Delta t}{R_{(\varphi)} \cdot \cos(\varphi)}$,

$h_{(t)} = W_{SAT} \cdot h_{SAT} + (1-W_{SAT}) \cdot h_{(t-_\Delta t)} + v_{z(t)} \cdot _\Delta t$,

where *R* is the ellipsoid radius at the given latitude

$R = \dfrac{\sqrt{b^4 \sin(\varphi)^2 + a^4 \cos(\varphi)^2}}{\sqrt{b^2 \sin(\varphi)^2 + a^2 \cos(\varphi)^2}}$.

Application needs to know projections of specific landmarks as normalized horizontal and
vertical coordinates (in range of -1 to 1) used for rendering

$\begin{bmatrix} x \cdot FOV_x \\ y \cdot FOV_y \end{bmatrix} = 
\begin{bmatrix} \cos(\gamma_{dev}) & -\sin(\gamma_{dev}) \\ \sin(\gamma_{dev}) & \cos(\gamma_{dev})  \end{bmatrix}
\times
\begin{bmatrix} \alpha_{proj} - \alpha_{dev} \\ \beta_{proj} - \beta_{dev} \end{bmatrix}
$,

where *FOV* is the field of view, *dev* means device angle (calculated by [inertial subsystem (2.4)](#inertial-measurement-subsystem)) and
*proj* means projection angle (defined later on in this section).
Orthodrome (great circle) is the intersection of a sphere and a plane passing though its center.
However, because Earth flattening is rather small, it may be used as an approximation for a curve following Earth surface,
connecting two points with shortest route. [Spherical trigonometry][sphtrig] [@SphTrig] defines basis for orthodrome calculations,
shown in the illustration below.

![Horizontal projection angle][hangle]

Heading changes along the route and its initial value is the horizontal projection angle

$\alpha_{proj} = \arctan \left ( \dfrac{\sin(\lambda - \lambda_0) \cos(\varphi)}
{\cos(\varphi_0) \sin(\varphi) - \sin(\varphi_0) \cos(\varphi) \cos(\lambda - \lambda_0)} \right )$,

the zero index refers to the device coordinate. Angular distance between those two points is

$\phi = \arccos(\sin(\varphi_0) \sin(\varphi) + \cos(\varphi_0) \cos(\varphi) \cos(\lambda - \lambda_0))$.

Vertical projection angle is the angle between the horizon (perpendicular to normal) and
a line directly connecting the points.
Lets construct a triangle connecting the points with the center of the reference ellipsoid as in the illustration below.
Zero flattening is assumed, so the normals have intersection in the center ($f = 0 \rightarrow e = 0 \rightarrow \psi = \varphi$).

![Vertical projection angle][vangle]

The triangle sides are

$a_\Delta = h_0 + R_{(\varphi_0)}$,

$b_\Delta = h + R_{(\varphi)}$,

$c_\Delta = \sqrt{a_\Delta^2 + b_\Delta^2 - 2 a_\Delta b_\Delta \cos(\phi)}$,

$\beta_{proj} = \arcsin \left ( \dfrac{b_\Delta}{c_\Delta} \sin(\phi) \right ) - \frac{\pi}{2}$,

where *h* is height above reference ellipsoid.
These calculations are quite complex and there is plenty of room for approximation.
Over short distance, such as typical in visual ranges, orthodromes may be replaced with loxodromes (rhumb lines).
Loxodrome is a curve following Earth surface, connecting two points with constant heading.
It has similar path to orthodrome, if the points are relatively far from poles a close together.
Simplified heading along the line is

$\alpha_{proj} \doteq \arctan \left ( \dfrac{\lambda \cos(\varphi) - \lambda_0 \cos(\varphi_0)}{\varphi - \varphi_0} \right )$.

Note that [loxodrome approximation][rhumb] will fail horribly near poles as the curve will run circles around the pole [@MapProjections].
Angular distance along loxodrome is

$\phi \doteq \sqrt{(\varphi - \varphi_0)^2 + (\lambda \cos(\varphi) - \lambda_0 \cos(\varphi_0))^2}$

and a horizontal distance along the arc between those points is

$d = \phi \cdot R_{(\varphi_0)}$,

assuming flattening difference is close to zero, so *R* is constant along the curve.
With the approximation of local flat Earth surface perpendicular to the normal, the simplified vertical projection angle is

$\beta_{proj} \doteq \arctan \left ( \dfrac{h - h_0}{d} \right )$.

This approximation will fail at higher altitudes when the visibility range is high enough to make the Earth curvature observable.

### Elevation mapping

Waypoints are usually defined only by latitude and longitude, as their altitude equals terrain altitude (for example the WPL sentence).
To determine the terrain topology, elevation map may be used. This is a scalar field usually encapsulated into raster image with meta-data.
[GeoTIFF][geotiff] [@GeoTIFF] is a standardized format defining georeferencing information within a TIFF file.
Digital elevation models in this format are available for example at [USGS][usgs] (United States) or [Eurostat][eurostat] (Europe).
There are several tools for working with this format, for example the [FWTools][fwtools] open source GIS binary kit.
To export quantized pixel map from the elevation model, the toolkit comes with the *gdal_translate* utility.
The following command will generate PNG image of the South Moravian Region of the Czech Republic

```
gdal_translate eudem_dem_5deg_n45e015.tif dem48_50n15_18e.png \
 -srcwin 0 0 10800 7200 -ot UInt16 -of PNG -scale 0 1000 0 65535
```

This file can be read by the *libpng* library

```{.c}
FILE *f = fopen("dem48_50n15_18e.png", "rb");
png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
png_infop info = png_create_info_struct(png);
png_init_io(png, f);
png_read_info(png, info);
size_t num = png_get_image_height(png, info);
size_t len = png_get_rowbytes(png, info);
png_bytep *p = malloc(num * sizeof(png_bytep));
int i; for(i = 0; i < num; i++) p[i] = malloc(len);
png_read_image(png, p);
```
<!---->

Then to calculate the actual elevation at the given coordinates

```{.c}
#define LEFT   15    // degrees east
#define RIGHT  18    // degrees east
#define TOP    50    // degrees north
#define BOTTOM 48    // degrees north
#define WIDTH  10800 // pixels
#define HEIGHT 7200  // pixels
#define SCALE  1000  // meters per 0xFFFF
int x = (lon - LEFT) / (RIGHT - LEFT) * WIDTH + 0.5;
int y = (TOP - lat) / (TOP - BOTTOM) * HEIGHT + 0.5;
double value = (double)(((uint16_t)p[y][x * 2] << 8) |
                         (uint16_t)p[y][x * 2 + 1]) / 0xFFFF * SCALE;
```
<!---->

This value should be bi-linearly interpolated across the four neighboring pixels located at the
nearest integer values *x~1~*, *x~2~*, *y~1~*, *y~2~*.
The intermediate linear interpolation is calculated as

$f_{(x,y_1)} = \dfrac{x_2 - x}{x_2 - x_1} f_{(x_1,y_1)} + \dfrac{x - x_1}{x_2 - x_1} f_{(x_2,y_1)}$,

$f_{(x,y_2)} = \dfrac{x_2 - x}{x_2 - x_1} f_{(x_1,y_2)} + \dfrac{x - x_1}{x_2 - x_1} f_{(x_2,y_2)}$.

The final value would then be

$f(x,y) = \dfrac{y_2 - y}{y_2 - y_1} f_{(x,y_1)} + \dfrac{y - y_1}{y_2 - y_1} f_{(x,y_2)}$.

