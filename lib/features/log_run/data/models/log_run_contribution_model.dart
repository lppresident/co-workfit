import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

class LogRunContributionModel extends LogRunContributionEntity {
  const LogRunContributionModel({
    required super.id, required super.challengeId, required super.userId, required super.userName,
    required super.workoutId, required super.distance, required super.workoutType,
    required super.workoutDate, required super.submittedAt, required super.percentage,
  });

  factory LogRunContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogRunContributionModel(
      id: doc.id, challengeId: data['challengeId'] as String, userId: data['userId'] as String,
      userName: data['userName'] as String, workoutId: data['workoutId'] as String,
      distance: (data['distance'] as num).toDouble(),
      workoutType: _parseWorkoutType(data['workoutType'] as String),
      workoutDate: (data['workoutDate'] as Timestamp).toDate(),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      percentage: (data['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId, 'userId': userId, 'userName': userName,
      'workoutId': workoutId, 'distance': distance,
      'workoutType': workoutType.toString().split('.').last,
      'workoutDate': Timestamp.fromDate(workoutDate),
      'submittedAt': Timestamp.fromDate(submittedAt), 'percentage': percentage,
    };
  }

  factory LogRunContributionModel.fromEntity(LogRunContributionEntity entity) {
    return LogRunContributionModel(
      id: entity.id, challengeId: entity.challengeId, userId: entity.userId, userName: entity.userName,
      workoutId: entity.workoutId, distance: entity.distance, workoutType: entity.workoutType,
      workoutDate: entity.workoutDate, submittedAt: entity.submittedAt, percentage: entity.percentage,
    );
  }

  static WorkoutType _parseWorkoutType(String value) {
    switch (value) {
      case 'running': return WorkoutType.running;
      case 'cycling': return WorkoutType.cycling;
      case 'walking': return WorkoutType.walking;
      case 'swimming': return WorkoutType.swimming;
      case 'weightTraining': return WorkoutType.weightTraining;
      case 'yoga': return WorkoutType.yoga;
      case 'hiking': return WorkoutType.hiking;
      default: return WorkoutType.other;
    }
  }
}
