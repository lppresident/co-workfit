// 통합 재화 시스템
//
// 모든 재화(통나무, 쇠 등)를 통합 관리하는 시스템
// 신규 재화 추가 시 CurrencyType enum과 RewardConfig만 추가하면 됨

// Domain - Entities
export 'domain/entities/currency_type.dart';
export 'domain/entities/reward_config.dart';
export 'domain/entities/currency_summary_entity.dart';
export 'domain/entities/settlement_entity.dart';
export 'domain/entities/challenge_settlement_data.dart';

// Domain - Repositories
export 'domain/repositories/currency_repository.dart';

// Domain - UseCases
export 'domain/usecases/calculate_reward.dart';
export 'domain/usecases/settle_daily_rewards.dart';
export 'domain/usecases/check_pending_settlements.dart';

// Data - Models
export 'data/models/currency_summary_model.dart';
export 'data/models/settlement_model.dart';

// Data - DataSources
export 'data/datasources/firestore_currency_datasource.dart';

// Data - Repositories
export 'data/repositories/currency_repository_impl.dart';

// Presentation - BLoC
export 'presentation/bloc/currency_bloc.dart';
export 'presentation/bloc/currency_event.dart';
export 'presentation/bloc/currency_state.dart';

// Presentation - Pages
export 'presentation/pages/settlement_history_page.dart';

// Presentation - Widgets
export 'presentation/widgets/currency_balance_widget.dart';
export 'presentation/widgets/settlement_dialog.dart';

