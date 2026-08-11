import 'package:flutter/material.dart';
import '../screens/aura_chat_screen.dart';

/// The floating "Aura" companion button that follows the user around the
/// app and can be dragged, mirroring the draggable FAB in the mockups.
class AuraFab extends StatefulWidget {
  const AuraFab({super.key});

  @override
  State<AuraFab> createState() => _AuraFabState();
}

class _AuraFabState extends State<AuraFab> {
  Offset _offset = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      right: 16 - _offset.dx,
      bottom: 96 - _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() => _offset -= details.delta),
        child: Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: scheme.primary.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuraChatScreen()),
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.bubble_chart, color: scheme.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
