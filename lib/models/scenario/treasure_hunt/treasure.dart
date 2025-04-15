class Treasure {
  final int id;
  final int treasureHuntScenarioId;
  final String name;
  final String? description;
  final String qrCode;
  final double? latitude;
  final double? longitude;
  final int points;
  final String symbol;
  final int orderNumber;

  Treasure({
    required this.id,
    required this.treasureHuntScenarioId,
    required this.name,
    this.description,
    required this.qrCode,
    this.latitude,
    this.longitude,
    required this.points,
    required this.symbol,
    required this.orderNumber,
  });

  factory Treasure.fromJson(Map<String, dynamic> json) {
    return Treasure(
      id: json['id'],
      treasureHuntScenarioId: json['treasureHuntScenario']['id'],
      name: json['name'],
      description: json['description'],
      qrCode: json['qrCode'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      points: json['points'],
      symbol: json['symbol'] ?? '💰',
      orderNumber: json['orderNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treasureHuntScenarioId': treasureHuntScenarioId,
      'name': name,
      'description': description,
      'qrCode': qrCode,
      'latitude': latitude,
      'longitude': longitude,
      'points': points,
      'symbol': symbol,
      'orderNumber': orderNumber,
    };
  }
}
