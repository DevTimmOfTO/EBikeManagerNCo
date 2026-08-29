import 'package:ebikemanager/features/history/domain/battery_degradation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at 100% with zero cycles', () {
    expect(estimateHealthPct(0), 100);
  });

  test('drops linearly toward 80% at the rated cycle life', () {
    expect(estimateHealthPct(400), 90);
    expect(estimateHealthPct(800), 80);
  });

  test('clamps to 0 rather than going negative for very high cycle counts', () {
    expect(estimateHealthPct(100000), 0);
  });

  test('clamps to 100 rather than exceeding it for a negative cycle count', () {
    expect(estimateHealthPct(-10), 100);
  });

  test('supports custom rated cycle life and degradation factor', () {
    expect(
      estimateHealthPct(50, ratedCycleLife: 100, degradationFactor: 40),
      80,
    );
  });
}
