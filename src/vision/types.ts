export type SessionDetails = {
  courseName: string;
  section: string;
  dateISO: string;
};

export type MarksReading = {
  enrollmentNo: string;
  questions: [number, number, number, number, number, number, number, number];
  total: number;
  minConfidence: number;
};

export type RoiRect = { x: number; y: number; width: number; height: number };

export type OcrToken = {
  text: string;
  confidence: number;
  frame: RoiRect;
};
