import "package:in_app_review/in_app_review.dart";
import "package:yivi_core/yivi_core.dart";

/// Play Store / App Store implementation of [StoreReviewService], wrapping the
/// `in_app_review` package (Google Play In-App Review on Android, SKStoreReview
/// on iOS). Lives here in `yivi_app` so the proprietary dependency stays out of
/// the FOSS `yivi_fdroid` build, which injects no service at all.
class InAppReviewStoreReviewService implements StoreReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();
}
