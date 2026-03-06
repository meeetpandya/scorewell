import { defaultRoiLayout, intersects, resolveRect } from './roiMapper';
import { MarksReading, OcrToken, RoiRect } from './types';

const toDigits = (text: string) => text.replace(/[^0-9]/g, '');

const pickNumericToken = (tokens: OcrToken[], target: RoiRect) => {
  const match = tokens.find((t) => intersects(t.frame, target) && toDigits(t.text).length > 0);
  if (!match) return null;
  const value = Number.parseInt(toDigits(match.text), 10);
  return Number.isNaN(value) ? null : { value, confidence: match.confidence };
};

const pickEnrollment = (tokens: OcrToken[], target: RoiRect) => {
  const parts = tokens
    .filter((t) => intersects(t.frame, target))
    .map((t) => toDigits(t.text))
    .filter(Boolean);
  return parts.length ? parts.join('') : null;
};

export const extractReadingFromTokens = (tokens: OcrToken[], frameRoi = defaultRoiLayout.tableRoi): MarksReading | null => {
  const enrollmentRect = resolveRect(defaultRoiLayout.enrollmentRect, frameRoi);
  const enrollmentNo = pickEnrollment(tokens, enrollmentRect);
  if (!enrollmentNo) return null;

  const qValues: number[] = [];
  let minConfidence = 1;

  for (const cell of defaultRoiLayout.questionRects) {
    const hit = pickNumericToken(tokens, resolveRect(cell, frameRoi));
    if (!hit) return null;
    qValues.push(hit.value);
    minConfidence = Math.min(minConfidence, hit.confidence);
  }

  const totalHit = pickNumericToken(tokens, resolveRect(defaultRoiLayout.totalRect, frameRoi));
  if (!totalHit) return null;
  minConfidence = Math.min(minConfidence, totalHit.confidence);

  if (qValues.length !== 8) return null;
  const questions = qValues as MarksReading['questions'];

  return {
    enrollmentNo,
    questions,
    total: totalHit.value,
    minConfidence,
  };
};
