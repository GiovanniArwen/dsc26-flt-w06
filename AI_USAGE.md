# AI Usage – W6

## 1. Tools I used
- Claude Code for implementation guidance, writing extra tests, and reviewing the logic against the README.
- Flutter test framework for validating the implementation.
- Dart analyzer for checking code quality and potential errors.

## 2. My best prompts
1. Implement the Laplacian variance exactly as the README says: interior pixels only, population variance (divide by n), and return 0.0 for images smaller than 3 pixels. Then compare it with a simple naive version on random images and make sure 640×480 runs in under 200 ms.
2. Implement the camera permission flow so it never calls request() more than once per action, never requests when a rationale should be shown first, and only opens Settings when the user taps the settings button. Write a fake gateway that counts every request() and openSettings() call.

## 3. One place the assistant got the maths or the permission rules wrong
The first version of laplacianVariance used the one-pass formula (sum of squares / n − mean²). It is correct on paper, but with doubles it subtracts two very large numbers that are almost equal, so it can lose precision on big sharp images. The grader compares H02 with a tight tolerance, so this was risky.
I changed it to a two-pass version: first store all the L values and get the mean, then average (L − mean)². I caught it by testing against a naive implementation on random images (5×4, 17×9 and 640×480). I also made sure it divides by n and not n − 1, because the checkerboard test (1040400) only passes with n.

## 4. Phone or server: Wiqaya's guided capture
The quality check, the angle order, the duplicate check and the permission flow should run on the phone, because the claimant needs instant feedback to retake a bad photo even with a weak connection, and nothing needs to be uploaded for that.
The server should recompute the SHA-256 and verify the evidence record by itself, and run any heavy damage analysis, because the phone is in the claimant's hands and its results cannot be trusted as final evidence for the claim.
