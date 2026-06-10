# Project Tasks - SoundSwap UX Upgrade

This file tracks the current SoundSwap batch generator UX improvements.

## Completed

- Unified Branding Tools, Text Overlay, and template management into **Overlay & Templates**.
- Added text and image overlay items with selection, drag positioning, resize support, remove action, and multi-line text.
- Added custom font file selection for overlay settings and FFmpeg `drawtext` preparation.
- Added template save, apply, rename, and delete actions inside the same overlay editor.
- Kept the existing batch audio replacement logic and bundled FFmpeg path workflow.
- Added optional Home generator controls:
  - Use Overlays
  - Use Template
  - Output size
  - Fit mode
- Added shared output naming:
  - `{prefix}-{number}.mp4`
  - scans the result folder
  - continues after the largest existing number
  - avoids overwrites
- Added watcher profiles:
  - profile name
  - source video folder
  - source audio folder
  - result folder
  - output prefix
  - optional template/overlay settings
  - independent start/stop
  - delete with confirmation
- Added result history process type:
  - `manual` for Home batch
  - `auto` for Folder Watcher
- Added Result History filtering and removal by All, Auto, or Manual.
- Removed the separate Templates sidebar screen.
- Templates now show text overlay count, image overlay count, font name, output prefix, output size, and fit mode.
- Added Home recent batch profiles:
  - auto-saved after a batch finishes successfully
  - stores folders, prefix, overlay/template selection, output size, and fit mode
  - add, select, edit, and delete actions
- Added persistent Home startup restore:
  - last video folder
  - last audio folder
  - last output folder
  - last selected template
  - last output prefix
  - last export settings
- Added explicit Home queue workflow:
  - Select folders
  - Generate Queue
  - Review queue
  - Start Batch
- Added queue controls:
  - remove one queued video
  - remove selected queued videos
  - clear queue
- Added generated queue snapshots:
  - queues are tied to the selected batch profile or manual folder setup
  - multiple profile queues can exist in one session
  - starting a batch only processes the selected queue
- Added Start Batch confirmation:
  - remove old numbered results for the current prefix and start fresh
  - keep old results and continue numbering
- Added result history metadata:
  - result folder
  - output prefix
  - date/time
  - total videos
- Added Result History result-folder filtering and folder-scoped cleanup actions.
- Added Folder Watcher profile edit and duplicate actions.
- Added Folder Watcher start-from-batch-profile flow.
- Improved Home batch profile cards:
  - service-card layout
  - stronger green, blue, orange, and white color usage
  - Start, Stop, Edit, Delete actions
  - stopped, queued, running, done statuses
- Improved Folder Watcher service cards:
  - Start Watch, Stop Watch, Edit, Delete actions
  - multiple watcher profiles can run at the same time
  - stopped profiles do nothing
- Added **Long Video Generator**:
  - video/audio/output folder selection
  - output name
  - target length in minutes
  - clip length in seconds
  - selected-audio or random-audio mode
  - Generate Plan, Start Export, Clear Plan actions
  - FFmpeg concat workflow using bundled `tools/ffmpeg/ffmpeg.exe`

## Overlay & Templates Usage

- Use **Add Text** for titles, prices, phone numbers, Telegram handles, Facebook names, or multi-line notes.
- Use **Add Image** for logos and product images.
- Select an overlay to edit, move, resize, or remove it.
- Use **Save Current as Template** to store the current overlays plus Home output prefix, output size, and fit mode.
- Use **Apply Template** to load saved settings back into the editor and Home generator configuration.
- Home batch and Folder Watcher profiles can both select saved templates.

## Home Batch Profiles

- Recent profiles are saved after a successful batch finish.
- Profile cards are the primary Home workflow.
- Clicking **Start** generates a queue and processes only that profile.
- Profiles that are not started do not process.
- Selecting/editing a profile restores folders, prefix, selected template, overlays, output size, and fit mode.
- Editing a profile opens a form for name, video folder, audio folder, output folder, and prefix.
- The last used Home setup is restored automatically on app startup.

## Queue Generation

- Folder selection scans folders but does not start processing.
- **Generate Queue** prepares the reviewable job list.
- Users can remove one video, remove selected videos, or clear the queue before batch start.
- Multiple generated queues can be created from different profiles.
- The selected queue chip controls which queue is processed.
- Start confirmation controls whether old numbered results for the current prefix are removed or numbering continues.

## Result History

- Records are filterable by All, Manual, Auto, and result folder.
- Cleanup actions include clearing selected-folder history and deleting recorded result files inside the selected folder.
- Manual and auto history can be removed separately with confirmation.

## Folder Watcher Profiles

- Profiles store video folder, audio folder, result folder, template, overlay settings, prefix, output size, and fit mode.
- Saved Home batch profiles can be selected and started directly from Folder Watcher.
- Profiles are displayed as service cards with Start Watch, Stop Watch, Edit, and Delete.
- Profiles can be edited, duplicated, deleted, and started or stopped independently.
- Multiple watcher profiles can run at the same time.
- All profile settings persist after restart.

## Long Video Generator

- Randomly picks short videos from a selected video folder.
- Does not duplicate picked videos until all available videos are already used.
- Uses the whole video when a source video is shorter than the requested clip length.
- Builds one combined MP4 result.
- Builds an audio plan that covers the final generated video duration.
- Avoids repeating random audio until all audio files are already used.
- Shows the generated plan before export:
  - selected clips
  - clip duration
  - selected audio files
  - estimated final duration
- Uses bundled FFmpeg and FFprobe only.
- Avoids overwriting existing output files.

## Validation Commands

Run these before release:

```powershell
flutter pub get
dart analyze
flutter test
flutter build windows
```

## Notes

- If no Home generator options are enabled, SoundSwap keeps the current audio replacement behavior.
- FFmpeg is still resolved from `tools/ffmpeg/ffmpeg.exe` and `tools/ffmpeg/ffprobe.exe`.
- The app does not depend on the Windows PATH.
