import * as SQLite from 'expo-sqlite';
import * as XLSX from 'xlsx';

import { MarksReading, SessionDetails } from '../vision/types';

const db = SQLite.openDatabaseSync('scorewell.db');

db.execSync(`
CREATE TABLE IF NOT EXISTS marks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course TEXT NOT NULL,
  section TEXT NOT NULL,
  dateISO TEXT NOT NULL,
  enrollmentNo TEXT NOT NULL,
  q1 INTEGER, q2 INTEGER, q3 INTEGER, q4 INTEGER,
  q5 INTEGER, q6 INTEGER, q7 INTEGER, q8 INTEGER,
  total INTEGER
);
`);

export const saveRecord = (session: SessionDetails, reading: MarksReading) => {
  db.runSync(
    `INSERT INTO marks (course, section, dateISO, enrollmentNo, q1, q2, q3, q4, q5, q6, q7, q8, total)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [session.courseName, session.section, session.dateISO, reading.enrollmentNo, ...reading.questions, reading.total]
  );
};

export const getAllRecords = () =>
  db.getAllSync<{
    course: string;
    section: string;
    dateISO: string;
    enrollmentNo: string;
    q1: number; q2: number; q3: number; q4: number;
    q5: number; q6: number; q7: number; q8: number;
    total: number;
  }>('SELECT * FROM marks ORDER BY id DESC');

export const exportWorkbookBase64 = () => {
  const rows = getAllRecords();
  const ws = XLSX.utils.json_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Marks');
  return XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
};
