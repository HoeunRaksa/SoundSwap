# SoundSwap

SoundSwap is a Flutter Windows desktop app that replaces the original sound of
videos with audio files from a selected folder.

## Features

- Select a video folder, audio folder, and output folder.
- Scan videos with `.mp4`, `.mov`, and `.mkv` extensions.
- Scan audio with `.mp3`, `.wav`, and `.m4a` extensions.
- Match media by order and loop audio files when there are more videos.
- Export MP4 files named `original_name_soundswap.mp4`.
- Show current progress, success count, failed count, and a queue table.

## FFmpeg setup on Windows

SoundSwap calls the `ffmpeg` CLI from your system `PATH`.

1. Download a Windows FFmpeg build from [ffmpeg.org](https://ffmpeg.org/download.html).
2. Extract the archive, for example to `C:\ffmpeg`.
3. Add `C:\ffmpeg\bin` to your Windows `PATH`.
4. Open a new PowerShell window and verify:

   ```powershell
   ffmpeg -version
   ```

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

For each queued pair, SoundSwap runs the equivalent of:

```powershell
ffmpeg -i "video.mp4" -i "audio.mp3" -map 0:v -map 1:a -c:v copy -shortest "output.mp4"
```
