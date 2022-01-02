# USB Device Mapping Issue

## General Description
* Using a single PC to host web interfaces for multiple machines that happen to have the same USB <-> Serial hardware (same USB VID/PID).  
* This makes it difficult to determine which device to use. 

## Details
* Sainsmart 3018-Pro Desktop CNC mill with Woodpecker 3.2 PCA using the USB device: QinHeng Electronics HL-340 USB-Serial adapter.
* Creality Ender3 Pro 3D printer with the Creality V4.2.7 silent motherboard using the USB device: QinHeng Electronics HL-340 USB-Serial adapter.
* The CNC mill is controlled by a CNCjs server running on a Docker container.
* The 3D printer is controlled by an Octoprint server running on a different Docker container.

# Solution

## Overview
1. Because the USB devices have the same VID/PID, it is not possible to directly identify them via USB ID's.  Possible solutions are:
  * Run a program upon connect to determine the device.
  * Always use the same USB port on the host PC. Given my hardware will always be connected the same, this is the chosen solution.
2. Use custom `udev` rules to identify the devices by USB port path, and assign a unique name.
3. Allow the Docker container to have access to only the USB device that it needs.

## USB Device Path Identification

