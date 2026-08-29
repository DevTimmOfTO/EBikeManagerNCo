/// Typical number of full charge cycles an e-bike Li-ion pack is rated for
/// before capacity falls to roughly 80% of new — manufacturers commonly cite
/// figures in the 500–1000 range; 800 is a reasonable, conservative default.
const int defaultRatedCycleLife = 800;

/// Percentage points of health lost by [defaultRatedCycleLife] cycles.
/// Matches the common "80% capacity at rated cycle life" convention.
const double defaultDegradationFactor = 20;

/// A simple, non-ML linear heuristic: health drops steadily from 100% toward
/// `100 - degradationFactor` as [cycleCount] approaches [ratedCycleLife].
/// This is a rough estimate meant to pre-fill a sensible starting value when
/// logging a charge — not a precise measurement — so the result is always
/// clamped to a valid 0–100 percentage.
double estimateHealthPct(
  int cycleCount, {
  int ratedCycleLife = defaultRatedCycleLife,
  double degradationFactor = defaultDegradationFactor,
}) {
  final pct = 100 - (cycleCount / ratedCycleLife) * degradationFactor;
  return pct.clamp(0, 100);
}
