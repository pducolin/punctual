# Punctual

A macOS menu bar app that watches your calendar and interrupts you with an overlay alert when a meeting is about to start — so you never join late again.

## How it works

Punctual runs silently in the background as a menu bar icon (no Dock presence). It polls your system calendar every 30 seconds and also listens for real-time calendar changes. When an event is within 2 minutes of starting, an overlay appears center-screen — on whichever display your cursor is on — and stays there until you dismiss it.

## Features

- Overlay alert 2 minutes before any non-all-day calendar event
- Shows event title, start time, location, and calendar name
- Color-coded urgency: orange when approaching, red when starting now
- Appears on the correct display (follows cursor position)
- Floats above full-screen apps and all Spaces
- "Got it" button (or ⏎) to dismiss
- No Dock icon — lives entirely in the menu bar

## Requirements

- macOS 14.0 or later
- Calendar access permission (prompted on first launch)

## Building

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Build from the command line
xcodebuild -project Punctual.xcodeproj -scheme Punctual -configuration Debug
```

Or open `Punctual.xcodeproj` in Xcode and press ⌘R.

## Running

On first launch macOS will prompt for calendar access. Grant it — Punctual reads events but never modifies them.
