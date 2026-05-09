// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vision Companion';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get signUpTitle => 'Create Account';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get nameLabel => 'Full Name';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get feature1Title => 'Live Object Detector';

  @override
  String get feature1Description =>
      'Detect objects in real-time using your camera';

  @override
  String get feature2Title => 'AI Image Analyzer';

  @override
  String get feature2Description => 'Capture and analyze images with AI';

  @override
  String get startButton => 'Start';

  @override
  String get pauseDetection => 'Pause Detection';

  @override
  String get resumeDetection => 'Resume Detection';

  @override
  String get cameraFeedLabel => 'Live camera feed for object detection';

  @override
  String get captureImage => 'Capture & Analyze';

  @override
  String get analyzingImage => 'Analyzing image, please wait';

  @override
  String get processingLabel => 'Processing';

  @override
  String get retryButton => 'Retry';

  @override
  String get historyTitle => 'Detection History';

  @override
  String get noHistory => 'No history yet. Start using features!';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String profileLabel(String name) {
    return 'Profile: $name, tap to open menu';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get errorOccurred => 'Something went wrong. Please try again.';

  @override
  String get networkError => 'Network error. Check your connection.';

  @override
  String get analysisResults => 'Analysis Results';

  @override
  String get detectedTags => 'Detected Tags';

  @override
  String get dominantColors => 'Dominant Colors';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String tagLabel(String tag, String confidence) {
    return 'Tag: $tag, $confidence% confidence';
  }

  @override
  String selectedLanguage(String language) {
    return 'Language changed to $language';
  }

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objects detected',
      one: '1 object detected',
      zero: 'No objects detected',
    );
    return '$_temp0';
  }

  @override
  String get emailAddress => 'Email address';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get minCharacters => 'Min 6 characters';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get whatToExplore => 'What would you like to explore today?';

  @override
  String get joinVisionCompanion => 'Join Vision Companion';

  @override
  String get setupPremium => 'Set up your premium access';

  @override
  String get scanningText => 'Scanning...';

  @override
  String detectedText(String count) {
    return '$count detected';
  }

  @override
  String get pauseButton => 'Pause';

  @override
  String get resumeButton => 'Resume';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get goBack => 'Go back';

  @override
  String get objectDetection => 'Object detection';

  @override
  String get imageAnalysis => 'Image analysis';

  @override
  String get detector => 'Detector';

  @override
  String get analyzer => 'Analyzer';

  @override
  String get emailInputLabel => 'Email Input Field';

  @override
  String get passwordInputLabel => 'Password Input Field';

  @override
  String get signInButtonLabel => 'Sign In Button';

  @override
  String get googleSignInButtonLabel => 'Sign In with Google Button';

  @override
  String get navigateToSignUpLabel => 'Navigate to Sign Up';

  @override
  String get fullNameInputLabel => 'Full Name Input Field';

  @override
  String get signUpButtonLabel => 'Sign Up Button';

  @override
  String get navigateToSignInLabel => 'Navigate to Sign In';

  @override
  String get signOutButtonLabel => 'Sign Out Button';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get viewHistoryLabel => 'View detection history';

  @override
  String featureOpenLabel(String title, String description) {
    return '$title feature. $description. Tap to open.';
  }

  @override
  String detectedAnnouncement(String label, String confidence) {
    return 'Detected: $label $confidence';
  }

  @override
  String get retakePhotoLabel => 'Retake photo';

  @override
  String get captureImageLabel => 'Capture image';

  @override
  String get retryLabel => 'Retry';

  @override
  String get selected => 'selected';

  @override
  String get defaultUserName => 'User';

  @override
  String cameraStatus(String status) {
    return 'Ready: $status';
  }

  @override
  String detectionCountStatus(int count) {
    return 'Detections: $count';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';
}
