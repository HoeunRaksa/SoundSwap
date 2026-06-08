# SoundSwap

SoundSwap is a Flutter Windows desktop app that replaces the original sound of
videos with audio files from a selected folder.

## Features

- Select a video folder, audio folder, and output folder.
- Local FFmpeg binaries (`ffmpeg.exe` and `ffprobe.exe`) resolved from `tools/ffmpeg/`.
- Scan videos with `.mp4`, `.mov`, `.mkv`, and `.avi` extensions.
- Scan audio with `.mp3`, `.wav`, `.m4a`, and `.aac` extensions.
- Randomly choose an audio file for each video.
- Use a random audio start time when the audio is longer than the video.
- Loop shorter audio files so the replacement audio can cover the video.
- Export MP4 files named `original_name_soundswap.mp4`.
- Show current progress, success count, failed count, and a queue table.
- Business screens for branding, text overlay prep, project templates, smart folder watching, result history, effects prep, and CSV product import.

## Business tools

SoundSwap includes separate feature screens that prepare business metadata
without changing the current batch audio replacement flow:

- **Branding Tools**: save a logo path, phone number, Telegram, and Facebook page name, with prepared FFmpeg overlay preview text.
- **Text Overlay**: save title, subtitle, promotion text, and position, with prepared `drawtext` preview text.
- **Templates**: save, load, rename, and delete video/audio/output folder templates, output prefix, branding settings, and text overlay settings.
- **Folder Watcher**: remember source video, source audio, and result folders, then auto-process new videos after copying finishes.
- **Result History**: review watcher results, open result folders, remove records, delete result files, clear result folders, and remove duplicate results safely.
- **Effects**: prepare optional random audio/effect toggles. Defaults are off.
- **Product Import**: import CSV rows with `name`, `price`, `description`, and `phone` columns.

## FFmpeg setup on Windows

SoundSwap runs FFmpeg silently from the project's `tools/ffmpeg/` directory.
It does not use the global Windows `PATH` and does not ask users to install
FFmpeg from inside the app.

### Development Setup
Before running the application in development, download the required Gyan FFmpeg
release essentials binaries:

```powershell
dart run tools/download_ffmpeg.dart
```

This helper script will:
- Download `ffmpeg-release-essentials.zip` from Gyan FFmpeg Builds.
- Extract only `ffmpeg.exe` and `ffprobe.exe` into `tools/ffmpeg/`.
- Clean up temporary zip files.

### Release Build Bundling
When building the app using `flutter build windows`, the CMake script automatically copies the `tools/ffmpeg/` directory to the release folder alongside the executable. The app resolves these paths automatically without depending on system `PATH`.

## Run

```powershell
flutter pub get
flutter run -d windows
```

## Build

```powershell
flutter build windows
```

## FFmpeg command

SoundSwap first reads video and audio durations with `ffprobe`.

When the selected audio is longer than the video, SoundSwap uses a random start
position:

```powershell
ffmpeg -y -i "video.mp4" -ss RANDOM_START -i "audio.mp3" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -t VIDEO_DURATION -shortest "output.mp4"
```

When the selected audio is shorter than or equal to the video, SoundSwap loops
the audio:

```powershell
ffmpeg -y -i "video.mp4" -stream_loop -1 -i "audio.mp3" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -t VIDEO_DURATION "output.mp4"
```
