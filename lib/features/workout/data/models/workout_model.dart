import 'package:json_annotation/json_annotation.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

part 'workout_model.g.dart';

@JsonSerializable()
class WorkoutModel {
  final String id;
  final String userId;
  @JsonKey(name: 'source')
  final String sourceString;
  @JsonKey(name: 'type')
  final String typeString;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double? distance;
  final int? calories;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? steps;
  final double? elevationGain;
  final double calibratedWorkload;
  final int calibratedScore;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.sourceString,
    required this.typeString,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.distance,
    this.calories,
    this.averageHeartRate,
    this.maxHeartRate,
    this.steps,
    this.elevationGain,
    required this.calibratedWorkload,
    required this.calibratedScore,
    required this.createdAt,
    this.syncedAt,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutModelToJson(this);

  /// Entity에서 Model로 변환
  factory WorkoutModel.fromEntity(WorkoutEntity entity) {
    return WorkoutModel(
      id: entity.id,
      userId: entity.userId,
      sourceString: entity.source.name,
      typeString: entity.type.name,
      startTime: entity.startTime,
      endTime: entity.endTime,
      durationMinutes: entity.durationMinutes,
      distance: entity.distance,
      calories: entity.calories,
      averageHeartRate: entity.averageHeartRate,
      maxHeartRate: entity.maxHeartRate,
      steps: entity.steps,
      elevationGain: entity.elevationGain,
      calibratedWorkload: entity.calibratedWorkload,
      calibratedScore: entity.calibratedScore,
      createdAt: entity.createdAt,
      syncedAt: entity.syncedAt,
    );
  }

  /// Model에서 Entity로 변환
  WorkoutEntity toEntity() {
    return WorkoutEntity(
      id: id,
      userId: userId,
      source: WorkoutSource.values.firstWhere(
        (e) => e.name == sourceString,
        orElse: () => WorkoutSource.manual,
      ),
      type: WorkoutType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => WorkoutType.other,
      ),
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      distance: distance,
      calories: calories,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      steps: steps,
      elevationGain: elevationGain,
      calibratedWorkload: calibratedWorkload,
      calibratedScore: calibratedScore,
      createdAt: createdAt,
      syncedAt: syncedAt,
    );
  }
}
