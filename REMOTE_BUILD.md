# Remote iPhone Install Flow

This project is designed for phone-friendly unsigned IPA delivery:

1. Push changes to `main`.
2. GitHub Actions runs on a macOS runner.
3. The workflow generates the Xcode project with XcodeGen.
4. It builds an unsigned iPhoneOS `.ipa`.
5. It uploads the IPA as:
   - a workflow artifact, and
   - the `latest` GitHub Release asset named `mawa-flow-keyboard-unsigned.ipa`.
6. On iPhone, download the IPA from the latest release, sign it with your on-device signing app, and install.

## Update behavior

If you keep the same bundle IDs and sign with the same certificate/profile, installing the newly signed IPA over the old one should behave like an update and preserve app data. You still need to install the new signed IPA unless your signing app supports its own update feed/source.

Current bundle IDs:

- Main app: `com.mawa.flow`
- Keyboard extension: `com.mawa.flow.keyboard`

For the keyboard extension, your signer/provisioning setup must handle both the main app and embedded extension.

## Latest IPA

After CI succeeds, the latest unsigned IPA is attached to the GitHub release tagged `latest`.

## Do not commit signing material

Never commit:

- `.p12`
- `.mobileprovision`
- certificate passwords
- Apple account credentials

Those are ignored by `.gitignore`.
