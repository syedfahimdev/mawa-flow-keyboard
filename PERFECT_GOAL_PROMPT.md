# Perfect Goal Prompt — Mawa Flow Keyboard

Use this prompt when asking Hermes/Codex/Claude Code to build the app phase-by-phase.

---

## Copy/Paste Prompt

You are building **Mawa Flow Keyboard**, an iPhone custom keyboard app that starts as a simple Whisper Flow / Aqua / Willow alternative and later becomes a context-aware AI keyboard with skills and API actions.

Before coding, read these project docs:

1. `/root/workspace/mawa-flow-keyboard/README.md`
2. `/root/workspace/mawa-flow-keyboard/DESIGN_RESEARCH.md`

## Product Goal

Build a native iOS MVP that lets a user install a custom keyboard, press a Mawa mic/action button, speak or simulate speech, generate/preview polished text, and insert it into the active text box.

The product should feel inspired by Wispr Flow, Aqua, Willow, and Superwhisper, but must use Mawa’s own brand: warm, fast, practical, privacy-aware, voice-native, and agent-ready.

## Build Strategy

Build phase-by-phase. Do **not** attempt the full agent platform in phase 1.

### Phase 1 — Installable Keyboard MVP

Deliver an installable iOS app with:

1. SwiftUI host app.
2. iOS custom keyboard extension.
3. Onboarding explaining how to enable the keyboard.
4. Keyboard UI with:
   - Mawa branding
   - mode chips: Auto, Dictate, Reply, Prompt, Rewrite
   - a central mic/action button
   - preview panel
   - Insert, Clear, Regenerate placeholders
   - globe/next-keyboard button
5. Text insertion into active field using `textDocumentProxy.insertText()`.
6. A local simulated pipeline first:
   - user taps a sample phrase or types demo text inside keyboard
   - app generates a polished response using deterministic local templates
   - result can be inserted
7. Basic shared App Group settings if needed.
8. No cloud dependency required for Phase 1.

The first phase must be simple enough that I can build/run/install it quickly in Xcode/TestFlight/local device.

### Phase 1 Acceptance Criteria

- App builds in Xcode.
- Keyboard extension appears in iOS keyboard settings.
- Keyboard can be selected in any normal text field.
- Pressing Mawa action button creates a visible preview.
- Pressing Insert inserts text into the active text box.
- Next keyboard/globe behavior works.
- UI is polished enough to demo.
- No hardcoded private secrets.
- No overpromising screen reading or background access.

### Phase 2 — Real Voice Input

After Phase 1 works:

1. Add microphone permission flow.
2. Add speech recognition with Apple Speech framework first.
3. Consider WhisperKit local STT after the Apple Speech path is stable.
4. Stream or show transcript in the keyboard preview.
5. Add fallback when speech is unavailable.

### Phase 3 — LLM Intent Engine

Add intent modes:

- dictate_clean
- message_reply
- prompt_builder
- rewrite_existing
- question_answer
- translate

Use a minimal backend endpoint or BYO API key. Keep a local deterministic fallback for offline demos.

### Phase 4 — Context Capture

Add explicit context sources only:

- cursor context from `textDocumentProxy.documentContextBeforeInput`
- clipboard context with user consent
- share sheet extension
- screenshot/OCR import later

Do not claim silent screen reading across apps.

### Phase 5 — Skills / Connectors

Add permissioned skills:

- calendar.find_times
- gmail.search_recent
- slack.draft_reply
- notion.search_pages
- web.search
- custom_api.fetch

Read actions may run after permission. Write/send actions must require explicit confirmation and audit logging.

## Design Requirements

Use the design research doc for inspiration. The app should combine:

- Wispr Flow’s clear before/after transformation
- Aqua’s calm minimal productivity feel
- Willow’s friendly SaaS cards and simple 3-step onboarding
- Superwhisper’s advanced modes/customization energy

But do not copy their branding. Use Mawa’s own design:

- warm ivory/light background
- deep teal primary
- soft violet accent
- rounded iOS-native cards
- pill mode chips
- large friendly mic/action button
- clear privacy/context badges

## Engineering Rules

1. Native iOS preferred: SwiftUI + Keyboard Extension.
2. Keep Phase 1 deterministic and local.
3. No complex backend unless the phase explicitly requires it.
4. Keep files organized and documented.
5. Use small, verifiable tasks.
6. After every phase, run/build/test and report real results.
7. Do not claim the app can silently read the whole iPhone screen.
8. Side effects like sending messages or API writes must require confirmation.
9. Prioritize installability and demoability over perfect architecture.

## Deliverables for Phase 1

- Xcode project or Swift Package/app structure.
- Host app source.
- Keyboard extension source.
- README with build/install steps.
- Screens implemented:
  - Welcome/onboarding
  - Enable keyboard instructions
  - Settings/privacy explanation
  - Demo text field
  - Keyboard UI
- A short test checklist.

## Output Format

When implementing, provide:

1. What you built.
2. Files created/modified.
3. Exact commands or Xcode steps to run.
4. Verification results.
5. Known limitations.
6. Next recommended phase.

Start by inspecting whether a repo/project already exists. If not, create the project structure under:

`/root/workspace/mawa-flow-keyboard/app`

Then implement **Phase 1 only**.

---

## Short Version

Build Phase 1 of Mawa Flow Keyboard: a native iOS SwiftUI app plus custom keyboard extension. The keyboard should show Mawa mode chips, a mic/action button, a preview panel, and insert generated text into the active text box. Use deterministic local demo text for now. Follow `/root/workspace/mawa-flow-keyboard/README.md` and `/root/workspace/mawa-flow-keyboard/DESIGN_RESEARCH.md`. Keep it installable, simple, privacy-aware, and demo-ready. Do not build real voice, LLM, screen reading, or skills until later phases.
