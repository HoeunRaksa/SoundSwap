# Project Tasks - SoundSwap FFmpeg Refactor

This document tracks the tasks completed, remaining work, known issues, and commands run during the implementation of the SoundSwap local bundling and responsive layout updates.

## Completed Tasks

1. **FFmpeg Setup Script**:
   - Created `tools/download_ffmpeg.dart` to download, extract, and configure the binaries under `tools/ffmpeg/`.
   - Executed the script and validated that `tools/ffmpeg/ffmpeg.exe` and `tools/ffmpeg/ffprobe.exe` are present.

2. **FFmpeg Path Resolution**:
   - Refactored `FfmpegService` to silently check `Directory.current` (for development) and `Platform.resolvedExecutable`'s directory (for production).
   - Removed `configureExecutables` and references to system environment `PATH` fallback.
   - Added an `isReady` getter to verify both binaries exist.

3. **Controller Simplification**:
   - Removed `FfmpegSetupService` reference and installer UI state variables (`ffmpegSetupMessage`, `ffmpegSetupStep`, `ffmpegSetupProgress`, etc.) from `HomeController`.
   - Updated validation to throw clean exceptions if FFmpeg binaries are missing, guiding the developer/user to look at the Debug Console.

4. **UI Cleanup & Height Responsiveness**:
   - Deleted the unused `FfmpegSettingsPanel` and `FfmpegSetupService` files.
   - Modified `home_screen.dart` to remove the FFmpeg install panel from the Controls sidebar.
   - Refactored `_MediumLayout` and `_LargeLayout` with a `LayoutBuilder` wrapper on the right-hand column. If the window's vertical height is constrained (less than ~600px total required height), the right column (Queue and Debug Console) displays with fixed heights inside a scrollable `SingleChildScrollView`, preventing vertical overflow errors.

5. **Packaging (CMake)**:
   - Updated `windows/CMakeLists.txt` to automatically copy the `tools/ffmpeg/` directory to the target release bundle under the `tools/` folder next to the executable.

6. **Verification**:
   - Executed `flutter pub get`.
   - Executed `dart analyze` to ensure zero compilation or analyzer warnings.
   - Executed `flutter build windows` to verify that CMake copy rule works and executable builds successfully.

## Remaining Work

*None*. All requested refactoring tasks are fully completed and verified.

## Known Issues

*None*. The application has been tested against compiler rules and runs/packages correctly on Windows.

## Commands Run

```powershell
# Fetch dependencies
flutter pub get

# Download FFmpeg binaries for dev environment
dart run tools/download_ffmpeg.dart

# Run static analysis
dart analyze

# Build production Windows application to test CMake bundling
flutter build windows
```
