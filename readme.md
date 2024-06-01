# Get the Docker image
````
docker pull cncjs/cncjs:latest
````

# Running the Image

> ⚠️ **See [info on USB device mapping](usb-device-mapping.md) for updates to the `--device` values for uniquely identifying identical USB devices for different containers.**

````
docker run --device=/dev/USB0:/dev/USB0 -p 80:8000 --detach --restart unless-stopped --name cncjs cncjs/cncjs:latest /usr/local/bin/cncjs -w /fileshare
````
* `--device`     : Access to specific hardware devices such as USB ports `--device=<host device>:<container device>`
* `--detach`     : Spawns the processes
* `-p`           : Maps ports `-p <host-port>:<container-port>`
* `--name`       : Simple name for the container
* `--restart`    " Restarts the container (including on host boot) unless manually stopped.
* `-v`           : Map volume `-v <host-dir>:<container-dir>`
* `-w`           : Watch directory for loading files from file system.  Using /fileshare

# OctoPrint

## Docker Image
````
docker pull octoprint/octoprint
````

⚠️See CNCjs section above for more information about mapping specific USB devices.

````
docker run --device=/dev/USB0:/dev/USB0 -p 8080:80 --detach --restart unless-stopped --name octoprint -v /fileshare:/octoprint octoprint/octoprint:latest
````

Note: running Octoprint on host port 8080 to leave CNCjs on server port 80.

## Spool Manager

* [SpoolMan](https://github.com/Donkie/Spoolman/) filament spool manager.

* Get latest Docker image:
```
docker pull ghcr.io/donkie/spoolman:latest
```

* Set up local directory for data storage (uses SQLite database):

```
cd <parent dir for data dir>
mkdir Spoolman-Data
chown 1000:1000 Spoolman-Data
```

* Start Docker container:

```
docker run --detach --restart unless-stopped --name spoolman -p 7912:8000 -v <parent dir>/Spoolman-Data/:/home/app/.local/share/spool
man ghcr.io/donkie/spoolman
```

## Webcam Streaming

* Octoprint doesn't directly support video cameras.  It provides videos through a web cam stream.  Have to install a separate web server for the video stream.
* Installed the video stream server on the base machine for simplicity.
* [ustreamer](https://github.com/pikvm/ustreamer) is a lightweight video streamer.  
  * Compiled from source, but was simple.  
  * After compile, did a `make install` to install for others.
  * Set up a system service to start web cam streaming on boot per: https://github.com/pikvm/ustreamer/issues/16
 * Started service on port `8083` to avoid conficts with CNCjs & Octoprint.
 * Configured Octoprint's webcam to point at `http://shop:8083/stream`

# Docker Quick Help

Given that we've named our image "cncjs" per the `--name` command above:

* Stop a the container (without removing it)
````
docker container stop cncjs
````
* Restart the container
````
docker container restart cncjs
````
* Remove the container so that we can recreate it with different parameters
````
docker container rm cncjs
````
* Log in to the currently running container
````
docker exec -it cncjs /bin/bash
````

# Samba File Share

Samba file share on my LAN Linux box.  System is not exposed to the broader internet.

* Shared directory mounted at `/fileshare` with permissions 777.
* Owned by user/group `shop/shop`.
* Windows Domain name is `workgroup`
* Samba password is `shop`

# CNCjs Touch Probe Setup

For 3-Axis probe hardware.

## Built in probe config

| Param | Value |
| ----- | ----- |
| Probe Depth | 10 mm |
| Probe Feedrate | 20 mm/min |
| Touch Plate Thickness | 6.38 mm |
| Retraction Distance | 1 mm |

## 3-Axis Probe Macro

````
;Start with end mill in hole, BELOW Z surface of probe

; Wait until the planner queue is empty
%wait

; Set user-defined variables
%Z_PROBE_THICKNESS = 6.38	;thickness of Z probe plate
%PROBE_DISTANCE = 20  ;Max distance for a probe motion
%PROBE_FEEDRATE_A = 250
%PROBE_FEEDRATE_B = 30
%PROBE_MAJOR_RETRACT = 1  ;distance of retract before probing opposite side
%Z_PROBE = 6	; Lift out of hole and Max Z probe
%Z_PROBE_KEEPOUT = 5 ;distance (X&Y) from edge of hole for Z probe 
%Z_FINAL = 3 ;final height above probe


%UNITS=modal.units
%DISTANCE=modal.distance


G91 ; Relative positioning
G21 ;Use millimeters

; Probe toward right side of hole with a maximum probe distance
G38.2 X[PROBE_DISTANCE] F[PROBE_FEEDRATE_A]
G0 X-1 ;retract
G38.2 X5 F[PROBE_FEEDRATE_B] ;Slow Probe
%X_RIGHT = posx
G0 X-[PROBE_MAJOR_RETRACT]	;retract

; Probe toward Left side of hole with a maximum probe distance
G38.2 X-[PROBE_DISTANCE] F[PROBE_FEEDRATE_A]
G0 X1 ;retract
G38.2 X-5 F[PROBE_FEEDRATE_B] ;Slow Probe
%X_LEFT = posx
%X_CHORD = X_RIGHT - X_LEFT
G0 X[X_CHORD/2]
%X_CENTER = posx	;get X-value of hole center for some reason
; A dwell time of one second to make sure the planner queue is empty
G4 P1
G10L20X0

; Probe toward top side of hole with a maximum probe distance
G38.2 Y[PROBE_DISTANCE] F[PROBE_FEEDRATE_A]
G0 Y-1 ;retract
G38.2 Y5 F[PROBE_FEEDRATE_B] ;Slow Probe
%Y_TOP = posy
G0 Y-[PROBE_MAJOR_RETRACT]	;retract
; Probe toward bottom side of hole with a maximum probe distance
G38.2 Y-[PROBE_DISTANCE] F[PROBE_FEEDRATE_A]
G0 Y1 ;retract 2mm
G38.2 Y-5 F[PROBE_FEEDRATE_B] ;Slow Probe
%Y_BTM = posy
%Y_CHORD = Y_TOP - Y_BTM
%HOLE_RADIUS = Y_CHORD/2
G0 Y[HOLE_RADIUS]
%Y_CENTER = posy	;get Y-value of hole center for some reason
; A dwell time of one second to make sure the planner queue is empty
G4 P0.5
G10L20Y0


;Get to Z probe location
G0 Z[Z_PROBE]
X[HOLE_RADIUS + Z_PROBE_KEEPOUT] Y[HOLE_RADIUS + Z_PROBE_KEEPOUT]
G4 P2

; Probe Z
G38.2 Z-[Z_PROBE+6] F[PROBE_FEEDRATE_A]
G0 Z1 ;retract 
G38.2 Z-5 F[PROBE_FEEDRATE_B] ;Slow Probe
G10L20Z[Z_PROBE_THICKNESS]
G0 Z[Z_FINAL]	;raise Z
G90	;absolute distance
G0 X0 Y0
; A dwell time of one second to make sure the planner queue is empty
G4 P1

[UNITS] [DISTANCE] ;restore unit and distance modal state
````

