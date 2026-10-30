import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class CustomKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearPressed;
  final VoidCallback onDividePressed;
  final VoidCallback onSubmitPressed;
  final bool canSubmit;

  const CustomKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onClearPressed,
    required this.onDividePressed,
    required this.onSubmitPressed,
    required this.canSubmit,
  });

  Widget _buildKey({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    Color? splashColor,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: backgroundColor ?? AppColors.surfaceKeypad,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            onLongPress: onLongPress != null
                ? () {
                    HapticFeedback.mediumImpact();
                    onLongPress();
                  }
                : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: splashColor ?? AppColors.mint.withValues(alpha: 0.2),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextKey(String text, {VoidCallback? customAction, Color? textColor, int flex = 1}) {
    return _buildKey(
      flex: flex,
      onTap: customAction ?? () => onDigitPressed(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Riga 1: 1, 2, 3, ÷
          Row(
            children: [
              _buildTextKey('1'),
              _buildTextKey('2'),
              _buildTextKey('3'),
              _buildKey(
                backgroundColor: AppColors.surfaceElevated,
                onTap: onDividePressed,
                child: Text(
                  '÷',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
          // Riga 2: 4, 5, 6, ⌫
          Row(
            children: [
              _buildTextKey('4'),
              _buildTextKey('5'),
              _buildTextKey('6'),
              _buildKey(
                backgroundColor: AppColors.surfaceElevated,
                onTap: onDeletePressed,
                onLongPress: onClearPressed,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Riga 3: 7, 8, 9, .
          Row(
            children: [
              _buildTextKey('7'),
              _buildTextKey('8'),
              _buildTextKey('9'),
              _buildTextKey(',', customAction: () => onDigitPressed(',')),
            ],
          ),
          // Riga 4: 0 e Pulsante "SEGNA"
          Row(
            children: [
              _buildTextKey('0', flex: 1),
              _buildKey(
                flex: 3,
                backgroundColor: canSubmit ? AppColors.purple : AppColors.surfaceElevated,
                onTap: canSubmit ? onSubmitPressed : () {},
                splashColor: Colors.white.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: canSubmit ? AppColors.goldCoin : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SEGNA IN UN LAMPO',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: canSubmit ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
