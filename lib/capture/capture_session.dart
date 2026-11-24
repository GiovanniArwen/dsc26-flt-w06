/// The state of one claimant's 8-angle capture plus close-ups, independent
/// of the camera: whichever bytes `submit`/`addCloseUp` receive.
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../evidence/evidence.dart';
import 'capture_angle.dart';
import 'quality_checker.dart';

/// The outcome of submitting one photo. Given: do not change.
sealed class CaptureResult {
  const CaptureResult();
}

/// The photo was accepted.
class Accepted extends CaptureResult {
  const Accepted();
}

/// The photo failed the quality gate.
class Rejected extends CaptureResult {
  const Rejected(this.issues);
  final List<QualityIssue> issues;
}

/// The same bytes (by SHA-256) are already accepted somewhere. [existingAngle]
/// is the angle that already holds them, or `null` when the match is a
/// close-up.
class Duplicate extends CaptureResult {
  const Duplicate(this.existingAngle);
  final CaptureAngle? existingAngle;
}

/// Tracks the 8 required angles plus up to [maxCloseUps] close-ups for one
/// claim.
class CaptureSession extends ChangeNotifier {
  CaptureSession({this.maxCloseUps = 6});

  final int maxCloseUps;

  /// SHA-256 of the accepted photo for each angle.
  final Map<CaptureAngle, String> _angleHashes = {};

  /// SHA-256 of each accepted close-up, in acceptance order.
  final List<String> _closeUpHashes = [];

  /// The first angle, in enum order, with no accepted photo. `null` once
  /// every angle has one.
  CaptureAngle? get nextRequiredAngle {
    for (final angle in CaptureAngle.values) {
      if (!_angleHashes.containsKey(angle)) return angle;
    }
    return null;
  }

  bool get isComplete => _angleHashes.length == CaptureAngle.values.length;

  /// Accepted angles out of the 8 required, as a fraction.
  double get progress => _angleHashes.length / CaptureAngle.values.length;

  /// Number of angles with an accepted photo.
  int get acceptedCount => _angleHashes.length;

  /// Number of accepted close-ups.
  int get closeUpCount => _closeUpHashes.length;

  /// Submits a photo for [angle]. Rejects on quality issues first; then, if
  /// [angle] already has an accepted photo, throws [StateError] (a plain
  /// double submit, whatever the bytes); then checks for a duplicate against
  /// every other accepted angle and every close-up; otherwise accepts.
  CaptureResult submit(
    CaptureAngle angle,
    Uint8List bytes,
    List<QualityIssue> issues,
  ) {
    if (issues.isNotEmpty) return Rejected(List.unmodifiable(issues));
    if (_angleHashes.containsKey(angle)) {
      throw StateError('${angle.name} already has an accepted photo');
    }
    final hash = sha256Hex(bytes);
    final duplicate = _findDuplicate(hash);
    if (duplicate != null) return duplicate;
    _angleHashes[angle] = hash;
    notifyListeners();
    return const Accepted();
  }

  /// Removes the accepted photo for [angle] (if any), reopening it.
  void retake(CaptureAngle angle) {
    _angleHashes.remove(angle);
    notifyListeners();
  }

  /// Adds a close-up. Same quality and duplicate rules as [submit]; once
  /// [maxCloseUps] close-ups are accepted, further calls throw [StateError].
  CaptureResult addCloseUp(Uint8List bytes, List<QualityIssue> issues) {
    if (_closeUpHashes.length >= maxCloseUps) {
      throw StateError('Already have $maxCloseUps close-ups');
    }
    if (issues.isNotEmpty) return Rejected(List.unmodifiable(issues));
    final hash = sha256Hex(bytes);
    final duplicate = _findDuplicate(hash);
    if (duplicate != null) return duplicate;
    _closeUpHashes.add(hash);
    return const Accepted();
  }

  Duplicate? _findDuplicate(String hash) {
    for (final entry in _angleHashes.entries) {
      if (entry.value == hash) return Duplicate(entry.key);
    }
    if (_closeUpHashes.contains(hash)) return const Duplicate(null);
    return null;
  }
}
