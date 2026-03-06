import { MarksReading } from './types';

const signatureOf = (r: MarksReading) => `${r.enrollmentNo}:${r.questions.join(',')}:${r.total}`;

export class StabilityGate {
  private lastSignature: string | null = null;
  private streak = 0;

  constructor(private readonly requiredFrames = 5, private readonly confidenceThreshold = 0.85) {}

  ingest(reading: MarksReading): boolean {
    const isMathValid = reading.questions.reduce((sum, q) => sum + q, 0) === reading.total;
    if (!isMathValid || reading.minConfidence < this.confidenceThreshold) {
      this.reset();
      return false;
    }

    const sig = signatureOf(reading);
    if (this.lastSignature !== sig) {
      this.lastSignature = sig;
      this.streak = 1;
      return false;
    }

    this.streak += 1;
    if (this.streak >= this.requiredFrames) {
      this.reset();
      return true;
    }
    return false;
  }

  reset() {
    this.lastSignature = null;
    this.streak = 0;
  }

  get currentStreak() {
    return this.streak;
  }
}
