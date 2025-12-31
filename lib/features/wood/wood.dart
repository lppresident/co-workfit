/// 통나무 재화 시스템 Feature
///
/// 통나무런 챌린지 완료 시 통나무(Wood) 재화를 지급하고,
/// 이를 활용한 아이템 제작 시스템의 기반을 제공합니다.
///
/// 보상 체계:
/// - 개인 운동 보상: 기본 5개 + 거리(km) × 2 + 일일 첫 운동 보너스 3개
/// - 챌린지 기여 보상: 제출 거리(km) × 1 + 첫 기여 보너스 5개
/// - 성공 보너스: 완료 30개 + MVP 20개 + 협력 보너스 + 마일스톤 보너스
///
/// 정산 규칙:
/// - 하루에 여러 챌린지 종료 시 가장 높은 보상 1개만 선택
/// - 7일 이내 미수령 시 보상 소멸

// Domain - Entities
export 'domain/entities/wood_summary_entity.dart';
export 'domain/entities/wood_settlement_entity.dart';
export 'domain/entities/wood_reward_constants.dart';

// Domain - Repositories
export 'domain/repositories/wood_repository.dart';

// Domain - UseCases
export 'domain/usecases/calculate_personal_reward.dart';
export 'domain/usecases/calculate_contribution_reward.dart';
export 'domain/usecases/calculate_success_bonus.dart';
export 'domain/usecases/calculate_challenge_reward.dart';
export 'domain/usecases/settle_daily_rewards.dart';
export 'domain/usecases/check_pending_settlements.dart';
export 'domain/usecases/get_wood_summary.dart';
export 'domain/usecases/get_settlement_history.dart';

// Data - Models
export 'data/models/wood_summary_model.dart';
export 'data/models/wood_settlement_model.dart';

// Data - DataSources
export 'data/datasources/firestore_wood_datasource.dart';

// Data - Repositories
export 'data/repositories/wood_repository_impl.dart';

// Presentation - BLoC
export 'presentation/bloc/wood_bloc.dart';
export 'presentation/bloc/wood_event.dart';
export 'presentation/bloc/wood_state.dart';

// Presentation - Widgets
export 'presentation/widgets/settlement_dialog.dart';
export 'presentation/widgets/wood_balance_widget.dart';

// Presentation - Pages
export 'presentation/pages/settlement_history_page.dart';

