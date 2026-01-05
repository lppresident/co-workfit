import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:co_workfit/features/currency/presentation/bloc/currency_state.dart';

/// 재화 잔액 표시 위젯
class CurrencyBalanceWidget extends StatelessWidget {
  /// 표시할 재화 타입 (null이면 모든 재화 표시)
  final CurrencyType? currencyType;

  /// 컴팩트 모드 (아이콘만 표시)
  final bool compact;

  /// 누적 획득량도 표시할지
  final bool showLifetime;

  const CurrencyBalanceWidget({
    super.key,
    this.currencyType,
    this.compact = false,
    this.showLifetime = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        if (state is CurrencyLoading) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (state is CurrencyLoaded) {
          if (currencyType != null) {
            return _buildSingleCurrency(
              context,
              currencyType!,
              state.getAmount(currencyType!),
              showLifetime ? state.getLifetimeEarned(currencyType!) : null,
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: CurrencyType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildSingleCurrency(
                  context,
                  type,
                  state.getAmount(type),
                  showLifetime ? state.getLifetimeEarned(type) : null,
                ),
              );
            }).toList(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSingleCurrency(
    BuildContext context,
    CurrencyType type,
    int amount,
    int? lifetime,
  ) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            _formatNumber(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: type.color,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: type.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _formatNumber(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: type.color,
                ),
              ),
            ],
          ),
          if (lifetime != null) ...[
            const SizedBox(height: 2),
            Text(
              '누적: ${_formatNumber(lifetime)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}


