# Scorewell (React Native + Expo)

Live OCR marks entry app scaffold built with Expo + React Native.

## Highlights
- Session initialization (course/date/section).
- Live camera preview with fixed ROI overlay.
- OCR frame processing pipeline hook (VisionCamera text-recognition plugin).
- Stability gate: requires 5 consecutive matching valid frames.
- Mathematical validation: `Q1+...+Q8 === Total`.
- Offline persistence in SQLite.
- Excel payload generation using `xlsx`.

## Run
```bash
npm install
npx expo prebuild
npm run android
```

> Note: Frame processors and ML OCR plugin require a development build (not Expo Go).
