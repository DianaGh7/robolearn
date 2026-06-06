import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Shared helpers for adapting layouts to different screen sizes.
class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isNarrow(BuildContext context) => width(context) < 360;

  static bool isVeryNarrow(BuildContext context) => width(context) < 340;

  /// Scales a base font size down slightly on narrow phones.
  static double fontSize(BuildContext context, double base) {
    final w = width(context);
    if (w < 320) return base * 0.85;
    if (w < 360) return base * 0.92;
    return base;
  }
}

/// Back / continue hints below intro speech bubbles.
/// Wraps to a second line instead of overflowing horizontally.
class SpeechBubbleHintRow extends StatelessWidget {
  final bool showBackHint;
  final VoidCallback? onBack;

  const SpeechBubbleHintRow({
    super.key,
    required this.showBackHint,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hintStyle = GoogleFonts.nunito(
      fontSize: Responsive.fontSize(context, 12),
      fontWeight: FontWeight.w700,
      color: AppTheme.tealPrimary.withValues(alpha: 0.55),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showBackHint)
          GestureDetector(
            onTap: onBack,
            child: Text(s.tapToGoBack, style: hintStyle),
          ),
        Text(s.tapToContinue, style: hintStyle),
      ],
    );
  }
}

/// Tutorial intro header: badge + title + skip, safe on narrow screens.
class IntroTutorialHeaderRow extends StatelessWidget {
  final Widget badge;
  final String title;
  final TextStyle titleStyle;
  final Widget skipButton;

  const IntroTutorialHeaderRow({
    super.key,
    required this.badge,
    required this.title,
    required this.titleStyle,
    required this.skipButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        badge,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle.copyWith(
              fontSize: Responsive.fontSize(context, titleStyle.fontSize ?? 15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        skipButton,
      ],
    );
  }
}
