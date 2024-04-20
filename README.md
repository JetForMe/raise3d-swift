# Raise3D Tool

A set of utilities for monitoring Raise3D 3D printers, and a Swift wrapper for the printer’s REST API.

The only useful thing this does right now is notify you of progress and if the printer is paused or
stopped.

> **Note:** This tool is in its very early stages. Many things may not work well, from installing it
to running it. I have only tested this on macOS 14.4. It might work on Linux, maybe even Windows,
but I haven’t tried it. You’ll probably have to adjust the `platforms` value in `Package.swift`.

> If you run into problems, please file issues in the Github repo. I’ll do my best to help, but this
is a very low priority project for me.

## Installation

> **Note**: For now, this only works on macOS.

Install via [brew](https://brew.sh), or download the sources and run directly. You’ll need a Swift 5.10+ compiler
installed to do that.

Brew will install a pre-built binary on macOS:

```bash
% brew tap jetforme/tap
% brew install raise3d-tool 
```

## Basic Usage

1. Download or clone the repo.
2. In a terminal, cd to the directory, and invoke it:

	```bash
	% swift run raise3d --addr <printer IP address:port> --password <printer password> info
	Building for debugging...
	[1/1] Write swift-version--58304C5D6DBC2206.txt
	Build complete! (0.13s)
	Name:              Raise3D
	Model:             Raise3D Pro2
	Version:           1.7.7.1026
	Storage available: 2.4 MB
	Firmware version:  1.7.0.1008
	API version:       0.1.0.926
	```


## Notifications

For now, notifications require the use of the [Alertz](https://alertzy.app) app and service. Install the app,
register, and copy the account key from the Account tab. Then invoke the `raise3d` tool like this:

```bash
% swift run raise3d --addr <printer IP address:port> --password <printer password> monitor --notify <alertz account key>
Building for debugging...
[1/1] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.18s)
Monitoring printer at address: <printer IP address:port>
Progress: 77.5% (next milestone: 80.0%)
```
Every 10%, you’ll get a notification, and you should get a notification if the printer is paused or stopped.

Control-C to stop.
 
## Motivation

I was printing with some old filament that kept breaking. I wouldn’t notice until hours later, wasting
precious time. So I built a crude tool to send a push notification to my phone if the printer reported an
error.

