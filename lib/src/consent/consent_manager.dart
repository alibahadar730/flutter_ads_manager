import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google's User Messaging Platform (UMP) SDK so GDPR/UK/US consent
/// is requested and, if required, the consent form is shown — automatically,
/// before any ad is loaded.
///
/// `AdsManager.init` calls [requestConsent] for you unless you pass
/// `requestConsent: false`.
class ConsentManager {
  /// Requests a consent info update and shows the consent form if one is
  /// required for the user's region.
  ///
  /// Returns true once the app is clear to request ads (consent obtained,
  /// not required, or the UMP flow failed and we chose to continue anyway
  /// rather than block ads entirely).
  ///
  /// Set [tagForUnderAgeOfConsent] to true if your app is directed at
  /// children under the age of consent.
  ///
  /// [testDeviceIds] and [debugGeography] let you force the EEA consent
  /// flow on a test device during development — see
  /// https://developers.google.com/admob/ump/android/test-guide
  Future<bool> requestConsent({
    bool tagForUnderAgeOfConsent = false,
    DebugGeography debugGeography = DebugGeography.debugGeographyDisabled,
    List<String> testDeviceIds = const [],
  }) async {
    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
      consentDebugSettings:
          debugGeography == DebugGeography.debugGeographyDisabled &&
                  testDeviceIds.isEmpty
              ? null
              : ConsentDebugSettings(
                  debugGeography: debugGeography,
                  testIdentifiers: testDeviceIds,
                ),
    );

    final updateCompleter = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => updateCompleter.complete(true),
      (_) => updateCompleter.complete(false),
    );
    final updateSucceeded = await updateCompleter.future;
    if (!updateSucceeded) {
      // e.g. no network — don't permanently block ad requests on this.
      return true;
    }

    if (!await ConsentInformation.instance.isConsentFormAvailable()) {
      return canRequestAds();
    }

    FormError? formError;
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      formError = error;
    });
    if (formError != null) return true;

    return canRequestAds();
  }

  /// Whether the app has completed the steps required to request ads
  /// (consent obtained where required, or not required at all).
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  /// Whether a "privacy options" entry point (e.g. a settings button that
  /// lets the user change their consent choice) must be shown in your UI.
  Future<bool> get isPrivacyOptionsRequired async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Shows the privacy options form so the user can change their consent
  /// choice. Only call this when [isPrivacyOptionsRequired] is true,
  /// typically from a "Privacy options" button in your settings screen.
  Future<void> showPrivacyOptionsForm() async {
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }

  /// Resets consent state. Only use this for testing.
  Future<void> reset() => ConsentInformation.instance.reset();
}
