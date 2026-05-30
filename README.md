# Control 3D

A cross-platform 3D printer control app built with Flutter. Connects to printers via serial (USB) with a real-time terminal, temperature monitoring, movement controls, and macro system.

## Features

- **Serial connection** — connect to printers over USB with configurable baud rates and auto-reconnect
- **Real-time terminal** — send G-code, view responses, filter system commands (M105/M114), comment syntax highlighting, persistent command history with up/down navigation
- **Temperature monitoring** — live nozzle and bed readouts with target controls, separate nozzle/bed sparkline charts over selectable time windows (30s / 1m / 5m / 15m)
- **Movement controls** — XY radial D-pad with adjustable step sizes, Z-axis panel, home buttons (All / X / Y / Z), coordinate display
- **Extrusion** — feed rate and amount sliders with E‑/E+ buttons
- **Speed & Flow** — live speed and flow rate override sliders
- **Macros** — collapsible panel with custom G-code macros (add, edit, delete, execute)
- **Multiple printers** — save and switch between printer configurations
- **Theming** — Tokyo Night (dark) and Tokyo Night Day (light), auto system theme
- **Responsive UI** — bottom navigation on mobile, vertical navigation rail on desktop (≥600px) with multi-column layouts

## Screens

| Tab | Description |
|---|---|
| **Control** | D-pad, coordinates, extrude, temperature, speed/flow, macros |
| **Temperature** | Time window selector, nozzle chart, bed chart, readouts, macros |
| **Terminal** | G-code input/output, silent mode toggle, macros |
| **Settings** | Theme picker, printer management, clear command history |

## Requirements

- Flutter SDK `^3.11.5`
- For serial connectivity: `flutter_libserialport` — see its [platform setup](https://pub.dev/packages/flutter_libserialport)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate app icons (uses control3d.png from project root)
dart run flutter_launcher_icons

# Run
flutter run
```

## Tech Stack

- **Framework:** Flutter + Dart
- **State management:** Riverpod
- **Serial:** flutter_libserialport
- **Charts:** fl_chart
- **Persistence:** shared_preferences
- **Icons:** Font Awesome Flutter
