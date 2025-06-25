import 'package:get_it/get_it.dart';
import 'advanced_location_service.dart';
import 'location_filter.dart';
import 'movement_detector.dart';

// Accesseurs globaux
final AdvancedLocationService locationService = GetIt.instance<AdvancedLocationService>();
final LocationFilter locationFilter = GetIt.instance<LocationFilter>();
final MovementDetector movementDetector = GetIt.instance<MovementDetector>();