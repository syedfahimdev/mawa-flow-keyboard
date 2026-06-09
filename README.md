# Mawa Flow Keyboard MVP

A Whisper Flow / Aqua-style iPhone keyboard MVP: speak naturally, transcribe, infer intent, generate the right text, and insert it into the current text field.

## Product Thesis

Most dictation tools do `speech -> transcript -> cleanup`. Mawa Flow should do `speech -> transcript -> context -> intent -> action/text -> insert`.

The first version should feel like a fast AI keyboard, not a full autonomous agent. The roadmap can later add screen/context understanding, skills, API connectors, and action triggers.

## MVP Scope

### Must ship first

1. iOS host app with onboarding and keyboard setup instructions.
2. Custom keyboard extension with:
   - mic button
   - mode selector: Auto, Dictate, Reply, Prompt, Rewrite, Ask
   - preview panel
   - Insert / Regenerate / Shorter / Warmer controls
3. Speech-to-text:
   - MVP: Apple Speech framework for fastest implementation.
   - Next: WhisperKit local model option.
4. Intent engine:
   - classify spoken input into a small intent set.
   - generate polished text using cloud LLM or BYO key.
5. Text insertion into active field via `textDocumentProxy.insertText()`.
6. Shared app group storage for settings/history between host app and keyboard.
7. Privacy-first settings:
   - local transcript history on/off
   - cloud AI on/off
   - BYO API key support

### Out of MVP

- Full screen reading.
- Fully local LLM.
- Autonomous background actions.
- Complex API connectors.
- App Store-perfect billing.
- Voice cloning/TTS.

These are phase 2+ features.

## iOS Reality / Constraints

- We cannot hijack Apple’s built-in keyboard microphone.
- We can build a custom keyboard with our own mic button.
- Some fields do not allow custom keyboards: password fields, some banking/medical apps, phone/number fields, and apps that disable third-party keyboards.
- Keyboard extensions need user-enabled “Allow Full Access” for network calls and shared write access. This creates trust/privacy friction.
- Keyboard extensions have limited context: nearby text around cursor, not the full screen.
- True global screen reading is not allowed like desktop. iOS-safe context capture needs explicit user action: share sheet, clipboard permission, screenshots/import, or app-specific integrations.

## Architecture

```text
Mawa Flow iOS App
├── Host App
│   ├── onboarding / keyboard install guide
│   ├── permissions: mic, speech recognition
│   ├── settings: API key, privacy, modes, style profile
│   ├── history and saved snippets
│   └── connector management later
│
├── Keyboard Extension
│   ├── UIInputViewController
│   ├── mic / recording controls
│   ├── mode chips
│   ├── text preview and action buttons
│   ├── textDocumentProxy.insertText(output)
│   └── reads settings from App Group
│
├── Voice Pipeline
│   ├── record audio
│   ├── STT: Apple Speech first, WhisperKit later
│   └── transcript normalization
│
├── Intent Pipeline
│   ├── context collector: cursor text + mode + app hints if available
│   ├── intent classifier
│   ├── prompt renderer
│   └── LLM call / local model later
│
└── Mawa Backend Optional
    ├── /v1/voice-intent
    ├── provider routing / BYO key proxy
    ├── skills registry later
    ├── connector execution later
    └── audit logs
```

## Intent Types

```json
[
  "dictate_clean",
  "message_reply",
  "email_reply",
  "prompt_builder",
  "rewrite_existing",
  "question_answer",
  "translate",
  "summarize_context",
  "task_create",
  "api_action"
]
```

## MVP API Contract

`POST /v1/voice-intent`

Request:

```json
{
  "mode": "auto",
  "transcript": "reply saying I checked it and it is probably missing an API key but make it professional",
  "context_before": "",
  "context_after": "",
  "style_profile": "warm_direct",
  "target_app_hint": "unknown",
  "locale": "en-US"
}
```

Response:

```json
{
  "intent": "message_reply",
  "output": "I checked this, and it looks like the issue may be related to a missing API key. I’ll verify the configuration and follow up with next steps.",
  "confidence": 0.86,
  "suggested_actions": ["insert", "shorter", "warmer"]
}
```

## Roadmap

### Phase 1 — Dictation MVP

Goal: prove the keyboard can capture speech and insert text into any normal text field.

- SwiftUI host app.
- Keyboard extension.
- Basic microphone flow.
- Apple Speech transcription.
- Insert raw/cleaned text.
- Simple cloud cleanup endpoint.

### Phase 2 — Intent AI

Goal: make it better than dictation.

- Auto intent classification.
- Reply / Prompt / Rewrite / Ask modes.
- Style profiles.
- Regenerate and transforms.
- Local history.

### Phase 3 — Explicit Context Capture

Goal: use context without violating iOS privacy/sandbox rules.

- Read `documentContextBeforeInput` and `documentContextAfterInput` from the active field.
- “Use Clipboard as Context” with iOS paste permission.
- Share Sheet extension: send selected text/page into Mawa Flow.
- Screenshot import: user manually shares screenshot; OCR and summarize.
- Safari extension later for web-page context.

### Phase 4 — Skills / Actions

Goal: speak commands that fetch data or trigger workflows.

- Skill registry with strict permission scopes.
- Connectors: Notion, Gmail, Calendar, Slack, Linear, Supabase, web search.
- Action confirmation UI before side effects.
- Audit log in host app.
- Example: “check my calendar and reply with two times tomorrow.”

### Phase 5 — Local-first Power Mode

Goal: reduce per-request cost and improve privacy.

- WhisperKit local STT.
- Small local intent classifier.
- Optional local LLM for simple rewrites.
- Hybrid cloud fallback for hard tasks.

## Screen Reading Strategy

True background screen reading across all iOS apps is not realistic. Use explicit, privacy-safe context capture instead:

1. Active text field context via keyboard APIs.
2. Clipboard context after user copies text.
3. Share Sheet extension for selected content/pages.
4. Manual screenshot-to-OCR context.
5. App-specific connectors where APIs exist.

For App Store trust, never imply the keyboard silently reads the screen.

## Skills / Connector Safety Model

Skills should be small, permissioned tools. Examples:

- `calendar.find_times`
- `gmail.search_recent`
- `notion.search_pages`
- `slack.draft_reply`
- `web.search`
- `supabase.query_readonly`
- `http.fetch_url`

Rules:

- Read actions can run after permission.
- Write/send actions require explicit confirmation.
- Show exactly what will be sent/changed.
- Keep an audit log.
- Let users disable any skill.

## Competitive Differentiation

- Intent-first, not transcript-first.
- Built for AI prompts and agent workflows.
- BYO key / BYO backend support to control costs.
- Privacy modes: on-device where practical, explicit context capture.
- Skills/connectors turn voice into useful actions, not just polished writing.

## Open Questions

1. Should the first test device target iPhone 15/16 only or older devices too?
2. Should MVP use Apple Speech first or WhisperKit first?
3. Should AI mode call OpenAI/Anthropic directly from device with BYO key, or route through Mawa backend?
4. Do we want App Store distribution or TestFlight/private build first?
5. What is the first killer workflow: iMessage replies, ChatGPT prompts, Gmail replies, or Slack updates?
