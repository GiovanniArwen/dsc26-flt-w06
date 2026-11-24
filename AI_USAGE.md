# AI usage: dsc26-flt-w06

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

- Claude Code (Claude Opus) to implement the five parts and to write extra local tests.
- `flutter test` and `flutter analyze` to check the result.

## 2. My best prompts

1. "Implement `laplacianVariance` exactly as the README says: interior pixels only, `L = top + bottom + left + right − 4 × centre`, population variance (divide by n), 0.0 for images under 3 px; then check it against a naive implementation on random images, including 640×480 under 200 ms."
2. "Implement `CameraPermissionFlow` so that `request()` is called at most once per user action, never when a rationale should be shown first, and `openSettings()` only from `onOpenSettingsTapped`; write a fake gateway that counts `request()` and `openSettings()` calls for every status."

## 3. One place the assistant got the maths or the permission rules wrong

The first draft of `laplacianVariance` used the one-pass shortcut `sumSq / n − mean²`. It is mathematically the population variance, but in doubles it subtracts two large, nearly equal numbers, so on big, sharp images it loses precision, and H02 compares against a reference with a tight tolerance. I switched to a two-pass version (store every L, compute the mean, then average `(L − mean)²`) and checked it against a naive implementation on random 5×4, 17×9 and 640×480 images. I also checked that it divides by n and not n − 1, because the public checkerboard test (1040400) only passes with n.

## 4. Phone or server: Wiqaya's guided capture

I would run the quality gate (brightness and Laplacian sharpness), the angle sequence, the duplicate check and the permission flow on the phone, because the claimant needs instant "retake this" feedback even with weak signal, and nothing has to be uploaded for that. The server should recompute the SHA-256 and check the canonical evidence record independently, and it should also run any heavier damage analysis, because the phone is in the claimant's hands and its results cannot be trusted as final evidence for a claim.
