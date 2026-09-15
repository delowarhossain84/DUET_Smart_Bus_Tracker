# Implementation Plan - Fix Splash Screen (Remove Black Background)

The goal is to fix the issue where the app shows a black screen immediately after clicking the icon. We will replace it with the professional **Primary DUET Blue** background to match your university branding.

## User Review Required

> [!IMPORTANT]
> The "Black Screen" you are seeing is the native Android splash screen. It appears before Flutter loads. I will force this to be **Blue** even if your phone is in Dark Mode.

## Proposed Changes

### 1. Native Android Fix (Splash Screen)

#### [MODIFY] [launch_background.xml](file:///G:/android_project/DUET_project/Bus_Tracker/duet_smart_bus_tracker/android/app/src/main/res/drawable/launch_background.xml)
- Change the solid background color from `white` to your Primary Blue (`#1565C0`).
- Center the `app_icon.png` in the middle of the splash screen so it looks like the icon you clicked.

#### [MODIFY] [styles.xml](file:///G:/android_project/DUET_project/Bus_Tracker/duet_smart_bus_tracker/android/app/src/main/res/values-night/styles.xml)
- Update the `LaunchTheme` to use a light parent or explicitly set the window background to avoid the automatic black screen in Dark Mode.

### 2. Flutter Splash Screen Polish

#### [MODIFY] [splash_screen.dart](file:///G:/android_project/DUET_project/Bus_Tracker/duet_smart_bus_tracker/lib/splash_screen.dart)
- Ensure the background matches the native blue perfectly.
- Clean up any UI glitches to ensure a seamless transition from the phone icon to the app's home page.

## Verification Plan

### Manual Verification
1. Click the app icon on your phone/emulator.
2. Verify that the screen is **immediately Blue** (no black flash).
3. Verify the bus icon appears smoothly in the center.
4. Confirm it transitions to the Login screen after 3 seconds.
