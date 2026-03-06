import React from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Rect } from 'react-native-svg';

type Props = {
  locked: boolean;
};

export default function RoiOverlay({ locked }: Props) {
  const color = locked ? '#22c55e' : '#ef4444';
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      <Svg width="100%" height="100%">
        <Rect x="6%" y="25%" width="88%" height="55%" rx="14" stroke={color} strokeWidth={locked ? 5 : 3} fill="transparent" />
        {Array.from({ length: 9 }).map((_, i) => (
          <Rect
            key={i}
            x={`${6 + (88 / 9) * i}%`}
            y="59.1%"
            width={`${88 / 9}%`}
            height="9.9%"
            stroke={color}
            strokeWidth={1.4}
            fill="transparent"
          />
        ))}
      </Svg>
    </View>
  );
}
