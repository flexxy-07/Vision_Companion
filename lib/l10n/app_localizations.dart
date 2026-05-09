import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Vision Companion'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpTitle;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameLabel;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @feature1Title.
  ///
  /// In en, this message translates to:
  /// **'Live Object Detector'**
  String get feature1Title;

  /// No description provided for @feature1Description.
  ///
  /// In en, this message translates to:
  /// **'Detect objects in real-time using your camera'**
  String get feature1Description;

  /// No description provided for @feature2Title.
  ///
  /// In en, this message translates to:
  /// **'AI Image Analyzer'**
  String get feature2Title;

  /// No description provided for @feature2Description.
  ///
  /// In en, this message translates to:
  /// **'Capture and analyze images with AI'**
  String get feature2Description;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @pauseDetection.
  ///
  /// In en, this message translates to:
  /// **'Pause Detection'**
  String get pauseDetection;

  /// No description provided for @resumeDetection.
  ///
  /// In en, this message translates to:
  /// **'Resume Detection'**
  String get resumeDetection;

  /// No description provided for @cameraFeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Live camera feed for object detection'**
  String get cameraFeedLabel;

  /// No description provided for @captureImage.
  ///
  /// In en, this message translates to:
  /// **'Capture & Analyze'**
  String get captureImage;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image, please wait'**
  String get analyzingImage;

  /// No description provided for @processingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingLabel;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Detection History'**
  String get historyTitle;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet. Start using features!'**
  String get noHistory;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile: {name}, tap to open menu'**
  String profileLabel(String name);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorOccurred;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get networkError;

  /// No description provided for @analysisResults.
  ///
  /// In en, this message translates to:
  /// **'Analysis Results'**
  String get analysisResults;

  /// No description provided for @detectedTags.
  ///
  /// In en, this message translates to:
  /// **'Detected Tags'**
  String get detectedTags;

  /// No description provided for @dominantColors.
  ///
  /// In en, this message translates to:
  /// **'Dominant Colors'**
  String get dominantColors;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @tagLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag: {tag}, {confidence}% confidence'**
  String tagLabel(String tag, String confidence);

  /// No description provided for @selectedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String selectedLanguage(String language);

  /// No description provided for @detectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No objects detected} =1{1 object detected} other{{count} objects detected}}'**
  String detectionCount(int count);

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minCharacters;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @whatToExplore.
  ///
  /// In en, this message translates to:
  /// **'What would you like to explore today?'**
  String get whatToExplore;

  /// No description provided for @joinVisionCompanion.
  ///
  /// In en, this message translates to:
  /// **'Join Vision Companion'**
  String get joinVisionCompanion;

  /// No description provided for @setupPremium.
  ///
  /// In en, this message translates to:
  /// **'Set up your premium access'**
  String get setupPremium;

  /// No description provided for @scanningText.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanningText;

  /// No description provided for @detectedText.
  ///
  /// In en, this message translates to:
  /// **'{count} detected'**
  String detectedText(String count);

  /// No description provided for @pauseButton.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButton;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @objectDetection.
  ///
  /// In en, this message translates to:
  /// **'Object detection'**
  String get objectDetection;

  /// No description provided for @imageAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Image analysis'**
  String get imageAnalysis;

  /// No description provided for @detector.
  ///
  /// In en, this message translates to:
  /// **'Detector'**
  String get detector;

  /// No description provided for @analyzer.
  ///
  /// In en, this message translates to:
  /// **'Analyzer'**
  String get analyzer;

  /// No description provided for @emailInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Input Field'**
  String get emailInputLabel;

  /// No description provided for @passwordInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Password Input Field'**
  String get passwordInputLabel;

  /// No description provided for @signInButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign In Button'**
  String get signInButtonLabel;

  /// No description provided for @googleSignInButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google Button'**
  String get googleSignInButtonLabel;

  /// No description provided for @navigateToSignUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Sign Up'**
  String get navigateToSignUpLabel;

  /// No description provided for @fullNameInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name Input Field'**
  String get fullNameInputLabel;

  /// No description provided for @signUpButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Button'**
  String get signUpButtonLabel;

  /// No description provided for @navigateToSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Sign In'**
  String get navigateToSignInLabel;

  /// No description provided for @signOutButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Button'**
  String get signOutButtonLabel;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @viewHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'View detection history'**
  String get viewHistoryLabel;

  /// No description provided for @featureOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'{title} feature. {description}. Tap to open.'**
  String featureOpenLabel(String title, String description);

  /// No description provided for @detectedAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Detected: {label} {confidence}'**
  String detectedAnnouncement(String label, String confidence);

  /// No description provided for @retakePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get retakePhotoLabel;

  /// No description provided for @captureImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Capture image'**
  String get captureImageLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @cameraStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready: {status}'**
  String cameraStatus(String status);

  /// No description provided for @detectionCountStatus.
  ///
  /// In en, this message translates to:
  /// **'Detections: {count}'**
  String detectionCountStatus(int count);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
