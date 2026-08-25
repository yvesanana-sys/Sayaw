import 'package:flutter/material.dart';

/// Keeps the focused field above the on-screen keyboard.
///
/// On a Windows tablet the touch keyboard is raised over the bottom of the
/// window as soon as a text field takes focus, and — unlike a phone — the app
/// window is not resized to compensate. Without this, the field the user is
/// typing into sits underneath the keyboard they are typing on.
///
/// Wrap the *scrollable* with this, not the whole page: padding the page pushes
/// the scroll view's viewport up and the content clips instead of scrolling.
class KeyboardSafeArea extends StatelessWidget {
  const KeyboardSafeArea({
    super.key,
    required this.child,
    this.extra = 16.0,
  });

  final Widget child;

  /// Breathing room above the keyboard, so the focused field is not flush
  /// against its top edge.
  final double extra;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets > 0 ? insets + extra : 0),
      child: child,
    );
  }
}
