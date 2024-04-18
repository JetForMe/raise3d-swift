# Raise3D Tool

A set of utilities for monitoring Raise3D 3D printers, and a Swift wrapper for the printer’s REST API.

Note that I’m working on automated builds to make using this tool simpler. But in the meantime, you
can build and run it yourself:

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
