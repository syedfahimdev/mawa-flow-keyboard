# Mawa Flow Keyboard — Design Research

Date: 2026-06-09

## Research Targets

Reviewed current public product pages and visible UI/positioning for:

- Wispr Flow — https://wisprflow.ai/
- Aqua Voice — https://aquavoice.com/
- Willow Voice — https://willowvoice.com/
- Superwhisper — https://superwhisper.com/

Goal: learn category design patterns for a Whisper Flow-style voice keyboard, then define an original Mawa-branded direction.

---

## Category Patterns

### 1. Core positioning is speed + polish

Repeated claims:

- “Don’t type, just speak.”
- “Write 4x/5x faster.”
- “Turn your voice into clear/polished text.”
- “Works in every app.”
- “Speak naturally; AI edits/understands.”

**Mawa takeaway:** Use direct language: “Speak messy. Mawa writes clearly.” The product should feel like an always-ready writing layer, not a note-taking app.

### 2. UI demos are more important than feature lists

All competitors show visual before/after or app-context demos:

- Wispr Flow: rambling speech transformed into polished text, app icon arcs, message composer UI.
- Aqua: writing surface, real-time document/editor panels, coding/prompting examples.
- Willow: side-by-side manual typing vs dictation, Slack/Gmail/iMessage cards, “3 steps” demo.
- Superwhisper: app mockups, chat bubbles, modes, settings, shortcut panels.

**Mawa takeaway:** MVP design should show the keyboard itself immediately:

1. User holds mic.
2. Words stream in.
3. Intent chip changes to Reply/Prompt/Rewrite.
4. Polished result preview appears.
5. Insert button writes into text field.

### 3. Trust and privacy are category requirements

Competitors emphasize privacy/security either directly or through “works offline,” “secure,” “no Wi-Fi,” “privacy-first,” or local model language.

**Mawa takeaway:** Make privacy visible in the UI:

- “Local transcript” badge.
- “Cloud AI on/off” indicator.
- “Context source: Clipboard / Cursor / Manual.”
- Explicit confirmation before API actions.

### 4. Mode chips are a strong pattern

Superwhisper and similar tools expose modes such as casual/formal/legal/chat, predefined modes, custom modes, shortcuts, and super mode.

**Mawa takeaway:** The keyboard should use mode chips:

- Auto
- Dictate
- Reply
- Prompt
- Rewrite
- Ask
- Translate

MVP can ship 4–6 modes; later users can create custom skills/modes.

### 5. App icons and “works everywhere” visuals are common

Wispr Flow, Willow, and Superwhisper all show common apps: Slack, Gmail, iMessage, Notion, ChatGPT, Cursor/Claude Code, Telegram, etc.

**Mawa takeaway:** Marketing and onboarding should show iMessage, Gmail, Slack, ChatGPT/Cursor. The keyboard UI itself should avoid relying on one app’s brand.

---

## Competitor Design Notes

### Wispr Flow

**Visual language:** playful premium editorial. Cream background, black/dark-green panels, lavender CTA, serif display typography, hand-drawn illustrations, large rounded sections.

**Positioning:** effortless voice dictation everywhere, clean polished text, 4x faster.

**Reusable patterns:**

- Before/after transformation of messy speech into polished text.
- Floating voice waveform pill.
- Platform chips: Mac, Windows, iPhone, Android.
- Use-case chips: Accessibility, Creators, Customer Support, Developers, etc.
- Personal dictionary and snippet library as productivity add-ons.

**Avoid copying:** exact cream/lavender/serif identity and Flow logo style.

### Aqua Voice

**Visual language:** minimal, airy, almost Apple-like. White/light-blue glass/water feel, lots of whitespace, thin type, blue CTA, calm tech aesthetic.

**Positioning:** real-time voice to clear text, AI prompts, essays, coding/prompting, “your screen is its dictionary.”

**Reusable patterns:**

- Real-time document/editor preview.
- “Hold Space and try yourself” interaction cue.
- Screen/context intelligence as premium feature.
- Developer/prompting-specific examples.
- Metrics: WPM, hours saved, average reply time.

**Avoid copying:** claiming full screen context on iPhone unless implemented through explicit context capture.

### Willow Voice

**Visual language:** soft SaaS productivity. Lavender/purple palette, gradient pastel backgrounds, rounded white cards, founder testimonials, strong social proof.

**Positioning:** AI voice dictation powerful enough to replace keyboard, automatic editing, style matching, context awareness, AI mode.

**Reusable patterns:**

- Simple 3-step flow: press hotkey, speak naturally, perfect text appears.
- Feature cards: automatic editing, style-matching, context awareness, AI mode.
- Trust badges and social proof.
- Privacy/security card.
- Comparison table: Willow vs regular dictation.

**Avoid copying:** “replace your keyboard” may overpromise for iOS custom keyboard restrictions; say “your AI voice keyboard.”

### Superwhisper

**Visual language:** dark, cinematic, developer/AI power-user vibe. Black/blue gradient, neon accents, dense feature cards, QR for iOS, settings/mode UI, agentic workflows.

**Positioning:** polished text anywhere, offline support, custom modes, shortcuts, agentic coding workflows.

**Reusable patterns:**

- Dark “power mode” aesthetic for advanced users.
- Mode cards: voice, messaging, predefined modes.
- Settings panel for models/providers/modes.
- Agentic workflows and coding use cases.
- Pricing with Free/Pro/Enterprise.

**Avoid copying:** too dark/heavy for first iPhone MVP; keep keyboard simple and friendly.

---

## Mawa Brand Direction

### Desired feel

Mawa should feel:

- warm
- fast
- trustworthy
- voice-native
- slightly magical
- practical for power users
- friendly enough for everyday messaging

### Suggested design direction

**Name:** Mawa Flow Keyboard or Mawa Voice Keyboard

**Tagline options:**

1. “Speak messy. Mawa writes clearly.”
2. “Your voice, turned into the right words.”
3. “Talk naturally. Insert polished text anywhere.”
4. “The AI keyboard that understands what you mean.”

### Visual system

**Palette:**

- Background: warm ivory `#FAF7EF` or iOS system background.
- Primary: deep teal `#075E54` or emerald `#007A5A`.
- Accent: soft violet `#CBB7FF` / `#B891FF`.
- Dark: near-black `#101114`.
- Success/action: bright green/teal.
- Warning/privacy: amber.

**Typography:**

- App/marketing: expressive display for headlines + clean sans body.
- iOS app/keyboard: use SF Pro / system font for native performance and trust.

**Shape language:**

- Rounded iOS cards.
- Pill chips for modes.
- Large circular/rounded mic button.
- Waveform pill while listening.
- Bottom sheet preview panel.

---

## MVP UI Concept

### Keyboard collapsed state

```text
┌────────────────────────────────────────┐
│ Auto   Reply   Prompt   Rewrite   Ask  │
│                                        │
│       Hold to talk with Mawa           │
│              [  Mic  ]                 │
│                                        │
│ Globe      Space / Status       Return │
└────────────────────────────────────────┘
```

### Listening state

```text
┌────────────────────────────────────────┐
│ Auto  • Listening...          Local STT│
│  ▁▃▆█▆▃▁  “reply saying I checked...”  │
│                                        │
│          Release to generate           │
└────────────────────────────────────────┘
```

### Result preview state

```text
┌────────────────────────────────────────┐
│ Intent: Reply        Context: Cursor   │
│ I checked this, and it looks like the  │
│ issue may be related to a missing API  │
│ key. I’ll verify and follow up.        │
│                                        │
│ [Insert] [Shorter] [Warmer] [Redo]     │
└────────────────────────────────────────┘
```

### Onboarding screens

1. Welcome: “Speak messy. Mawa writes clearly.”
2. Install keyboard: step-by-step Settings guide.
3. Enable permissions: Microphone, Speech Recognition, Full Access explanation.
4. Choose privacy mode: local only / cloud AI / BYO key.
5. Try demo: press mic, say a message, insert into sample field.

---

## Phase 1 Design Scope

Phase 1 should be intentionally simple and installable:

- Native SwiftUI host app.
- Keyboard extension UI.
- Demo text insertion.
- Mic UI states.
- Apple Speech transcription if feasible in keyboard extension; otherwise host-app speech demo + keyboard insert flow fallback.
- Static local rewrite modes or simple backend endpoint.

No screen reading, no connectors, no full local model in phase 1.

---

## Later Design Add-ons

### Context panel

Show what context Mawa is using:

- Cursor text
- Clipboard
- Shared page
- Screenshot OCR
- Gmail/Calendar/Slack connector

### Skill drawer

```text
Skills
[Calendar] [Gmail] [Slack] [Notion] [Web] [Custom API]
```

Each skill has:

- status: connected/not connected
- permissions: read/write
- confirmation setting
- audit log

### Action confirmation sheet

Before write/send actions:

```text
Mawa wants to:
1. Read your calendar tomorrow afternoon.
2. Draft a reply with 2 available times.

[Allow once] [Cancel]
```

For actual sending:

```text
Ready to insert/send:
“I’m free tomorrow at 2:00 PM or 4:30 PM...”

[Insert only] [Send if supported] [Cancel]
```

---

## Design Principles for Build

1. **Keyboard first:** the core product must be usable from the keyboard, not only the host app.
2. **Preview before insertion:** never surprise-insert long AI text without a visible preview unless user chooses quick-insert mode.
3. **Mode clarity:** user should always know if they are dictating, replying, prompting, rewriting, or asking.
4. **Context transparency:** show exactly what context was used.
5. **Permission humility:** explain Full Access and cloud AI plainly; do not hide privacy tradeoffs.
6. **Fast path:** one press to speak, one tap to insert.
7. **Mawa brand:** warm, capable, practical — not cold enterprise AI.
