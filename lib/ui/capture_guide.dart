/// The small widget that tells the claimant which angle to shoot next.
import 'package:flutter/material.dart';

import '../capture/capture_angle.dart';
import '../capture/capture_session.dart';

class CaptureGuide extends StatelessWidget {
  const CaptureGuide({super.key, required this.session});

  final CaptureSession session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final next = session.nextRequiredAngle;
        if (session.isComplete || next == null) {
          return const Row(
            key: Key('capture-complete'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('All 8 angles captured'),
            ],
          );
        }
        final total = CaptureAngle.values.length;
        final step = session.acceptedCount + 1;
        final label = angleLabel(next);
        return Semantics(
          key: const Key('capture-step'),
          container: true,
          excludeSemantics: true,
          label: 'Step $step of $total: $label',
          child: Text(
            label,
            key: const Key('capture-instruction'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
    );
  }
}
