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

This solution is based on information found from:
* https://askubuntu.com/questions/49910/how-to-distinguish-between-identical-usb-to-serial-adapters
* http://www.reactivated.net/writing_udev_rules.html

## USB Device Path Identification

Because we're going to be writing `udev` rules, we query the udev system getting so that it will report the device characteristics in a manner in which we can use the information directly.  

First, plug in the CNC mill into the port which it will live on. It should show up on `/dev/ttyUSB0`.

Next, query the device info:
````
udevadm info -a -p $(udevadm info -q path -n /dev/ttyUSB0)
````

The relevant portion of the returned information is:
````
  looking at device '/devices/pci0000:00/0000:00:1d.0/usb1/1-1/1-1.4/1-1.4.4/1-1.4.4:1.0/ttyUSB0/tty/ttyUSB0':
    KERNEL=="ttyUSB0"
    SUBSYSTEM=="tty"
    DRIVER==""

  looking at parent device '/devices/pci0000:00/0000:00:1d.0/usb1/1-1/1-1.4/1-1.4.4/1-1.4.4:1.0/ttyUSB0':
    KERNELS=="ttyUSB0"
    SUBSYSTEMS=="usb-serial"
    DRIVERS=="ch341-uart"
    ATTRS{port_number}=="0"

  looking at parent device '/devices/pci0000:00/0000:00:1d.0/usb1/1-1/1-1.4/1-1.4.4/1-1.4.4:1.0':
    KERNELS=="1-1.4.4:1.0"
    SUBSYSTEMS=="usb"
    DRIVERS=="ch341"
    ATTRS{bNumEndpoints}=="03"
    ATTRS{bAlternateSetting}==" 0"
    ATTRS{bInterfaceProtocol}=="02"
    ATTRS{bInterfaceClass}=="ff"
    ATTRS{supports_autosuspend}=="1"
    ATTRS{authorized}=="1"
    ATTRS{bInterfaceSubClass}=="01"
    ATTRS{bInterfaceNumber}=="00"

  looking at parent device '/devices/pci0000:00/0000:00:1d.0/usb1/1-1/1-1.4/1-1.4.4':
    KERNELS=="1-1.4.4"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ATTRS{busnum}=="1"
    ATTRS{bConfigurationValue}=="1"
````
We'll focus on the `KERNEL` and `KERNELS` information.

## UDEV Rules

# Test

Reload the `udev` rules, then trigger the system to rerun them.

````
udevadm control --reload
udevadm trigger
````
