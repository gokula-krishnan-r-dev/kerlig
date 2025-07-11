# Background Mode Implementation

## Overview

This document describes the implementation of background mode functionality for Kerlig, allowing the app to run continuously in the background and respond to hotkeys without showing in the dock.

## Key Components

### 1. BackgroundAppManager (`Services/BackgroundAppManager.swift`)

- **Purpose**: Central coordinator for background app functionality
- **Key Features**:
  - Manages app lifecycle (background/foreground modes)
  - Handles global hotkey registration
  - Monitors system events (sleep/wake, user sessions)
  - Coordinates with menu bar controller
  - Manages window visibility

### 2. MenuBarController (`Controllers/MenuBarController.swift`)

- **Purpose**: Provides menu bar access when app is in background
- **Key Features**:
  - Custom menu bar icon with "K" logo
  - Left-click for quick capture
  - Right-click for full menu
  - Menu options: Quick Capture, Show Main Window, Settings, Port Monitor, About, Quit
  - Launch at login toggle

### 3. LaunchAtLoginManager (`Services/LaunchAtLoginManager.swift`)

- **Purpose**: Manages launch at login functionality
- **Key Features**:
  - macOS 13+ support using SMAppService
  - Legacy support for older macOS versions
  - Persistent settings storage

### 4. AppState Updates

- **New Properties**:
  - `runInBackground`: Controls background mode
  - `launchAtLogin`: Controls launch at login
- **New Methods**:
  - `toggleBackgroundMode()`: Switches between background/foreground
  - `toggleLaunchAtLogin()`: Enables/disables launch at login

## Configuration

### Info.plist Settings

```xml
<key>LSUIElement</key>
<true/>
```

This key makes the app run as a background agent by default.

### User Preferences

Users can control background behavior through:

1. **Settings Panel**: General Settings → App Behavior
2. **Menu Bar**: Right-click menu bar icon → Launch at Login

## How It Works

### App Launch

1. App starts with `LSUIElement=true` (background agent)
2. `BackgroundAppManager` is configured with dependencies
3. Based on user preferences:
   - If `runInBackground=true`: Stays in background, shows menu bar icon
   - If `runInBackground=false`: Shows in dock, displays main window

### Background Mode

- **Dock Icon**: Hidden (app not visible in dock)
- **Menu Bar**: Shows custom "K" icon
- **Hotkeys**: Global hotkey (Option+Space) works system-wide
- **Windows**: Only floating panels are shown when triggered

### Foreground Mode

- **Dock Icon**: Visible (app appears in dock)
- **Menu Bar**: Icon remains for quick access
- **Hotkeys**: Still work globally
- **Windows**: Main window can be shown/hidden normally

### Hotkey Handling

1. User presses Option+Space anywhere in the system
2. `HotkeyManager` captures the keystroke
3. `BackgroundAppManager` handles the event
4. Text is captured from the current application
5. Floating panel is shown with captured text

## User Experience

### First Launch

- App shows onboarding/welcome screens
- After setup, enters background mode if preference is enabled
- Menu bar icon appears for access

### Daily Usage

- **Quick Capture**: Click menu bar icon or use Option+Space
- **Main Window**: Right-click menu bar → "Show Main Window"
- **Settings**: Right-click menu bar → "Settings..."
- **Quit**: Right-click menu bar → "Quit Kerlig"

### Settings Control

Users can toggle:

- **Run in background**: App behavior (background vs. foreground)
- **Launch at login**: Automatic startup
- **Hotkey enabled**: Global hotkey functionality

## Technical Details

### System Integration

- Uses `NSApp.setActivationPolicy(.accessory)` for background mode
- Uses `NSApp.setActivationPolicy(.regular)` for foreground mode
- Monitors system events for sleep/wake cycles
- Handles user session changes

### Memory Management

- Proper cleanup in `deinit` methods
- Notification center observer removal
- Timer invalidation for system monitoring

### Error Handling

- Permission checks for accessibility access
- Graceful fallbacks for hotkey registration
- Logging for debugging background operations

## Future Enhancements

### Planned Features

1. **Status Indicators**: Show app activity in menu bar icon
2. **Quick Actions**: Additional menu bar shortcuts
3. **Notification Integration**: Background task notifications
4. **System Tray Customization**: User-configurable menu bar icon

### Performance Optimizations

1. **Lazy Loading**: Initialize components only when needed
2. **Memory Efficiency**: Optimize background resource usage
3. **Battery Optimization**: Minimize background activity impact

## Troubleshooting

### Common Issues

1. **Hotkey Not Working**: Check accessibility permissions
2. **Menu Bar Icon Missing**: Restart app or check background mode setting
3. **App Not Launching at Login**: Verify launch at login permission

### Debug Logging

The app includes comprehensive logging for background operations:

- `🔄 Entered background mode - app hidden from dock`
- `🔄 Exited background mode - app visible in dock`
- `✅ Launch at login enabled`
- `🔑 Handling hotkey press`

## Conclusion

The background mode implementation provides a seamless, professional experience for users who want Kerlig to be always available without cluttering their dock. The combination of menu bar integration, global hotkeys, and user-controlled preferences ensures the app works exactly as users expect from a modern macOS utility.
