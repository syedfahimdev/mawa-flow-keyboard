# Mawa Flow Keyboard — Phase 1 App

This folder contains the Phase 1 iOS implementation for **Mawa Flow Keyboard**.

Phase 1 is intentionally local and deterministic: it proves the custom keyboard can show a Mawa UI, generate a preview, and insert generated text into the active text field.

## What is included

- SwiftUI host app: onboarding, demo lab, privacy explanation.
- Custom keyboard extension: mode chips, Mawa action button, local preview, Insert/Clear/Shorter/Warmer/Regenerate, globe/next keyboard.
- Shared deterministic generation engine used by both host app and keyboard.
- XcodeGen `project.yml` for generating an Xcode project.

## What is not included yet

- Real microphone input.
- Apple Speech / WhisperKit transcription.
- Cloud LLM calls.
- Screen reading.
- Skills/connectors.

Those are later phases.

## Build on macOS

This Linux server cannot run Xcode or produce an installable iPhone build. On a Mac:

```bash
cd /root/workspace/mawa-flow-keyboard/app
brew install xcodegen
xcodegen generate
open MawaFlowKeyboard.xcodeproj
```

In Xcode:

1. Select the `MawaFlow` target.
2. Set your Apple Developer Team under **Signing & Capabilities**.
3. Set bundle IDs if needed:
   - `com.mawa.flow`
   - `com.mawa.flow.keyboard`
4. Choose a physical iPhone or simulator.
5. Build and run the `MawaFlow` app.

## Enable the keyboard on iPhone

After installing the app:

1. Open iOS **Settings**.
2. Go to **General → Keyboard → Keyboards**.
3. Tap **Add New Keyboard…**.
4. Select **Mawa Flow Keyboard**.
5. Open Notes/iMessage/any normal text field.
6. Tap the globe key and switch to Mawa Flow.

Phase 1 does **not** require “Allow Full Access” because there are no network calls.

## Test checklist

- [ ] Host app opens and shows onboarding.
- [ ] Demo Lab generates local previews.
- [ ] Keyboard appears in iOS keyboard settings.
- [ ] Keyboard can be selected in a normal text field.
- [ ] Mode chips change the preview intent.
- [ ] Sample buttons generate previews.
- [ ] Insert writes preview text into the active text box.
- [ ] Globe button advances to the next keyboard.
- [ ] Clear clears the preview.
- [ ] Shorter/Warmer transforms work.

## Phase 2 next

Add real voice:

1. Microphone permission in host app.
2. Speech recognition permission.
3. Apple Speech transcription pipeline.
4. Keyboard state for listening/transcribing.
5. Fallback when speech is unavailable.
