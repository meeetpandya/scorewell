import { RoiRect } from './types';

export type MarksRoiLayout = {
  tableRoi: RoiRect;
  enrollmentRect: RoiRect;
  questionRects: RoiRect[];
  totalRect: RoiRect;
};

export const defaultRoiLayout: MarksRoiLayout = {
  tableRoi: { x: 0.06, y: 0.25, width: 0.88, height: 0.55 },
  enrollmentRect: { x: 0.72, y: 0.07, width: 0.24, height: 0.08 },
  questionRects: Array.from({ length: 8 }, (_, i) => ({
    x: 0.05 + i * 0.105,
    y: 0.62,
    width: 0.095,
    height: 0.17,
  })),
  totalRect: { x: 0.9, y: 0.62, width: 0.09, height: 0.17 },
};

export const resolveRect = (relative: RoiRect, parent: RoiRect): RoiRect => ({
  x: parent.x + relative.x * parent.width,
  y: parent.y + relative.y * parent.height,
  width: relative.width * parent.width,
  height: relative.height * parent.height,
});

export const intersects = (a: RoiRect, b: RoiRect) =>
  a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y;
