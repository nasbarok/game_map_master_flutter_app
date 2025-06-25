import 'dart:convert';
import 'package:game_map_master_flutter_app/models/geocoding_result.dart'; // To be created
import 'package:game_map_master_flutter_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:game_map_master_flutter_app/utils/logger.dart';

class GeocodingService {
  final ApiService _apiService;

  GeocodingService(this._apiService);

  Future<List<GeocodingResult>> searchAddress(String address) async {
    if (address.isEmpty) {
      return [];
    }
    try {
      // Note: The backend endpoint was planned as /api/v1/geocoding/search
      // Adjust if your ApiService handles the /api/v1 prefix or if it's different.
      final response = await _apiService.get('geocoding/search?address=${Uri.encodeComponent(address)}');
      
      // Assuming the response is a list of geocoding results
      // The actual structure of GeocodingResult will depend on what Nominatim (or your chosen service) returns
      // and how your backend formats it.
      // For now, let's assume a simple structure for GeocodingResult.
      final List<dynamic> decodedResponse = response as List<dynamic>; // Or jsonDecode(response) if it's a string
      return decodedResponse.map((item) => GeocodingResult.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error during geocoding search: $e');
      }
      // Depending on how you want to handle errors, you might rethrow, return empty, or a custom error object.
      throw Exception('Failed to search address: $e');
    }
  }
}

