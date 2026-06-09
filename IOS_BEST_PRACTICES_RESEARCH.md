# Mawa Flow Keyboard — iOS Best Practices & Constraint Research

Date: 2026-06-09

## Sources checked

- Apple Developer: Creating a custom keyboard
- Apple Developer: Configuring open access for a custom keyboard
- Apple Developer: UIInputViewController `hasDictationKey`
- Apple Developer: App Groups entitlement
- Mawa Flow current architecture/spec docs

## Summary

Mawa Flow should be built as a native iOS app with a custom keyboard extension, plus additional approved extension points over time. There is no safe or App-Store-compatible loophole that lets an iPhone app silently read the whole screen, hijack Apple’s dictation mic, or run a global always-on assistant across other apps. The right strategy is to combine Apple-supported surfaces:

1. Custom Keyboard Extension for text insertion.
2. Host app for permissions, onboarding, settings, model downloads, and history.
3. Share Extension for explicit context capture from other apps.
4. Safari Web Extension for webpage context later.
5. App Intents / Shortcuts for approved actions and automation.
6. App Groups for shared settings/data between host app and extensions.
7. Server/API connectors for skills, with user confirmation for side effects.

## Apple custom keyboard facts

Apple says custom keyboards are enabled by the user in Settings and become available systemwide where third-party keyboards are supported. Apple’s template creates a keyboard extension target that Xcode includes in the containing app bundle.

Important requirements:

- The keyboard extension must be embedded in the app bundle under `PlugIns/*.appex`.
- The keyboard target needs a clear display name; Settings uses it in the third-party keyboard list.
- The keyboard must offer a way to switch keyboards.
- Use `textDocumentProxy.insertText(...)` to insert text.
- Use `textDocumentProxy.selectedText`, `documentContextBeforeInput`, and related APIs for limited text context.
- Test in portrait, landscape, and iPad floating/regular widths.
- Keep memory usage low; keyboard extensions run in a separate process and can be killed if they exceed memory limits.

## Open Access facts

By default, custom keyboards run in a sandbox that:

- disallows network access;
- prevents writing to shared app group containers;
- provides no access to microphone and speaker;
- prevents participation in iCloud/Game Center/IAP from the keyboard.

Setting `RequestsOpenAccess = true` allows network/server-backed features and shared container write access, but the user must explicitly enable “Allow Full Access” in Settings. Apple warns that keyboards handle sensitive data, so we need clear user trust design.

Implication for Mawa:

- Phase 1 can keep `RequestsOpenAccess = false` because it is local demo text insertion.
- Real LLM calls from the keyboard require `RequestsOpenAccess = true`.
- For privacy, we should not turn Full Access on until the UI clearly explains why.
- If possible, route heavy/network work through the host app or explicit actions, but a keyboard extension still needs Full Access for direct network.

## Microphone / dictation reality

Apple’s docs show `hasDictationKey`, but this property only tells iOS whether the keyboard already provides a dictation key so iOS does not show a duplicate disabled/system dictation button. It is not a loophole to hijack Apple’s own dictation mic.

Important design decision:

- Do not rely on Apple’s built-in keyboard mic.
- Build our own Mawa mic UI.
- Real audio capture from a keyboard extension may be limited/fragile. If microphone is blocked or unreliable in the extension, use the host app or a separate recording flow and hand the result back via shared storage/clipboard/insert flow.

## Screen/context “loophole” reality

There is no good loophole for silent cross-app screen reading on iOS. Apple intentionally blocks that.

Approved/context-safe alternatives:

1. `textDocumentProxy` context around cursor.
2. Clipboard context after user copies text and grants paste access.
3. Share Extension where the user explicitly shares content to Mawa.
4. Screenshot import where the user explicitly selects an image; run OCR/Vision.
5. Safari extension for webpage-specific context.
6. App/API connectors where the user authenticates and grants access.
7. App Intents / Shortcuts for explicit actions.

Marketing/product wording should say: “Use context you choose” rather than “Mawa reads your screen.”

## Best architecture

### Recommended module layout

```text
MawaFlow/
├── HostApp SwiftUI
│   ├── onboarding
│   ├── settings/privacy
│   ├── model/API setup
│   ├── history
│   └── connector management
│
├── KeyboardExtension UIKit
│   ├── UIInputViewController
│   ├── mode chips
│   ├── preview panel
│   ├── insert text
│   └── minimal runtime only
│
├── SharedCore
│   ├── intent models
│   ├── prompt templates
│   ├── local deterministic fallback
│   ├── privacy/context labels
│   └── shared serialization types
│
├── ShareExtension later
│   └── explicit context capture
│
├── SafariExtension later
│   └── webpage context capture
│
└── Backend/Skills later
    ├── LLM gateway
    ├── connector registry
    ├── audit log
    └── confirmation-required writes
```

### Keyboard extension best practices

- Keep the keyboard extension lightweight.
- Avoid big models inside the keyboard extension.
- Avoid long blocking network calls on the main thread.
- Use a state machine: idle → drafting/listening → processing → preview → inserted/error.
- Always preview long generated text before insertion.
- Always include a keyboard switch/globe path.
- Avoid assuming secure/password fields will allow the keyboard.
- Make UI responsive to varying keyboard heights/widths.

### Host app best practices

- Put permissions in the host app, not hidden in the keyboard.
- Explain Full Access with plain language.
- Store privacy settings/history in an App Group only if entitlements are properly configured.
- Add a test field in the host app to debug insertion and UI.
- Add diagnostics page: app version, extension version, bundle IDs, signer info if readable, keyboard setup checklist.

### Signing/distribution best practices for sideloading

- Keyboard extension must be signed, not only the main app.
- Keep the main and extension bundle IDs stable across updates.
- Extension bundle ID should be under the main bundle namespace, e.g.:
  - `com.mawa.flow`
  - `com.mawa.flow.keyboard`
- Installing a new signed IPA over the same bundle ID should behave like an update.
- If the keyboard does not show in Settings, likely causes are:
  1. signer removed `PlugIns/*.appex`;
  2. signer did not sign nested extension;
  3. provisioning profile does not cover extension bundle ID;
  4. bundle ID changed between builds;
  5. app was not fully reinstalled after failed signing.

## Recommended phases after 0.1.3

### Phase 1.1 — Make install/sign diagnostics easier

- Add a diagnostics screen in the host app.
- Show exact app/extension bundle IDs and version.
- Add “Keyboard setup checklist.”
- Add a simpler plain keyboard UI fallback to prove the extension loads.
- Add `hasDictationKey = true` only if/when we provide a real dictation control.

### Phase 2 — Text-first AI without mic

- Enable Full Access only with clear explanation.
- Add BYO API key / server endpoint.
- Let user type/paste rough text inside keyboard and get AI rewrite/response.
- This validates network and intent routing before microphone complexity.

### Phase 3 — Voice

- Test microphone capture path.
- If keyboard mic is unreliable, use host app recording + share/clipboard/insert workflow.
- Add Apple Speech first; WhisperKit later.

### Phase 4 — Explicit context

- Cursor context via `textDocumentProxy`.
- Clipboard context.
- Share extension.
- Screenshot OCR.

### Phase 5 — Skills/actions

- Calendar/Gmail/Slack/Notion/Web connectors.
- Read actions can run after permission.
- Write/send actions require confirmation.
- Add audit log.

## Recommendation before installing 0.1.3

Install 0.1.3 only as a keyboard-extension/signing test. It is not yet the real voice product.

Expected from 0.1.3:

- Host app opens.
- If signed correctly, “Mawa Flow Keyboard” appears under Settings → General → Keyboard → Keyboards → Add New Keyboard.
- Keyboard can insert local deterministic preview text.

Not expected yet:

- microphone recording;
- live transcription;
- LLM replies;
- screen reading;
- skills/connectors.

If 0.1.3 does not show in Keyboard settings, do not spend time testing app UI; fix Feather signing of the embedded `.appex` first.
