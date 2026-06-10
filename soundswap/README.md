# SoundSwap

SoundSwap is a Flutter Windows desktop app for batch video generation. It can
keep the original workflow of replacing video audio, or optionally add branding,
text overlays, and vertical output sizing during export.

## Features

- Select a video folder, audio folder, and output folder.
- Local FFmpeg binaries (`ffmpeg.exe` and `ffprobe.exe`) resolved from `tools/ffmpeg/`.
- Scan videos with `.mp4`, `.mov`, `.mkv`, and `.avi` extensions.
- Scan audio with `.mp3`, `.wav`, `.m4a`, and `.aac` extensions.
- Randomly choose an audio file for each video.
- Use a random audio start time when the audio is longer than the video.
- Loop shorter audio files so the replacement audio can cover the video.
- Export MP4 files with numbered names using the selected prefix, such as `soundswap-1.mp4`.
- Show current progress, success count, failed count, and a queue table.
- Generate and review the queue before starting a batch.
- Save recent batch profiles automatically after a batch finishes successfully.
- Optional Home controls for overlays, templates, output size, and video fit mode.
- Business screens for Overlay & Templates, smart folder watcher profiles, Long Video Generator, result history, effects prep, and CSV product import.

If no generator options are enabled, SoundSwap keeps the existing audio
replacement workflow and FFmpeg command path.

## Business tools

SoundSwap includes separate feature screens that prepare business metadata
without changing the default batch audio replacement flow:

- **Overlay & Templates**: add text overlays and image/logo overlays, select each item, move and resize it on a vertical preview, choose colors/fonts, and save the current overlay setup as a template. Templates can be applied, renamed, and deleted from the same screen. Phone, Telegram, and Facebook are normal text overlays.
- **Folder Watcher**: create multiple watcher profiles. Each profile stores source video folder, source audio folder, result folder, output prefix, and optional template/overlay settings. Profiles are shown as service cards and can run independently.
- **Long Video Generator**: build one long MP4 by randomly selecting short video clips and matching audio from selected folders.
- **Result History**: review auto and manual results, filter by process type or result folder, open result folders, remove records, delete result files, clear folder history, and remove duplicate results safely.
- **Effects**: prepare optional random audio/effect toggles. Defaults are off.
- **Product Import**: import CSV rows with `name`, `price`, `description`, and `phone` columns.

## Generator options

Home screen generator options are optional:

- **Use Overlays** applies the current Overlay & Templates overlay setup.
- **Use Template** loads a saved template, including overlays, output prefix, output size, and fit mode when available.
- **Output size** supports Original Size, 720 x 1280, 1080 x 1920, and 2160 x 3840 vertical output.
- **Fit mode** supports Keep Original, Fit Inside + Blurred Background, Fill and Crop, and Stretch.

When overlays or resizing are enabled, SoundSwap first runs the existing audio
replacement step, then runs a separate FFmpeg overlay/render step against the
completed output. This keeps the current audio workflow compatible.

## Home Batch Profiles

When a batch finishes successfully, SoundSwap saves or updates a recent batch profile.
Profiles store:

- Video folder, audio folder, and output folder.
- Output prefix.
- Overlay and template selections.
- Output size and fit mode.

Use **Recent Batch Profiles** on Home to add, edit, or delete profiles such as
`Daily Cats`, `Daily Dogs`, `Furniture Page`, or `PVC Ceiling`. Profiles are
shown as service cards, similar to containers. Each card shows the profile name,
video folder, audio folder, output folder, prefix, and status:

- `stopped`
- `queued`
- `running`
- `done`

Click **Start** on a profile card to generate a queue for only that profile and
start that profile's batch. Profiles that are not started do not process.
Click **Stop** to stop after the current file. Manual folder fields remain for
one-off work, but saved profiles are the main workflow. SoundSwap also restores
the last used folders, template, prefix, and export settings on startup.

## Queue Generation

Home uses this workflow:

1. Select video, audio, and output folders.
2. Select a saved batch profile, or use the current folders manually.
3. Click **Generate Queue**.
4. Review the compact queue table.
5. Remove one video, remove selected videos, or clear the queue if needed.
6. Click **Start Batch**.

You can generate queues from different batch profiles in one session. Each
queue keeps its own profile, folder paths, output prefix, overlay/template
settings, and queued videos. Select the queue chip before starting; SoundSwap
only processes the selected queue.

Before processing starts, SoundSwap shows a confirmation dialog:

- **Remove old results and start fresh** deletes existing numbered result files
  for the current prefix in the selected result folder.
- **Keep old results and continue numbering** scans the result folder and
  continues from the next available number.

Existing files are never overwritten.

## Overlay & Templates

Use **Overlay & Templates** to build reusable video layouts:

- Click **Add Text** for titles, prices, phone numbers, Telegram handles, Facebook page names, or any multi-line text.
- Click **Add Image** for logo/image overlays.
- Select an overlay from the list or preview, then edit text, font, color, size, shadow, background box, or remove it.
- Drag overlays on the preview and resize them with the preview resize handle.
- Click **Save Current as Template** to store the current overlay setup with the current Home output prefix, output size, and fit mode.
- Click **Apply Template** to load a saved template back into the editor and Home generator settings.

Home batch can use saved templates with **Use Template**. Folder Watcher
profiles can also select one saved template, and auto processing uses that
template's overlay/export settings.

## Output naming

Home batch and Folder Watcher profiles use the same naming rule:

- The selected prefix defaults to `soundswap`.
- SoundSwap scans the result folder before processing.
- It finds the biggest existing number matching `{prefix}-{number}.mp4`.
- The next export continues from the next number.

Example: if `mydaily-1.mp4` and `mydaily-2.mp4` exist, the next result is
`mydaily-3.mp4`. Existing files are not overwritten.

## Folder Watcher Profiles

Folder Watcher can start directly from a saved Home batch profile. Select the
batch profile and click **Start Watch**; the watcher uses that profile's video
folder, audio folder, output folder, prefix, template, overlay settings, output
size, and fit mode.

Folder Watcher profiles also store source video folder, source audio folder,
result folder, template, overlay settings, output prefix, output size, and fit
mode. Profiles are shown as service cards with **Start Watch**, **Stop Watch**,
**Edit**, and **Delete** actions. Multiple watcher profiles can run at the same
time. Stopped profiles do not watch folders or process files. All watcher
profile settings are remembered after app restart.

## Long Video Generator

Use **Long Video Generator** to create one long video from short clips:

1. Select a video folder, audio folder, and output folder.
2. Enter an output name.
3. Set the target length in minutes.
4. Set the clip length per short video in seconds.
5. Choose an audio mode:
   - **Use one selected audio file**
   - **Pick random audio files from folder**
6. Click **Generate Plan** to preview selected clips, audio files, and estimated duration.
7. Click **Start Export** to create the final MP4.

Video selection is random. Videos are not duplicated until the available folder
videos are already used; if the target length is not reached after all videos
are used, SoundSwap exports the current planned duration. If a source video is
shorter than the clip length, the whole video is used.

Audio segments are selected to cover the generated video duration. Random audio
mode avoids repeats until all audio files have been used, then repeats if
needed. Output names avoid overwriting by appending a number when needed.

## Manual vs Auto History

Result History stores a process type for every recorded result:

- `manual`: exported from the Home batch screen.
- `auto`: exported by a Folder Watcher profile.

History records also store result folder, output prefix, date/time, and total
videos for the batch. Use the filters to view All, Manual, Auto, or a selected
result folder. Cleanup actions require confirmation and include:

- Clear history for the selected folder.
- Remove result files from the selected folder.
- Remove only auto history.
- Remove only manual history.

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
