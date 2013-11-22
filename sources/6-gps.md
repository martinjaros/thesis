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

GPS receivers uses [NMEA 183 standard][nmea0183][@NMEA0183]. Communication is done in sentences,
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
 * 6-9 fields are destination waypoint latitude and longitude with same formatting as in GGA sentence
 * 10th field is range to destination in nautical miles
 * 11th field is bearing to destination in degrees
 * 12th field is velocity towards destination in knots
 * 13th field is `A` for arrived or `V` for not arrived to destination

### Navigation

> TODO: Map projections [@Kennedy2000]

