import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

class ContributionModel extends ContributionEntity {
  const ContributionModel({
    required super.id,
    required super.challengeId,
    required super.userId,
    required super.userNickname,
    required super.workoutId,
    required super.contributionValue,
    required super.submittedAt,
    required super.percentage,
    super.workoutType,
    super.workoutDate,
  });

  factory ContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContributionModel(
      id: doc.id,
      challengeId: data['challengeId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userNickname: data['userNickname'] as String? ?? '',
      workoutId: data['workoutId'] as String? ?? '',
      contributionValue: (data['contributionValue'] as num?)?.toDouble() ?? 
                         (data['distance'] as num?)?.toDouble() ?? 0.0, // 하위 호환성
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      workoutType: data['workoutType'] != null 
          ? _parseWorkoutType(data['workoutType'] as String) 
          : null,
      workoutDate: (data['workoutDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'challengeId': challengeId,
      'userId': userId,
      'userNickname': userNickname,
      'workoutId': workoutId,
      'contributionValue': contributionValue,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'percentage': percentage,
    };
    
    // 피드 표시용 캐시 (선택적)
    if (workoutType != null) {
      data['workoutType'] = workoutType.toString().split('.').last;
    }
    if (workoutDate != null) {
      data['workoutDate'] = Timestamp.fromDate(workoutDate!);
    }
    
    return data;
  }

  factory ContributionModel.fromEntity(ContributionEntity entity) {
    return ContributionModel(
      id: entity.id,
      challengeId: entity.challengeId,
      userId: entity.userId,
      userNickname: entity.userNickname,
      workoutId: entity.workoutId,
      contributionValue: entity.contributionValue,
      submittedAt: entity.submittedAt,
      percentage: entity.percentage,
      workoutType: entity.workoutType,
      workoutDate: entity.workoutDate,
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
