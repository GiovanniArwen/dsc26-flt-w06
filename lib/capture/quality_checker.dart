/// Plain image statistics used to accept or reject a claim photo before it
/// ever leaves the phone. No camera, no plugin: a [GrayImage] is just bytes.
import 'dart:typed_data';

/// A greyscale image, row-major, one byte (0-255) per pixel. Given: do not
/// change.
class GrayImage {
  const GrayImage({
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int width;
  final int height;

  /// Length must be `width * height`. `pixels[y * width + x]` is the pixel
  /// at column `x`, row `y`.
  final Uint8List pixels;
}

/// A problem found with a captured photo, in the order [checkQuality]
/// reports them. Given: do not change.
enum QualityIssue { tooSmall, tooDark, tooBright, blurry }

/// Default thresholds for [checkQuality]. Given: do not change.
class QualityThresholds {
  const QualityThresholds({
    this.minWidth = 640,
    this.minHeight = 480,
    this.darkBelow = 50,
    this.brightAbove = 215,
    this.minSharpness = 100,
  });

  final int minWidth;
  final int minHeight;
  final double darkBelow;
  final double brightAbove;
  final double minSharpness;
}

/// The mean of every pixel in [img]. An empty image (`width * height == 0`)
/// has a mean brightness of `0.0`.
double meanBrightness(GrayImage img) {
  final n = img.width * img.height;
  if (n <= 0) return 0.0;
  final px = img.pixels;
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += px[i];
  }
  return sum / n;
}

/// The population variance of the discrete Laplacian `L = top + bottom +
/// left + right - 4 * centre`, computed at every interior pixel (one pixel
/// away from every edge). Images narrower or shorter than 3 pixels, which
/// have no interior pixel, return `0.0`.
double laplacianVariance(GrayImage img) {
  final w = img.width;
  final h = img.height;
  if (w < 3 || h < 3) return 0.0;
  final px = img.pixels;
  final values = Int32List((w - 2) * (h - 2));
  var k = 0;
  var sum = 0;
  for (var y = 1; y < h - 1; y++) {
    final row = y * w;
    for (var x = 1; x < w - 1; x++) {
      final i = row + x;
      final l = px[i - w] + px[i + w] + px[i - 1] + px[i + 1] - 4 * px[i];
      values[k++] = l;
      sum += l;
    }
  }
  final n = values.length;
  final mean = sum / n;
  // Two-pass population variance (divide by n, not n - 1) for accuracy.
  var sq = 0.0;
  for (var i = 0; i < n; i++) {
    final d = values[i] - mean;
    sq += d * d;
  }
  return sq / n;
}

/// The quality problems with [img] against [thresholds], in [QualityIssue]
/// order. If the image is smaller than the minimum size, every other check
/// is skipped and only [QualityIssue.tooSmall] is reported.
List<QualityIssue> checkQuality(
  GrayImage img, {
  QualityThresholds thresholds = const QualityThresholds(),
}) {
  if (img.width < thresholds.minWidth || img.height < thresholds.minHeight) {
    return [QualityIssue.tooSmall];
  }
  final issues = <QualityIssue>[];
  final brightness = meanBrightness(img);
  if (brightness < thresholds.darkBelow) issues.add(QualityIssue.tooDark);
  if (brightness > thresholds.brightAbove) issues.add(QualityIssue.tooBright);
  if (laplacianVariance(img) < thresholds.minSharpness) {
    issues.add(QualityIssue.blurry);
  }
  return issues;
}
