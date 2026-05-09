// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'विज़न कंपेनियन';

  @override
  String get loginTitle => 'वापस स्वागत है';

  @override
  String get loginSubtitle => 'जारी रखने के लिए साइन इन करें';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get signInButton => 'साइन इन';

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get noAccount => 'खाता नहीं है? साइन अप करें';

  @override
  String get signUpTitle => 'खाता बनाएं';

  @override
  String get signUpButton => 'साइन अप';

  @override
  String get haveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get nameLabel => 'पूरा नाम';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get feature1Title => 'लाइव ऑब्जेक्ट डिटेक्टर';

  @override
  String get feature1Description => 'कैमरे से रियल-टाइम में वस्तुओं को पहचानें';

  @override
  String get feature2Title => 'AI इमेज एनालाइज़र';

  @override
  String get feature2Description => 'AI से छवियां कैप्चर और विश्लेषण करें';

  @override
  String get startButton => 'शुरू करें';

  @override
  String get pauseDetection => 'डिटेक्शन रोकें';

  @override
  String get resumeDetection => 'डिटेक्शन फिर शुरू करें';

  @override
  String get cameraFeedLabel => 'ऑब्जेक्ट डिटेक्शन के लिए लाइव कैमरा फ़ीड';

  @override
  String get captureImage => 'कैप्चर करें और विश्लेषण करें';

  @override
  String get analyzingImage =>
      'इमेज का विश्लेषण हो रहा है, कृपया प्रतीक्षा करें';

  @override
  String get processingLabel => 'प्रोसेसिंग';

  @override
  String get retryButton => 'पुनः प्रयास करें';

  @override
  String get historyTitle => 'डिटेक्शन इतिहास';

  @override
  String get noHistory => 'अभी कोई इतिहास नहीं। फ़ीचर का उपयोग शुरू करें!';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिन्दी';

  @override
  String profileLabel(String name) {
    return 'प्रोफ़ाइल: $name, मेनू खोलने के लिए टैप करें';
  }

  @override
  String get signOut => 'साइन आउट';

  @override
  String get errorOccurred => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get networkError => 'नेटवर्क त्रुटि। अपना कनेक्शन जांचें।';

  @override
  String get analysisResults => 'विश्लेषण परिणाम';

  @override
  String get detectedTags => 'पहचाने गए टैग';

  @override
  String get dominantColors => 'प्रमुख रंग';

  @override
  String get retakePhoto => 'फिर से फ़ोटो लें';

  @override
  String tagLabel(String tag, String confidence) {
    return 'टैग: $tag, $confidence% विश्वसनीयता';
  }

  @override
  String selectedLanguage(String language) {
    return 'भाषा $language में बदल दी गई';
  }

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तुएं मिलीं',
      one: '1 वस्तु मिली',
      zero: 'कोई वस्तु नहीं मिली',
    );
    return '$_temp0';
  }

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get enterValidEmail => 'एक मान्य ईमेल दर्ज करें';

  @override
  String get enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get minCharacters => 'न्यूनतम 6 वर्ण';

  @override
  String get continueWithGoogle => 'गूगल के साथ जारी रखें';

  @override
  String get whatToExplore => 'आज आप क्या एक्सप्लोर करना चाहेंगे?';

  @override
  String get joinVisionCompanion => 'विज़न कंपेनियन में शामिल हों';

  @override
  String get setupPremium => 'अपनी प्रीमियम एक्सेस सेटअप करें';

  @override
  String get scanningText => 'स्कैनिंग...';

  @override
  String detectedText(String count) {
    return '$count पहचाना गया';
  }

  @override
  String get pauseButton => 'रोकें';

  @override
  String get resumeButton => 'जारी रखें';

  @override
  String get showPassword => 'पासवर्ड दिखाएं';

  @override
  String get hidePassword => 'पासवर्ड छुपाएं';

  @override
  String get goBack => 'वापस जाएं';

  @override
  String get objectDetection => 'वस्तु पहचान';

  @override
  String get imageAnalysis => 'छवि विश्लेषण';

  @override
  String get detector => 'डिटेक्टर';

  @override
  String get analyzer => 'एनालाइज़र';

  @override
  String get emailInputLabel => 'ईमेल इनपुट फ़ील्ड';

  @override
  String get passwordInputLabel => 'पासवर्ड इनपुट फ़ील्ड';

  @override
  String get signInButtonLabel => 'साइन इन बटन';

  @override
  String get googleSignInButtonLabel => 'गूगल के साथ साइन इन बटन';

  @override
  String get navigateToSignUpLabel => 'साइन अप पर जाएं';

  @override
  String get fullNameInputLabel => 'पूरा नाम इनपुट फ़ील्ड';

  @override
  String get signUpButtonLabel => 'साइन अप बटन';

  @override
  String get navigateToSignInLabel => 'साइन इन पर जाएं';

  @override
  String get signOutButtonLabel => 'साइन आउट बटन';

  @override
  String get settingsLabel => 'सेटिंग्स';

  @override
  String get viewHistoryLabel => 'डिटेक्शन इतिहास देखें';

  @override
  String featureOpenLabel(String title, String description) {
    return '$title सुविधा। $description। खोलने के लिए टैप करें।';
  }

  @override
  String detectedAnnouncement(String label, String confidence) {
    return 'पहचाना गया: $label $confidence';
  }

  @override
  String get retakePhotoLabel => 'फिर से फोटो लें';

  @override
  String get captureImageLabel => 'छवि कैप्चर करें';

  @override
  String get retryLabel => 'पुनः प्रयास करें';

  @override
  String get selected => 'चयनित';

  @override
  String get defaultUserName => 'उपयोगकर्ता';

  @override
  String cameraStatus(String status) {
    return 'तैयार: $status';
  }

  @override
  String detectionCountStatus(int count) {
    return 'डिटेक्शन: $count';
  }

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';
}
