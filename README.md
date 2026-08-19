# MacMonitor Premium

A lightweight, native macOS menu bar monitor — CPU thermal state, RAM, disk and battery — built without an Apple Developer account.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black) ![Swift 5.8](https://img.shields.io/badge/Swift-5.8-orange) ![MIT](https://img.shields.io/badge/license-MIT-blue) [![Buy me a coffee](https://img.shields.io/badge/☕-Buy%20me%20a%20coffee-yellow)](https://buymeacoffee.com/bulldozeStore)

## Why not °C?

Most menu bar monitors call `osx-cpu-temp` (a subprocess) or access SMC directly. On macOS Ventura, **SMC access is blocked for unsigned apps** — you get `kIOReturnUnsupported` on every key, so the temperature always shows `--°`.

MacMonitor uses `ProcessInfo.thermalState` — the exact same variable macOS uses internally to decide whether to throttle your CPU. Zero SMC, zero subprocess, zero cost.

| State | Meaning |
|-------|---------|
| Normal | CPU is cool, no throttling |
| Morno | Slightly warm, moderate load |
| Quente | Hot — throttling active |
| Crítico | Critical — severe performance reduction |

## Features

- CPU thermal state (Normal / Morno / Quente / Crítico)
- RAM usage % with active+wired+compressed calculation
- Disk usage % via `/System/Volumes/Data`
- Battery time remaining / to charge with dynamic icon
- Settings panel — show/hide each metric individually
- Event-driven updates (thermalState via NotificationCenter, battery via IOPSNotification)
- Disk updates every 5 min, everything else every 3s
- ~0% CPU at idle, ~4 MB RAM

## Requirements

- macOS 13 Ventura or later
- Intel or Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)

## Build

```bash
git clone https://github.com/goiascontab-ui/macmonitor
cd macmonitor
./build.sh
open MacMonitor.app
```

First launch: right-click → Open (Gatekeeper prompt for unsigned app).

## License

MIT — free to use, modify, and distribute.

## Support

If MacMonitor saved your Mac from overheating, [buy me a coffee ☕](https://buymeacoffee.com/bulldozeStore)
