import 'package:flutter/material.dart';

/// The maximum height a dialog's content may occupy so the whole dialog
/// stays on screen (centered).
///
/// The result never exceeds 75% of the screen height and does NOT depend
/// on the on-screen keyboard: the dialog keeps its exact size and is moved
/// (translated) instead of resized when the keyboard appears.
///
/// Set [subtractKeyboard] to true only for dialogs that should shrink to
/// fit above the keyboard (e.g. pickers with a scrollable list).
///
/// [verticalMargin] is the total vertical space reserved around the content
/// (dialog inset padding, title, actions, etc.) in addition to the system
/// insets.
double dialogContentMaxHeight(
  BuildContext context, {
  double verticalMargin = 96,
  bool subtractKeyboard = false,
}) {
  final media = MediaQuery.of(context);
  var available = media.size.height -
      media.padding.top -
      media.padding.bottom -
      verticalMargin;
  if (subtractKeyboard) {
    available -= media.viewInsets.bottom;
  }
  final maxByPercent = media.size.height * 0.75;
  final result = available < maxByPercent ? available : maxByPercent;
  return result < 120 ? 120 : result;
}

/// Positions a dialog centered on screen, but when the on-screen keyboard
/// is visible it moves the dialog up so its bottom edge rests [gap] pixels
/// above the keyboard. The dialog is never resized (only its Y position
/// changes) and it stays centered horizontally in both states.
class KeyboardAwareDialogLayout extends SingleChildLayoutDelegate {
  const KeyboardAwareDialogLayout({required this.keyboard, this.gap = 16});

  /// Current height of the on-screen keyboard in pixels.
  final double keyboard;

  /// Distance between the dialog's bottom edge and the keyboard's top edge.
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().copyWith(minWidth: 0.0, minHeight: 0.0);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (size.width - childSize.width) / 2;
    if (keyboard <= 0) {
      return Offset(x, (size.height - childSize.height) / 2);
    }
    return Offset(x, size.height - keyboard - gap - childSize.height);
  }

  @override
  bool shouldRelayout(covariant KeyboardAwareDialogLayout oldDelegate) {
    return keyboard != oldDelegate.keyboard || gap != oldDelegate.gap;
  }
}
