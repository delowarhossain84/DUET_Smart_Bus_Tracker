# Implementation Plan: Fix Profile Screen Overflow

The `ProfileScreen` currently has a layout overflow issue on smaller screens because the "Logout" button is being pushed out of view by a `Spacer()` inside an `Expanded` widget.

## Proposed Changes

### [Component Name]

#### [MODIFY] [profile_screen.dart](file:///G:/android_project/DUET_project/duet_smart_bus_tracker/lib/profile_screen.dart)
- Wrap the entire `body` content in a `SingleChildScrollView` to ensure all elements are accessible on any screen size.
- Remove the `Expanded` widget wrapping the white container.
- Remove the `Spacer()` widget before the Logout button.
- Add a `SizedBox` with fixed height (e.g., `height: 40`) instead of the `Spacer()` to provide consistent padding between the list items and the logout button.
- Ensure the white container has a `BoxConstraints` or simply grows with its content.

## Verification Plan

### Manual Verification
- Launch the app and go to the **Profile** tab.
- Verify that the Logout button is now visible and there is no yellow/black overflow warning.
- Try scrolling to ensure the content is reachable if it exceeds the screen height.
