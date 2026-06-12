import 'package:flutter/material.dart';
import '../models/challenge_model.dart';
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
  String get levelsLabel => isArabic ? 'المستويات' : 'Levels';
  String get challengesLabel => isArabic ? 'التحديات' : 'Challenges';
  String ageYears(int age) => isArabic ? '$age سنة' : '$age yrs';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Log out';
  String get languageOption =>
      isArabic ? 'Switch to English 🌐' : 'التبديل إلى العربية 🌐';
  String get languageLabel => isArabic ? 'اللغة' : 'Language';
  String get level => isArabic ? 'المستوى' : 'Level';
  String levelBadge(int level) => isArabic ? 'المستوى $level' : 'Lv $level';
  String levelProgress(int current, int total, int percent) => isArabic
      ? '$current / $total مستويات • $percent%'
      : '$current / $total levels • $percent%';
  String days(int count) => isArabic ? '$count يوم' : '$count days';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get dropBlockHere => isArabic ? 'أفلت البلوك هنا' : 'drop block here';
  String get ifInsideAnotherIf =>
      isArabic ? 'يمكن أن يكون IF داخل IF!' : 'IF can go INSIDE another IF!';
  String get nestedExplanation =>
      isArabic ? 'هذا ما يسمى بالتداخل! 🐾' : "That's called Nested! 🐾";
  String get bigAnimalQuestion => isArabic ? 'حيوان كبير؟' : 'Big animal?';
  String get checkAgainInside =>
      isArabic ? '→ افحص مرة أخرى بالداخل!' : '→ check AGAIN inside!';
  String get tallNoseQuestion => isArabic ? 'أنف طويل؟' : 'Tall nose?';
  String get checkInsideLabel => isArabic ? 'افحص بالداخل:' : 'Check INSIDE:';
  String get elephantLabel => isArabic ? 'فيل!' : 'elephant!';
  String get lionLabel => isArabic ? 'أسد!' : 'lion!';
  String get yes => isArabic ? 'نعم' : 'YES!';
  String get no => isArabic ? 'لا' : 'NO';
  String blockLabel(CodeBlockType type) {
    switch (type) {
      case CodeBlockType.start:
        return 'START';
      case CodeBlockType.moveForward:
        return 'Move Forward';
      case CodeBlockType.moveBackward:
        return 'Move Backward';
      case CodeBlockType.moveLeft:
        return 'Move Left';
      case CodeBlockType.moveRight:
        return 'Move Right';
      case CodeBlockType.turnLeft:
        return 'Turn Left';
      case CodeBlockType.turnRight:
        return 'Turn Right';
      case CodeBlockType.end:
        return 'END';
      case CodeBlockType.beep:
        return 'beep 🔊';
      case CodeBlockType.clap:
        return 'clap 👏';
      case CodeBlockType.happy:
        return 'smile 😊';
      case CodeBlockType.repeat:
        return 'repeat';
      case CodeBlockType.ifHappy:
        return 'IF happy 😊';
      case CodeBlockType.music:
        return 'play music 🎵';
      case CodeBlockType.ifSad:
        return 'IF sad 😢';
      case CodeBlockType.cry:
        return 'sad tone';
      case CodeBlockType.ifMoon:
        return 'IF moon 🌙';
      case CodeBlockType.thenNight:
        return 'show night 🌃';
      case CodeBlockType.elseIfSun:
        return 'ELSE IF sun ☀️';
      case CodeBlockType.thenMorning:
        return 'show morning 🌅';
      case CodeBlockType.ifStreak5:
        return 'IF streak >= 5';
      case CodeBlockType.cheering:
        return 'cheer 🎉';
      case CodeBlockType.elseIfStreak2:
        return 'ELSE IF streak >= 2';
      case CodeBlockType.elseBlock:
        return 'ELSE';
      case CodeBlockType.encourage:
        return 'keep going! 💪';
      case CodeBlockType.ifBig:
        return 'IF big 🐾';
      case CodeBlockType.ifHasTrunk:
        return 'IF tall nose 🐽';
      case CodeBlockType.elephantSound:
        return 'elephant 🐘';
      case CodeBlockType.lionSound:
        return 'lion 🦁';
      case CodeBlockType.ifFluffy:
        return 'IF fluffy';
      case CodeBlockType.catSound:
        return 'cat 🐱';
      case CodeBlockType.dogSound:
        return 'dog 🐶';
      case CodeBlockType.setRed:
        return 'set RED 🔴';
      case CodeBlockType.setGreen:
        return 'set GREEN 🟢';
      case CodeBlockType.setBlue:
        return 'set BLUE 🔵';
      case CodeBlockType.setYellow:
        return 'set YELLOW 🟡';
      case CodeBlockType.ledOff:
        return 'LED off ⚫';
      case CodeBlockType.waitShort:
        return 'wait ⏱️';
      case CodeBlockType.ledRepeat3:
        return 'REPEAT 3×';
      case CodeBlockType.ledRepeat2:
        return 'REPEAT 2×';
      case CodeBlockType.ledRepeat5:
        return 'REPEAT 5×';
      case CodeBlockType.varSetScore:
        return 'score = 10';
      case CodeBlockType.varSetZero:
        return 'score = 0';
      case CodeBlockType.varAdd5:
        return 'score = score + 5';
      case CodeBlockType.varShowScore:
        return 'show score';
      case CodeBlockType.varSetCount:
        return 'count = 0';
      case CodeBlockType.varRepeat3:
        return 'REPEAT 3×';
      case CodeBlockType.varAddOne:
        return 'count + 1';
      case CodeBlockType.varShowCount:
        return 'show count';
      case CodeBlockType.varSetTempHot:
        return 'temp = 40';
      case CodeBlockType.varIfHot:
        return 'IF temp > 30';
      case CodeBlockType.varShowSun:
        return 'show ☀️';
      case CodeBlockType.varElse:
        return 'ELSE';
      case CodeBlockType.varShowSnow:
        return 'show ❄️';
      case CodeBlockType.varSetA:
        return 'speedA = 8';
      case CodeBlockType.varSetB:
        return 'speedB = 3';
      case CodeBlockType.varShowFaster:
        return 'show winner';
      case CodeBlockType.varSetWater:
        return 'water = 0';
      case CodeBlockType.varWaterPlant:
        return 'water = water + 1';
      case CodeBlockType.varShowPlant:
        return 'show plant';
      case CodeBlockType.varSetCountdown:
        return 'countdown = 3';
      case CodeBlockType.varMinusOne:
        return 'countdown = countdown - 1';
      case CodeBlockType.varShowCountdown:
        return 'show countdown';
    }
  }
  String challengeTargetDisplay(int number, String fallback) {
    if (!isArabic) return fallback;
    return _ar[number]?['targetDisplay'] ?? fallback;
  }
  String get parentDashboard => isArabic ? 'لوحة الآباء' : 'Parent Dashboard';
  String get parentDashboardSubtitle =>
      isArabic ? 'تتبع تقدم أطفالك' : 'Track your children\'s progress';
  String get totalLessons => isArabic ? 'إجمالي الدروس' : 'Total Lessons';
  String get avgProgress => isArabic ? 'متوسط التقدّم' : 'Avg Progress';
  String get totalStreak => isArabic ? 'إجمالي السلسلة' : 'Total Streak';
  String yourChildren(int count) =>
      isArabic ? 'أطفالك ($count)' : 'Your Children ($count)';
  String get addChild => isArabic ? 'أضف طفلاً' : 'Add Child';
  String get addNewChild => isArabic ? 'أضف طفلاً جديداً' : 'Add New Child';
  String get childName => isArabic ? 'اسم الطفل' : 'Child Name';
  String get ageLabel => isArabic ? 'العمر' : 'Age';
  String get genderLabel => isArabic ? 'الجنس' : 'Gender';
  String get girl => isArabic ? 'بنت' : 'Girl';
  String get boy => isArabic ? 'ولد' : 'Boy';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get remove => isArabic ? 'إزالة' : 'Remove';
  String editChildTitle(String name) =>
      isArabic ? 'تعديل $name' : 'Edit $name';
  String removeChildTitle(String name) =>
      isArabic ? 'إزالة $name؟' : 'Remove $name?';
  String get removeChildBody => isArabic
      ? 'هذا سوف يحذف كل تقدم هذا الطفل.'
      : 'This will delete all progress for this child.';
  String get recentSessions => isArabic ? 'الجلسات الأخيرة' : 'Recent Sessions';
  String get noSessionsYet => isArabic ? 'لا توجد جلسات بعد.' : 'No sessions yet.';
  String get noChildrenAddedYet =>
      isArabic ? 'لم تتم إضافة أطفال بعد' : 'No children added yet';
  String get tapAddChildHint => isArabic
      ? 'اضغط "أضف طفلاً" لإنشاء ملف'
      : 'Tap "Add Child" to create a profile';
  String get passed => isArabic ? 'ناجح' : 'Passed';
  String get failed => isArabic ? 'فشل' : 'Failed';
  String get joined => isArabic ? 'انضم في' : 'Joined';

  String levelTitle(int n) {
    if (!isArabic) {
      return switch (n) {
        1 => 'Move Your Robot',
        2 => 'Play with Colors',
        3 => 'Make Some Noise',
        4 => 'Magic Screen',
        _ => 'Level $n',
      };
    }
    return switch (n) {
      1 => 'حرّك روبوتك',
      2 => 'العب بالألوان',
      3 => 'أصدر بعض الأصوات',
      4 => 'الشاشة السحرية',
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
  String get currentEmoji => isArabic ? 'الرمز الحالي' : 'Current Emoji';

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
  String get robotDisconnectedTitle =>
      isArabic ? 'انقطع الاتصال بالروبوت!' : 'Robot disconnected!';
  String get robotDisconnectedSub =>
      isArabic ? 'تحقق من أن الروبوت مشغّل.' : 'Check if the robot is powered on.';

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
      ? 'أدخل بريدك الإلكتروني المسجَّل وسنرسل لك رابط إعادة تعيين كلمة المرور.'
      : 'Enter your registered email address and we will send you a password reset link.';
  String get yourEmail => isArabic ? 'بريدك الإلكتروني' : 'Your email';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get enterPasswordToContinue =>
      isArabic ? 'أدخل كلمة المرور للمتابعة' : 'Enter your password to continue';
  String get sendLink => isArabic ? 'إرسال الرابط' : 'Send Link';
  String get resetEmailSent => isArabic
      ? 'إذا كان البريد مسجَّلاً، تم إرسال رابط الإعادة. تحقق من البريد الوارد ومجلد الرسائل غير المرغوب فيها.'
      : 'If this email is registered, a reset link has been sent. Check your inbox and spam/junk folder.';
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

  // ── Email verification screen ─────────────────────────────
  String get emailVerificationTitle => isArabic ? 'تحقق من بريدك الإلكتروني' : 'Verify Your Email';
  String get emailVerificationBody => isArabic ? 'أرسلنا رابط التحقق إلى:' : 'We sent a verification link to:';
  String get emailVerificationInstruction => isArabic
      ? 'تحقق من بريدك الوارد ومجلد الرسائل غير المرغوب فيها، ثم انقر على الرابط لتفعيل حسابك.'
      : 'Check your inbox and spam/junk folder, then click the link to activate your account.';
  String get iHaveVerified => isArabic ? 'لقد تحققت من بريدي' : "I've Verified My Email";
  String get resendEmail => isArabic ? 'إعادة إرسال البريد' : 'Resend Email';
  String resendIn(int n) => isArabic ? 'إعادة الإرسال بعد $nث' : 'Resend in ${n}s';
  String get emailNotVerifiedYet => isArabic
      ? 'البريد لم يُتحقق منه بعد. تحقق من بريدك الوارد وانقر على الرابط.'
      : 'Email not verified yet. Please check your inbox and click the link.';
  String get emailVerificationResent => isArabic
      ? 'تم إعادة إرسال بريد التحقق. تحقق من بريدك الوارد.'
      : 'Verification email resent. Check your inbox and spam folder.';
  String get backToLogin => isArabic ? 'العودة إلى تسجيل الدخول' : 'Back to Login';
  String get emailVerificationRequired => isArabic
      ? 'يرجى تفعيل بريدك الإلكتروني. تحقق من بريدك الوارد للحصول على رابط التحقق.'
      : 'Please verify your email. Check your inbox for a verification link.';

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
          'Last updated: May 2026\n\n'
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
  String get tapToGoBack => isArabic ? 'اضغط للعودة' : 'Tap to go back';
  String get tapToContinue => isArabic ? 'اضغط للمتابعة' : 'Tap to continue';
  String get tapAnywhereToAdvance =>
      isArabic ? 'اضغط في أي مكان للاستمرار' : 'Tap anywhere to continue';
  String get backHint => isArabic ? 'عودة' : 'Back';

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
      'instruction': 'حاول تحريك روبوتك خطوة واحدة إلى الأمام ⬆️',
    },
    2: {
      'title': 'تحرك للخلف',
      'instruction': 'حاول تحريك روبوتك خطوة واحدة إلى الخلف ⬇️',
    },
    3: {
      'title': 'تحرك لليمين',
      'instruction': 'حرّك روبوتك إلى اليمين',
    },
    4: {
      'title': 'تحرك لليمين - متعدد',
      'instruction': 'حرّك روبوتك خطوتين إلى اليمين',
    },
    5: {
      'title': 'تحرك لليسار',
      'instruction': 'حرّك روبوتك إلى اليسار',
    },
    // Level 2 – Sound logic
    7: {
      'title': 'موسيقى سعيدة',
      'instruction': 'ساعد الروبوت على الرد عندما يظهر رمز السعادة.',
    },
    8: {
      'title': 'ردّ فعل حزين',
      'instruction': 'ساعد الروبوت يعمل ردة فعل لما يكون حزيناً، وإذا لم يكن حزيناً، خليه مبتسماً',
    },
    9: {
      'title': 'السلاسل',
      'instruction': 'ساعد الروبوت على مكافأتك بناءً على سلسلتك.',
      'targetDisplay': '🔥 سلسلة 5+  →  احتفل! 🎉\n📈 سلسلة 2+  →  صفّق! 👏\n💪 خلاف ذلك  →  استمر!',
    },
    10: {
      'title': 'النهار والليل',
      'instruction': 'ساعد الروبوت على الرد بناءً على وقت اليوم.',
      'targetDisplay': '🌙  →  🌃 ليل\n☀️  →  🌅 صباح',
    },
    11: {
      'title': 'خمّن الحيوان',
      'instruction': 'ساعد الروبوت على تخمين الحيوان الذي يظهر.',
      'targetDisplay': 'كبير + أنف طويل  →  🐘 فيل\nكبير، لا أنف  →  🦁 أسد\nصغير + فرو كثيف  →  🐱 قط\nصغير، غير فروي  →  🐶 كلب',
    },
    // Level 3 – LED
    12: {
      'title': 'أضئ الضوء',
      'instruction': 'شغّل ضوء الروبوت بالأحمر، انتظر قليلاً، ثم أطفئه!',
    },
    13: {
      'title': 'وميض ثلاث مرات',
      'instruction': 'اجعل الضوء الأحمر يومض 3 مرات باستخدام حلقة!',
    },
    14: {
      'title': 'هجوم وانتصار',
      'instruction': 'الأعداء يهاجمون! أومض الأحمر 🔴 ثلاث مرات للدفاع، ثم احتفل بوميضتَي أخضر 🟢!',
    },
    16: {
      'title': 'أوقف السيارات',
      'instruction': 'ساعد المشاة على العبور!\nأخضر للانطلاق، أصفر تحذيراً، أحمر 3 مرات لإيقاف السيارات، أصفر مجدداً، ثم أخضر!',
    },
    17: {
      'title': 'أضواء الشرطة',
      'instruction': 'اصنع أضواء شرطة!\nكرّر 3 مرات:\n  • أومض الأحمر 🔴 مرتين\n  • أومض الأزرق 🔵 مرتين',
    },
    // Level 4 – Variables
    18: {
      'title': 'أول متغير',
      'instruction': 'اضبط الدرجة على 10، ثم اعرضها على شاشة الروبوت! 📊',
    },
    19: {
      'title': 'أضف نقاطاً',
      'instruction': 'ابدأ الدرجة من 0، أضف 5 نقاط، ثم اعرض النتيجة! ➕',
    },
    20: {
      'title': 'ري النبتة',
      'instruction': 'اسقِ النبتة! اضبط الماء على 0، ثم استخدم كرّر 3× — بداخل الحلقة: اسقِها واعرض النبتة في كل مرة. شاهدها تنمو! 🌻',
    },
    21: {
      'title': 'فحص الحرارة',
      'instruction': 'اضبط درجة الحرارة، تحقق هل هي حارة، واعرض الرمز المناسب! 🌡️',
    },
    22: {
      'title': 'العد التنازلي',
      'instruction': 'أطلق الصاروخ! 🚀\nاضبط العد على 3 واعرضه، ثم استخدم كرّر 3× لطرح 1 وعرض النتيجة في كل مرة.\nيجب أن تظهر الشاشة: 3 ← 2 ← 1 ← 0',
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
