import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/scenario/target_elimination/target_elimination_scenario.dart';
import '../../../models/scenario/target_elimination/player_target.dart';
import '../../../models/scenario/target_elimination/elimination.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class TargetEliminationService {
  final ApiService _apiService;
  final AuthService _authService;

  TargetEliminationService({
    ApiService? apiService,
    AuthService? authService,
  }) : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  /// Crée un nouveau scénario d'élimination ciblée
  Future<TargetEliminationScenario> createScenario({
    required int gameSessionId,
    required bool isTeamMode,
    required bool friendlyFire,
    required int pointsPerElimination,
    required int cooldownMinutes,
    required int numberOfQRCodes,
    required String announcementTemplate,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios',
        body: json.encode({
          'gameSessionId': gameSessionId,
          'isTeamMode': isTeamMode,
          'friendlyFire': friendlyFire,
          'pointsPerElimination': pointsPerElimination,
          'cooldownMinutes': cooldownMinutes,
          'numberOfQRCodes': numberOfQRCodes,
          'announcementTemplate': announcementTemplate,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TargetEliminationScenario.fromJson(data);
      } else {
        throw Exception('Erreur lors de la création du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la création du scénario: $e');
    }
  }

  /// Récupère un scénario par son ID
  Future<TargetEliminationScenario?> getScenario(int scenarioId) async {
    try {
      final response = await _apiService.get('/api/target-elimination/scenarios/$scenarioId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TargetEliminationScenario.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors de la récupération du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la récupération du scénario: $e');
    }
  }

  /// Met à jour un scénario existant
  Future<TargetEliminationScenario> updateScenario({
    required int scenarioId,
    required bool isTeamMode,
    required bool friendlyFire,
    required int pointsPerElimination,
    required int cooldownMinutes,
    required int numberOfQRCodes,
    required String announcementTemplate,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/target-elimination/scenarios/$scenarioId',
        body: json.encode({
          'isTeamMode': isTeamMode,
          'friendlyFire': friendlyFire,
          'pointsPerElimination': pointsPerElimination,
          'cooldownMinutes': cooldownMinutes,
          'numberOfQRCodes': numberOfQRCodes,
          'announcementTemplate': announcementTemplate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TargetEliminationScenario.fromJson(data);
      } else {
        throw Exception('Erreur lors de la mise à jour du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la mise à jour du scénario: $e');
    }
  }

  /// Supprime un scénario
  Future<void> deleteScenario(int scenarioId) async {
    try {
      final response = await _apiService.delete('/api/target-elimination/scenarios/$scenarioId');

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la suppression du scénario: $e');
    }
  }

  /// Génère les QR codes pour un scénario
  Future<List<String>> generateQRCodes({
    required int scenarioId,
    required int numberOfCodes,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/generate-qr-codes',
        body: json.encode({
          'numberOfCodes': numberOfCodes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['qrCodes']);
      } else {
        throw Exception('Erreur lors de la génération des QR codes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la génération des QR codes: $e');
    }
  }

  /// Récupère les QR codes d'un scénario
  Future<List<String>> getQRCodes(int scenarioId) async {
    try {
      final response = await _apiService.get('/api/target-elimination/scenarios/$scenarioId/qr-codes');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['qrCodes']);
      } else {
        throw Exception('Erreur lors de la récupération des QR codes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la récupération des QR codes: $e');
    }
  }

  /// Affecte automatiquement les numéros aux joueurs connectés
  Future<List<PlayerTarget>> assignPlayerTargets({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/assign-targets',
        body: json.encode({
          'gameSessionId': gameSessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> targetsJson = data['playerTargets'];
        return targetsJson.map((json) => PlayerTarget.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de l\'affectation des cibles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de l\'affectation des cibles: $e');
    }
  }

  /// Récupère les affectations de cibles pour un scénario
  Future<List<PlayerTarget>> getPlayerTargets({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/player-targets',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlayerTarget.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des cibles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la récupération des cibles: $e');
    }
  }

  /// Récupère la cible d'un joueur spécifique
  Future<PlayerTarget?> getPlayerTarget({
    required int scenarioId,
    required int playerId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/players/$playerId/target',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerTarget.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors de la récupération de la cible du joueur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la récupération de la cible du joueur: $e');
    }
  }

  /// Récupère la cible du joueur actuel
  Future<PlayerTarget?> getCurrentPlayerTarget({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    return getPlayerTarget(
      scenarioId: scenarioId,
      playerId: currentUser.id,
      gameSessionId: gameSessionId,
    );
  }

  /// Traite une élimination via scan de QR code
  Future<Elimination> processElimination({
    required String qrCode,
    required int killerId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/process-elimination',
        body: json.encode({
          'qrCode': qrCode,
          'killerId': killerId,
          'gameSessionId': gameSessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Elimination.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du traitement de l\'élimination');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion lors du traitement de l\'élimination: $e');
    }
  }

  /// Récupère l'historique des éliminations
  Future<List<Elimination>> getEliminations({
    required int scenarioId,
    required int gameSessionId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'gameSessionId': gameSessionId.toString(),
      };
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/eliminations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Elimination.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des éliminations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la récupération des éliminations: $e');
    }
  }

  /// Récupère les dernières éliminations pour le feed
  Future<List<Elimination>> getRecentEliminations({
    required int scenarioId,
    required int gameSessionId,
    int limit = 10,
  }) async {
    return getEliminations(
      scenarioId: scenarioId,
      gameSessionId: gameSessionId,
      limit: limit,
      offset: 0,
    );
  }

  /// Vérifie si un joueur est en cooldown d'immunité
  Future<CooldownStatus> checkCooldownStatus({
    required int scenarioId,
    required int victimId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/target-elimination/scenarios/$scenarioId/players/$victimId/cooldown-status',
        queryParameters: {
          'gameSessionId': gameSessionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CooldownStatus.fromJson(data);
      } else {
        throw Exception('Erreur lors de la vérification du cooldown: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la vérification du cooldown: $e');
    }
  }

  /// Démarre le scénario (verrouille les affectations)
  Future<void> startScenario({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/start',
        body: json.encode({
          'gameSessionId': gameSessionId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors du démarrage du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors du démarrage du scénario: $e');
    }
  }

  /// Arrête le scénario
  Future<void> stopScenario({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/stop',
        body: json.encode({
          'gameSessionId': gameSessionId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'arrêt du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de l\'arrêt du scénario: $e');
    }
  }

  /// Réinitialise le scénario (supprime toutes les éliminations et scores)
  Future<void> resetScenario({
    required int scenarioId,
    required int gameSessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/reset',
        body: json.encode({
          'gameSessionId': gameSessionId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la réinitialisation du scénario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion lors de la réinitialisation du scénario: $e');
    }
  }

  /// Valide un QR code sans traiter l'élimination
  Future<QRCodeValidation> validateQRCode({
    required String qrCode,
    required int scenarioId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/target-elimination/scenarios/$scenarioId/validate-qr-code',
        body: json.encode({
          'qrCode': qrCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QRCodeValidation.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'QR code invalide');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion lors de la validation du QR code: $e');
    }
  }
}

/// Classe pour le statut de cooldown d'un joueur
class CooldownStatus {
  final bool isInCooldown;
  final DateTime? cooldownEndTime;
  final int remainingSeconds;

  CooldownStatus({
    required this.isInCooldown,
    this.cooldownEndTime,
    required this.remainingSeconds,
  });

  factory CooldownStatus.fromJson(Map<String, dynamic> json) {
    return CooldownStatus(
      isInCooldown: json['isInCooldown'] as bool,
      cooldownEndTime: json['cooldownEndTime'] != null 
          ? DateTime.parse(json['cooldownEndTime'] as String)
          : null,
      remainingSeconds: json['remainingSeconds'] as int,
    );
  }

  String get formattedRemainingTime {
    if (!isInCooldown) return '';
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Classe pour la validation d'un QR code
class QRCodeValidation {
  final bool isValid;
  final int? targetNumber;
  final int? playerId;
  final String? playerName;
  final String? message;

  QRCodeValidation({
    required this.isValid,
    this.targetNumber,
    this.playerId,
    this.playerName,
    this.message,
  });

  factory QRCodeValidation.fromJson(Map<String, dynamic> json) {
    return QRCodeValidation(
      isValid: json['isValid'] as bool,
      targetNumber: json['targetNumber'] as int?,
      playerId: json['playerId'] as int?,
      playerName: json['playerName'] as String?,
      message: json['message'] as String?,
    );
  }
}

