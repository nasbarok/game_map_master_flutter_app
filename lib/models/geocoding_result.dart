class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;
  // Add other fields you might get from Nominatim or your backend proxy
  // For example: address components (street, city, country), bounding box, etc.

  GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    // This is a basic example. Adjust based on the actual API response structure.
    // Nominatim typically returns lat/lon as strings, so parsing to double is needed.
    return GeocodingResult(
      displayName: json["display_name"] ?? json["displayName"] ?? "Unknown Address",
      latitude: double.tryParse(json["lat"]?.toString() ?? json["latitude"]?.toString() ?? "0.0") ?? 0.0,
      longitude: double.tryParse(json["lon"]?.toString() ?? json["longitude"]?.toString() ?? "0.0") ?? 0.0,
    );
  }

  // toJson might not be needed if you only receive this from the server
  Map<String, dynamic> toJson() {
    return {
      "displayName": displayName,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}

