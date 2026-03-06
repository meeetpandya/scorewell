import { router } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

export default function SessionInitScreen() {
  const [courseName, setCourseName] = useState('');
  const [section, setSection] = useState('');
  const [dateISO, setDateISO] = useState(new Date().toISOString().slice(0, 10));

  const canStart = useMemo(() => courseName.trim() && section.trim() && dateISO.trim(), [courseName, section, dateISO]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Start Marks Session</Text>
      <TextInput placeholder="Course Name" style={styles.input} value={courseName} onChangeText={setCourseName} />
      <TextInput placeholder="Section" style={styles.input} value={section} onChangeText={setSection} />
      <TextInput placeholder="YYYY-MM-DD" style={styles.input} value={dateISO} onChangeText={setDateISO} />

      <Pressable
        style={[styles.button, !canStart && styles.buttonDisabled]}
        disabled={!canStart}
        onPress={() =>
          router.push({
            pathname: '/scanner',
            params: { courseName: courseName.trim(), section: section.trim(), dateISO },
          })
        }
      >
        <Text style={styles.buttonText}>Start Live Scanner</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, justifyContent: 'center', backgroundColor: '#0f172a' },
  title: { color: 'white', fontSize: 28, marginBottom: 24, fontWeight: '700' },
  input: {
    color: 'white',
    borderWidth: 1,
    borderColor: '#334155',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 12,
    backgroundColor: '#111827',
  },
  button: { marginTop: 8, backgroundColor: '#22c55e', borderRadius: 10, padding: 14, alignItems: 'center' },
  buttonDisabled: { opacity: 0.45 },
  buttonText: { color: '#052e16', fontWeight: '700', fontSize: 16 },
});
