# SoundSwap

SoundSwap is a Flutter Windows desktop app that replaces the original sound of
videos with audio files from a selected folder.

## Features

- Select a video folder, audio folder, and output folder.
- Scan videos with `.mp4`, `.mov`, and `.mkv` extensions.
- Scan audio with `.mp3`, `.wav`, and `.m4a` extensions.
- Randomly choose an audio file for each video.
- Use a random audio start time when the audio is longer than the video.
- Loop shorter audio files so the replacement audio can cover the video.
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
