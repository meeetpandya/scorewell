import * as Haptics from 'expo-haptics';
import { useLocalSearchParams } from 'expo-router';
import React, { useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Camera, useCameraDevice, useCameraPermission, useFrameProcessor } from 'react-native-vision-camera';
// eslint-disable-next-line import/no-unresolved
import { scanText } from 'react-native-vision-camera-text-recognition';
import { runOnJS } from 'react-native-worklets-core';

import { exportWorkbookBase64, saveRecord } from '../data/marksRepository';
import { extractReadingFromTokens } from '../vision/liveOcrController';
import { defaultRoiLayout } from '../vision/roiMapper';
import { StabilityGate } from '../vision/stabilityGate';
import { OcrToken, SessionDetails } from '../vision/types';
import RoiOverlay from './RoiOverlay';

export default function ScannerScreen() {
  const params = useLocalSearchParams<{ courseName: string; section: string; dateISO: string }>();
  const session = useMemo<SessionDetails>(
    () => ({
      courseName: params.courseName ?? 'Unknown',
      section: params.section ?? 'A',
      dateISO: params.dateISO ?? new Date().toISOString().slice(0, 10),
    }),
    [params.courseName, params.dateISO, params.section]
  );

  const { hasPermission, requestPermission } = useCameraPermission();
  const device = useCameraDevice('back');
  const gate = useRef(new StabilityGate(5, 0.85)).current;

  const [locked, setLocked] = useState(false);
  const [status, setStatus] = useState('Align marks table in the ROI frame.');
  const [lastLine, setLastLine] = useState('No reading yet.');

  const onTokens = (tokens: OcrToken[]) => {
    const reading = extractReadingFromTokens(tokens, defaultRoiLayout.tableRoi);
    if (!reading) return;

    setLastLine(`Enroll ${reading.enrollmentNo} | Q: ${reading.questions.join(',')} | T: ${reading.total}`);

    const success = gate.ingest(reading);
    if (!success) {
      setLocked(false);
      setStatus(`Stabilizing... ${gate.currentStreak}/5`);
      return;
    }

    saveRecord(session, reading);
    setLocked(true);
    setStatus(`Locked ✓ Saved enrollment ${reading.enrollmentNo}`);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    setTimeout(() => setLocked(false), 450);
  };

  const frameProcessor = useFrameProcessor(
    (frame) => {
      'worklet';
      const result = scanText(frame);
      const mapped = result.blocks.flatMap((block: any) =>
        block.lines.map((line: any) => ({
          text: line.text,
          confidence: line.confidence ?? 0,
          frame: {
            x: line.frame.x / frame.width,
            y: line.frame.y / frame.height,
            width: line.frame.width / frame.width,
            height: line.frame.height / frame.height,
          },
        }))
      );
      runOnJS(onTokens)(mapped);
    },
    [onTokens]
  );

  if (!hasPermission) {
    return (
      <View style={styles.centered}>
        <Text style={styles.text}>Camera permission required</Text>
        <Pressable style={styles.button} onPress={requestPermission}>
          <Text style={styles.buttonText}>Grant Camera Access</Text>
        </Pressable>
      </View>
    );
  }

  if (!device) {
    return (
      <View style={styles.centered}>
        <Text style={styles.text}>No back camera available.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Camera style={StyleSheet.absoluteFill} device={device} isActive frameProcessor={frameProcessor} pixelFormat="yuv" />
      <RoiOverlay locked={locked} />

      <View style={styles.topCard}>
        <Text style={styles.text}>{session.courseName} • {session.section} • {session.dateISO}</Text>
        <Text style={styles.subText}>{lastLine}</Text>
      </View>

      <View style={styles.bottomCard}>
        <Text style={styles.text}>{status}</Text>
        <Pressable
          style={[styles.button, { marginTop: 8 }]}
          onPress={() => {
            const base64 = exportWorkbookBase64();
            setStatus(`Workbook generated in-memory (${base64.length} bytes base64).`);
          }}
        >
          <Text style={styles.buttonText}>Generate Excel Payload</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: 'black' },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#020617', padding: 20 },
  topCard: {
    position: 'absolute',
    top: 52,
    left: 12,
    right: 12,
    backgroundColor: '#020617cc',
    borderRadius: 12,
    padding: 10,
  },
  bottomCard: {
    position: 'absolute',
    bottom: 16,
    left: 12,
    right: 12,
    backgroundColor: '#020617cc',
    borderRadius: 12,
    padding: 10,
  },
  text: { color: 'white', fontWeight: '600' },
  subText: { color: '#bfdbfe', marginTop: 2 },
  button: { backgroundColor: '#22c55e', borderRadius: 8, paddingVertical: 10, paddingHorizontal: 12, alignItems: 'center' },
  buttonText: { color: '#052e16', fontWeight: '700' },
});
