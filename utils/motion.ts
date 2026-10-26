import { useEffect, useState } from 'react';
import { AccessibilityInfo } from 'react-native';

export const SNAP_SPRING = {
  damping: 24,
  stiffness: 280,
  mass: 0.65,
  restDisplacementThreshold: 0.4,
  restSpeedThreshold: 0.4,
};

export function useReduceMotion() {
  const [reduce, setReduce] = useState(false);
  useEffect(() => {
    let active = true;
    AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (active) setReduce(value);
    });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduce);
    return () => {
      active = false;
      subscription.remove();
    };
  }, []);
  return reduce;
}
