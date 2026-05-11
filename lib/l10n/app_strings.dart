import 'package:flutter/material.dart';
import '../services/language_notifier.dart';

class AppStrings {
  final bool isArabic;

  AppStrings(this.isArabic);

  static AppStrings of(BuildContext context) =>
      AppStrings(LangScope.of(context).isArabic);

  // ── Adventure Map ─────────────────────────────────────────
  String get adventureMap => isArabic ? 'خريطة المغامرة' : 'Adventure Map';
  String get chooseLevelPrompt =>
      isArabic ? 'اختر مستوى لبدء البرمجة!' : 'Choose a level to start coding!';
  String get completedLabel => isArabic ? 'مكتمل' : 'Completed';
  String get attemptsLabel => isArabic ? 'المحاولات' : 'Attempts';
  String get streakLabel => isArabic ? 'السلسلة' : 'Streak';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Log out';
  String get languageOption =>
      isArabic ? 'Switch to English 🌐' : 'التبديل إلى العربية 🌐';
  String get level => isArabic ? 'المستوى' : 'Level';

  String levelTitle(int n) {
    if (!isArabic) {
      return switch (n) {
        1 => 'Move Your Robot',
        2 => 'Make Some Noise',
        3 => 'Play with Colors',
        4 => 'Magic Screen',
        5 => 'Smart Moves',
        _ => 'Level $n',
      };
    }
    return switch (n) {
      1 => 'حرّك روبوتك',
      2 => 'أصدر بعض الأصوات',
      3 => 'العب بالألوان',
      4 => 'الشاشة السحرية',
      5 => 'تحركات ذكية',
      _ => 'المستوى $n',
    };
  }

  String comingSoon(int n, String title) => isArabic
      ? 'المستوى $n: $title — قريبًا!'
      : 'Level $n: $title — Coming soon!';

  // ── Code area (shared across level screens) ───────────────
  String get yourCode => isArabic ? 'الكود الخاص بك' : 'Your Code';
  String get run => isArabic ? 'تشغيل' : 'Run';
  String get running => isArabic ? 'يعمل...' : 'Running...';
  String get availableBlocks =>
      isArabic ? 'البلوكات المتاحة' : 'Available Blocks';
  String get tapOrDrag =>
      isArabic ? 'اضغط أو اسحب البلوكات لبناء حلك:' : 'Tap or drag blocks to build your solution:';
  String blocksCount(int n) =>
      isArabic ? '$n بلوك' : '$n block${n != 1 ? 's' : ''}';

  // ── Grid (Level 1) ────────────────────────────────────────
  String get grid => isArabic ? 'الشبكة' : 'Grid';
  String get robot => isArabic ? 'الروبوت' : 'Robot';
  String get target => isArabic ? 'الهدف' : 'Target';

  // ── Visualization labels ──────────────────────────────────
  String get logicToMatch => isArabic ? 'المنطق المطلوب' : 'Logic to Match';

  // ── Navigation ────────────────────────────────────────────
  String get previous => isArabic ? 'السابق' : 'Previous';
  String get next => isArabic ? 'التالي' : 'Next';

  // ── Connection ────────────────────────────────────────────
  String get offline => isArabic ? 'غير متصل' : 'Offline';
  String get connectingStatus => isArabic ? 'جارٍ الاتصال' : 'Connecting';
  String get connectedStatus => isArabic ? 'متصل' : 'Connected';
  String get executingStatus => isArabic ? 'يُنفَّذ' : 'Executing';
  String get connectBtn => isArabic ? 'اتصال' : 'Connect';

  // ── Banners ───────────────────────────────────────────────
  String get challengeCompleted =>
      isArabic ? 'اكتمل التحدي! 🎉' : 'Challenge Completed! 🎉';
  String streakMsg(bool renewed, int streakVal) {
    if (renewed) {
      return isArabic ? '🔥 السلسلة: $streakVal!' : '🔥 Streak: $streakVal!';
    }
    return isArabic ? 'عمل رائع! استمر 🌟' : 'Excellent work! Keep it up 🌟';
  }
  String get keepItUp => isArabic ? 'استمر! 🌟' : 'Keep it up! 🌟';
  String get tryAgain => isArabic ? 'حاول مجددًا' : 'Try again';
  String get wrongOrderMsg => isArabic
      ? 'الترتيب أو الحل خاطئ. صحّحه وأعد التشغيل.'
      : 'Wrong order or wrong solution. Fix it and run again.';
  String get checkSequenceMsg => isArabic
      ? 'تحقق من التسلسل المستهدف وحاول مجددًا.'
      : 'Check the target sequence and try again.';
  String get checkPatternMsg => isArabic
      ? 'تحقق من النمط المستهدف وحاول مجددًا.'
      : 'Check the target pattern and try again.';
  String get robotConnectedTitle =>
      isArabic ? 'الروبوت متصل!' : 'Robot connected!';
  String get robotConnectedSub =>
      isArabic ? 'تم الاتصال بالروبوت بنجاح.' : 'Robot connected successfully.';

  // ── Welcome screen ────────────────────────────────────────
  String get welcomeTo => isArabic ? 'مرحبًا بك في' : 'Welcome to';
  String get tagline =>
      isArabic ? 'تعلّم البرمجة مع روبوتك، خطوة بخطوة.' : 'Learn coding with your robot, step by step.';
  String get whatIsRoboLearn => isArabic ? 'ما هو روبوليرن؟' : 'What is RoboLearn?';
  String get roboLearnDesc => isArabic
      ? 'روبوليرن يساعد الأطفال على تعلّم أساسيات البرمجة ببناء بلوكات كود بسيطة والتحكم في روبوت حقيقي.'
      : 'RoboLearn helps kids learn programming basics by building simple code blocks and controlling a real robot.';
  String get howItWorks => isArabic ? 'كيف يعمل؟' : 'How It Works';
  String get stepSendLabel => isArabic ? 'أرسل' : 'Send';
  String get stepSendDesc => isArabic ? 'ابنِ البلوكات وأرسل' : 'Build blocks and send';
  String get stepExecuteLabel => isArabic ? 'نفّذ' : 'Execute';
  String get stepExecuteDesc => isArabic ? 'الروبوت يعمل فورًا' : 'Robot runs instantly';
  String get stepLearnLabel => isArabic ? 'تعلّم' : 'Learn';
  String get stepLearnDesc => isArabic ? 'تحسّن مع كل محاولة' : 'Improve with each try';
  String get whyFamilies =>
      isArabic ? 'لماذا تختار العائلات روبوليرن' : 'Why families choose RoboLearn';
  String get featureChildren => isArabic
      ? 'ممتع وبسيط للأطفال الراغبين في تعلّم البرمجة'
      : 'Fun and simple for children who want to learn programming';
  String get featureParents => isArabic
      ? 'آمن وسهل المتابعة للآباء الراغبين في دعم تعلّم أطفالهم'
      : "Safe and easy to monitor for parents who want to support their child's learning";
  String get readyToStart => isArabic ? 'هل أنت مستعد للبدء؟ 🚀' : 'Ready to start? 🚀';
  String get getStarted => isArabic ? 'ابدأ الآن' : 'Get Started';

  // ── Login screen ──────────────────────────────────────────
  String get welcomeBack => isArabic ? 'مرحبًا بعودتك! 👋' : 'Welcome Back! 👋';
  String get signInToContinue =>
      isArabic ? 'سجّل الدخول لمتابعة مغامرتك' : 'Sign in to continue your adventure';
  String get parentsEmail =>
      isArabic ? 'بريد ولي الأمر الإلكتروني' : "Parent's Email";
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get orDivider => isArabic ? 'أو' : 'or';
  String get noAccount => isArabic ? 'ليس لديك حساب؟ ' : "Don't have an account? ";
  String get signUpLink => isArabic ? 'إنشاء حساب' : 'Sign Up';
  String get forgotPasswordDialogBody => isArabic
      ? 'أدخل بريدك الإلكتروني وسنرسل لك رابط الإعادة.'
      : 'Enter your email and we will send you a reset link.';
  String get yourEmail => isArabic ? 'بريدك الإلكتروني' : 'Your email';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get enterPasswordToContinue =>
      isArabic ? 'أدخل كلمة المرور للمتابعة' : 'Enter your password to continue';
  String get sendLink => isArabic ? 'إرسال الرابط' : 'Send Link';
  String get resetEmailSent => isArabic
      ? 'إذا كان البريد موجودًا، تم إرسال رابط الإعادة.'
      : 'If this email exists, a reset link has been sent.';
  String get continueWithGoogle =>
      isArabic ? 'المتابعة بحساب Google' : 'Continue with Google';
  String get googleSignInFailed => isArabic
      ? 'فشل تسجيل الدخول بـ Google. حاول مجددًا.'
      : 'Google sign-in failed. Please try again.';

  // ── Auth error messages ───────────────────────────────────
  String authError(String code) {
    if (!isArabic) {
      return switch (code) {
        'invalid-email' => 'The email address format is invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Network error. Check your connection and retry.',
        'email-already-in-use' => 'This email is already in use.',
        'weak-password' => 'Password is too weak. Use at least 8 characters.',
        'operation-not-allowed' =>
          'Email/password auth is not enabled yet.',
        _ => 'Authentication failed. Please try again.',
      };
    }
    return switch (code) {
      'invalid-email' => 'صيغة البريد الإلكتروني غير صحيحة.',
      'user-disabled' => 'تم تعطيل هذا الحساب.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
      'too-many-requests' => 'محاولات كثيرة. يرجى المحاولة لاحقًا.',
      'network-request-failed' =>
        'خطأ في الشبكة. تحقق من اتصالك وأعد المحاولة.',
      'email-already-in-use' => 'هذا البريد الإلكتروني مستخدم بالفعل.',
      'weak-password' => 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.',
      'operation-not-allowed' =>
        'تسجيل الدخول بالبريد الإلكتروني غير مفعّل بعد.',
      _ => 'فشلت المصادقة. يرجى المحاولة مرة أخرى.',
    };
  }

  // ── Sign up screen ────────────────────────────────────────
  String get joinRoboLearn => isArabic ? 'انضم إلى روبوليرن! 🚀' : 'Join RoboLearn! 🚀';
  String get learningAsPlaying => isArabic ? 'التعلّم كاللعب!' : 'Learning as playing!';
  String get firstName => isArabic ? 'الاسم الأول' : 'First Name';
  String get lastName => isArabic ? 'الاسم الأخير' : 'Last Name';
  String get passwordHint =>
      isArabic ? 'كلمة المرور (8 أحرف على الأقل)' : 'Password (min 8 characters)';
  String get confirmPassword => isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get passwordsDoNotMatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get iAgreeToThe => isArabic ? 'أوافق على ' : 'I agree to the ';
  String get termsAndConditions =>
      isArabic ? 'الشروط والأحكام' : 'Terms and Conditions';
  String get createAccount => isArabic ? 'إنشاء حساب' : 'Create Account';
  String get alreadyHaveAccount =>
      isArabic ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ';
  String get termsDialogTitle => isArabic ? 'الشروط والخصوصية' : 'Terms & Privacy';
  String get termsDialogBody => isArabic
      ? 'الشروط والأحكام وسياسة الخصوصية\n'
          'آخر تحديث: مايو 2025\n\n'
          '1. القبول والاستخدام\n'
          'باستخدامك لتطبيق روبوليرن، فأنت تؤكد موافقتك على هذه الشروط، سواء كنت ولي أمر أو مشرفًا على الطفل، أو طفلًا يمتلك الوعي الكافي للاستخدام المستقل.\n\n'
          '2. إنشاء الحساب\n'
          'يمكن لأي شخص إنشاء حساب على التطبيق، بما في ذلك الأطفال الذين لديهم القدرة على فهم طبيعة التطبيق والتعامل معه بشكل مسؤول. ويُنصح الآباء بمرافقة أطفالهم الصغار خلال التجربة.\n\n'
          '3. البيانات التي نجمعها\n'
          'نجمع بريدك الإلكتروني واسمك عند التسجيل، وبيانات تقدّم الأطفال (المستويات المكتملة والمحاولات) لعرضها لك. لا نجمع أي بيانات حساسة أو نشاركها مع أطراف خارجية لأغراض تجارية.\n\n'
          '4. أمان الحساب\n'
          'أنت مسؤول عن الحفاظ على سرية بيانات دخولك. في حال الاشتباه بأي وصول غير مصرح به، يرجى تغيير كلمة المرور فورًا.\n\n'
          '5. منطقة الآباء\n'
          'منطقة الآباء محمية بكلمة مرور لضمان ألا يتمكن الأطفال من تعديل الإعدادات أو الاطلاع على بيانات الحساب.\n\n'
          '6. التعديلات\n'
          'نحتفظ بحق تحديث هذه الشروط في أي وقت. سيتم إعلامك بأي تغييرات جوهرية عبر التطبيق.\n\n'
          'robolearnapp1@gmail.com'
      : 'Terms & Conditions and Privacy Policy\n'
          'Last updated: May 2025\n\n'
          '1. Acceptance of Terms\n'
          'By using RoboLearn, you confirm that you agree to these terms — whether you are a parent or guardian supervising a child, or a child who is mature enough to use the app independently.\n\n'
          '2. Account Creation\n'
          'Anyone may create an account on RoboLearn, including children who have a sufficient understanding of the app and can engage with it responsibly. Parents are encouraged to accompany younger children throughout the experience.\n\n'
          '3. Data We Collect\n'
          'We collect your email address and name upon registration, and your child\'s progress data (completed levels and attempts) to display to you. We do not collect sensitive data or share it with third parties for commercial purposes.\n\n'
          '4. Account Security\n'
          'You are responsible for keeping your login credentials confidential. If you suspect unauthorized access, please change your password immediately.\n\n'
          '5. Parents Area\n'
          'The Parents Area is password-protected to ensure children cannot modify settings or access account information.\n\n'
          '6. Changes to These Terms\n'
          'We reserve the right to update these terms at any time. You will be notified of any material changes through the app.\n\n'
          'robolearnapp1@gmail.com';
  String get gotIt => isArabic ? 'حسنًا! ✓' : 'Got it! ✓';

  // ── Choose child screen ───────────────────────────────────
  String get whoIsPlayingToday =>
      isArabic ? 'من يلعب اليوم؟ 🎮' : 'Who is playing today? 🎮';
  String get tapToSelectPrompt => isArabic
      ? 'اضغط على بطاقة للاختيار، ثم اضغط هيا نلعب!'
      : "Tap a card to select, then press Let's Play!";
  String get noChildProfiles =>
      isArabic ? 'لا توجد ملفات أطفال بعد' : 'No child profiles yet';
  String get openParentsAreaHint => isArabic
      ? 'افتح منطقة الآباء لإضافة ملف طفل.\nثم ارجع هنا لبدء اللعب.'
      : 'Open Parents Area to add a child profile.\nThen come back here to start playing.';
  String get pleaseChooseChild =>
      isArabic ? 'يرجى اختيار طفل أولاً!' : 'Please choose a child first!';
  String get letsPlay => isArabic ? 'هيا نلعب!' : "Let's Play!";
  String get parentsArea => isArabic ? 'منطقة الآباء' : 'Parents Area';
  String get lvPrefix => isArabic ? 'المستوى' : 'Lv';
  String get couldNotLoadChildren =>
      isArabic ? 'تعذّر تحميل بيانات الأطفال' : 'Could not load children';

  // ── Challenge titles & instructions ───────────────────────
  // Code block labels always stay in English (not translated here).
  // targetDisplay is code/logic structure — stays in English too.

  static const Map<int, Map<String, String>> _ar = {
    // Level 1 – Movement
    1: {
      'title': 'تحرك للأمام',
      'instruction': 'حاول تحريك روبوتك خطوة واحدة إلى الأمام',
    },
    2: {
      'title': 'تحرك للخلف',
      'instruction': 'حاول تحريك روبوتك خطوة واحدة إلى الخلف',
    },
    3: {
      'title': 'تحرك لليمين',
      'instruction': 'حرّك روبوتك إلى اليمين',
    },
    4: {
      'title': 'تحرك لليمين - متعدد',
      'instruction': 'حرّك روبوتك 3 خطوات إلى اليمين',
    },
    5: {
      'title': 'تحرك لليسار',
      'instruction': 'حرّك روبوتك إلى اليسار',
    },
    6: {
      'title': 'تحرك لليسار - متعدد',
      'instruction': 'حرّك روبوتك خطوتين إلى اليسار',
    },
    // Level 2 – Sound logic
    7: {
      'title': 'موسيقى سعيدة',
      'instruction': 'ابنِ المنطق عندما يظهر رمز السعادة:',
    },
    8: {
      'title': 'ردّ فعل حزين',
      'instruction': 'ابنِ المنطق عندما يظهر رمز الحزن:',
    },
    9: {
      'title': 'النهار والليل',
      'instruction': 'مثّل المنطق التالي ببلوكات الكود المناسبة:',
    },
    10: {
      'title': 'السلاسل',
      'instruction': 'ابنِ نظام مكافأة السلاسل باستخدام بلوكات الكود!',
    },
    11: {
      'title': 'خمّن الحيوان',
      'instruction': 'خمّن الحيوان باستخدام بلوكات IF المتداخلة:',
    },
    // Level 3 – LED
    12: {
      'title': 'الوميض الأول',
      'instruction': 'أضئه! شغّل الصمام الأحمر، انتظر، ثم أطفئه.',
    },
    13: {
      'title': 'وميض 3 مرات',
      'instruction': 'استخدم REPEAT 3× لإومض الصمام الأحمر 3 مرات!',
    },
    14: {
      'title': 'استعراض الألوان',
      'instruction': 'داخل الحلقة، أظهر الأحمر ثم الأخضر ثم الأزرق!',
    },
    15: {
      'title': 'وميض أصفر',
      'instruction': 'أومض الصمام الأصفر مرتين باستخدام REPEAT 2×!',
    },
    16: {
      'title': 'إشارة المرور',
      'instruction': 'أومض الأحمر 3 مرات أولاً، ثم أومض الأخضر مرتين!',
    },
    17: {
      'title': 'دوران قوس قزح',
      'instruction':
          'أومض الأحمر مرتين أولاً، ثم دوّر الأحمر ← الأخضر ← الأزرق 3 مرات!',
    },
  };

  String challengeTitle(int number, String fallback) {
    if (!isArabic) return fallback;
    return _ar[number]?['title'] ?? fallback;
  }

  String challengeInstruction(int number, String fallback) {
    if (!isArabic) return fallback;
    return _ar[number]?['instruction'] ?? fallback;
  }
}
