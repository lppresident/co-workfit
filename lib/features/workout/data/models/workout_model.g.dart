// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutModel _$WorkoutModelFromJson(Map<String, dynamic> json) => WorkoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sourceString: json['source'] as String,
      typeString: json['type'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
      correctedDistance: (json['correctedDistance'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toInt(),
      averageHeartRate: (json['averageHeartRate'] as num?)?.toInt(),
      maxHeartRate: (json['maxHeartRate'] as num?)?.toInt(),
      steps: (json['steps'] as num?)?.toInt(),
      elevationGain: (json['elevationGain'] as num?)?.toDouble(),
      calibratedWorkload: (json['calibratedWorkload'] as num).toDouble(),
      calibratedScore: (json['calibratedScore'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
    );

Map<String, dynamic> _$WorkoutModelToJson(WorkoutModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'source': instance.sourceString,
      'type': instance.typeString,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'distance': instance.distance,
      'correctedDistance': instance.correctedDistance,
      'calories': instance.calories,
      'averageHeartRate': instance.averageHeartRate,
      'maxHeartRate': instance.maxHeartRate,
      'steps': instance.steps,
      'elevationGain': instance.elevationGain,
      'calibratedWorkload': instance.calibratedWorkload,
      'calibratedScore': instance.calibratedScore,
      'createdAt': instance.createdAt.toIso8601String(),
      'syncedAt': instance.syncedAt?.toIso8601String(),
    };
