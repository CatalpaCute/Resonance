const List<int> kAutoRefreshIntervalPresets = <int>[
  15,
  30,
  60,
  180,
  360,
  720,
  1440,
  4320,
  10080,
];

const int kDefaultAutoRefreshIntervalMinutes = 1440;

int normalizeAutoRefreshInterval(int minutes) {
  if (kAutoRefreshIntervalPresets.contains(minutes)) {
    return minutes;
  }
  return kDefaultAutoRefreshIntervalMinutes;
}
