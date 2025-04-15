class TreasureHuntConfig {
  final int numberOfTreasures;
  final int defaultValue;
  final String defaultSymbol;

  TreasureHuntConfig({
    required this.numberOfTreasures,
    required this.defaultValue,
    this.defaultSymbol = "💰",
  });

  Map<String, dynamic> toJson() {
    return {
      'count': numberOfTreasures,
      'defaultValue': defaultValue,
      'defaultSymbol': defaultSymbol,
    };
  }
}