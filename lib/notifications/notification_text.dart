// Notification titles, channel names, and settings copy.
//
// Quote bodies are never stored here. Languages other than English are
// machine translations and are marked needs_review, same standard as
// the widget gallery. Missing keys fall back to English.

import '../l10n/widget_gallery.dart';

String notifyUi(String lang, String key) {
  final table = _ui[key];
  if (table == null) return key;
  return table[lang] ?? table['en'] ?? key;
}

List<String> morningTitleVariants(String lang) {
  return _morning[lang] ?? _morning['en']!;
}

List<String> eveningTitleVariants(String lang) {
  return _evening[lang] ?? _evening['en']!;
}

String morningTitle(String lang, int variant) {
  final list = morningTitleVariants(lang);
  return list[variant % list.length];
}

String eveningTitle(String lang, int variant) {
  final list = eveningTitleVariants(lang);
  return list[variant % list.length];
}

String notificationBody(String quote, String author) => '$quote\n— $author';

String streakTitle(String lang, int count, int variant) {
  final forms = _streak[lang] ?? _streak['en']!;
  final index = variant % forms.length;
  return _applyPlural(forms[index], lang, count);
}

String _applyPlural(_StreakForm form, String lang, int count) {
  final template = form.pick(lang, count);
  return template.replaceAll('{count}', '$count');
}

class _StreakForm {
  const _StreakForm(this.one, this.other, {this.few, this.many, this.two});

  final String one;
  final String other;
  final String? few;
  final String? many;
  final String? two;

  String pick(String lang, int count) {
    if (lang == 'ru') {
      final mod100 = count % 100;
      final mod10 = count % 10;
      if (mod10 == 1 && mod100 != 11) return one;
      if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
        return few ?? other;
      }
      return many ?? other;
    }
    if (lang == 'ar') {
      if (count == 0) return many ?? other;
      if (count == 1) return one;
      if (count == 2) return two ?? other;
      if (count % 100 >= 3 && count % 100 <= 10) return few ?? other;
      if (count % 100 >= 11) return many ?? other;
      return other;
    }
    if (count == 1) return one;
    return other;
  }
}

const _morning = <String, List<String>>{
  'en': [
    'Your morning quote',
    'Start the day with this',
    'Something to carry into today',
    'Fresh words for a fresh day',
    'Before the day gets busy',
    'A good thought to start on',
    'Make today count',
    'Rise and read',
  ],
  'es': [
    'Tu cita de la mañana',
    'Empieza el día con esto',
    'Algo para llevar hoy',
    'Palabras nuevas para un día nuevo',
    'Antes de que el día apriete',
    'Un buen pensamiento al empezar',
    'Haz que hoy cuente',
    'Levántate y lee',
  ],
  'fr': [
    'Votre citation du matin',
    'Commencez la journée avec ceci',
    'Quelque chose à emporter aujourd’hui',
    'Des mots neufs pour un jour neuf',
    'Avant que la journée s’emballe',
    'Une pensée pour commencer',
    'Faites compter ce jour',
    'Levez-vous et lisez',
  ],
  'pt': [
    'A tua citação da manhã',
    'Começa o dia com isto',
    'Algo para levar hoje',
    'Palavras novas para um dia novo',
    'Antes de o dia ficar cheio',
    'Um bom pensamento para começar',
    'Faz de hoje contar',
    'Levanta-te e lê',
  ],
  'de': [
    'Dein Morgenzitat',
    'Starte den Tag damit',
    'Etwas für den heutigen Tag',
    'Frische Worte für einen frischen Tag',
    'Bevor der Tag voll wird',
    'Ein guter Gedanke zum Start',
    'Mach den Tag bedeutsam',
    'Aufstehen und lesen',
  ],
  'it': [
    'La tua citazione del mattino',
    'Inizia la giornata con questo',
    'Qualcosa da portare oggi',
    'Parole nuove per un giorno nuovo',
    'Prima che la giornata si riempia',
    'Un pensiero per cominciare',
    'Fai valere oggi',
    'Alzati e leggi',
  ],
  'ru': [
    'Утренняя цитата',
    'Начните день с этого',
    'С собой на сегодняшний день',
    'Свежие слова на новый день',
    'Пока день не стал шумным',
    'Мысль, с которой начать',
    'Пусть сегодня имеет вес',
    'Встань и прочитай',
  ],
  'ar': [
    'اقتباسك الصباحي',
    'ابدأ اليوم بهذا',
    'شيء تحمله معك اليوم',
    'كلمات جديدة ليوم جديد',
    'قبل أن يزدحم اليوم',
    'فكرة طيبة للبداية',
    'اجعل اليوم ذا معنى',
    'انهض واقرأ',
  ],
  'fa': [
    'نقل‌قول صبحگاهی تو',
    'روز را با این شروع کن',
    'چیزی برای بردن به امروز',
    'کلمه‌های تازه برای روز تازه',
    'پیش از شلوغ شدن روز',
    'فکری خوب برای شروع',
    'امروز را مهم کن',
    'برخیز و بخوان',
  ],
  'tr': [
    'Sabah alıntın',
    'Güne bununla başla',
    'Bugüne götüreceğin bir söz',
    'Yeni bir gün için taze sözler',
    'Gün dolmadan önce',
    'Başlamak için iyi bir düşünce',
    'Bugünü değerli kıl',
    'Kalk ve oku',
  ],
  'hi': [
    'आपकी सुबह की पंक्ति',
    'दिन की शुरुआत इससे करें',
    'आज साथ ले जाने योग्य',
    'नए दिन के लिए नई बात',
    'दिन व्यस्त होने से पहले',
    'शुरू करने का अच्छा विचार',
    'आज को मायने दो',
    'उठो और पढ़ो',
  ],
  'id': [
    'Kutipan pagimu',
    'Mulai hari dengan ini',
    'Sesuatu untuk dibawa hari ini',
    'Kata baru untuk hari baru',
    'Sebelum hari menjadi ramai',
    'Pikiran baik untuk memulai',
    'Buat hari ini berarti',
    'Bangun dan baca',
  ],
  'zh': [
    '你的晨间一句',
    '用这句话开始今天',
    '带进今天的一行',
    '新的一天，新的句子',
    '在忙碌开始之前',
    '一个适合开始的念头',
    '让今天有分量',
    '起来读一句',
  ],
  'ja': [
    '朝の一文',
    'これで一日を始める',
    '今日に持っていく言葉',
    '新しい日のための新しい言葉',
    '忙しくなる前に',
    '始めるためのよい考え',
    '今日を大切に',
    '起きて読む',
  ],
  'ko': [
    '아침의 문장',
    '이것으로 하루를 시작하세요',
    '오늘 가지고 갈 한 줄',
    '새날을 위한 새 말',
    '하루가 바빠지기 전에',
    '시작하기 좋은 생각',
    '오늘을 의미 있게',
    '일어나서 읽기',
  ],
  'sw': [
    'Nukuu yako ya asubuhi',
    'Anza siku na hii',
    'Kitu cha kubeba leo',
    'Maneno mapya kwa siku mpya',
    'Kabla siku haijajaa',
    'Wazo jema la kuanza',
    'Fanya leo iwe na maana',
    'Amka na soma',
  ],
  'af': [
    'Jou oggendaanhaling',
    'Begin die dag hiermee',
    'Iets om vandag saam te dra',
    'Vars woorde vir ’n vars dag',
    'Voor die dag vol raak',
    '’n Goeie gedagte om mee te begin',
    'Maak vandag tel',
    'Staan op en lees',
  ],
  'zu': [
    'Isisho sakho sasekuseni',
    'Qala usuku ngalokhu',
    'Into ozoyiphatha namuhla',
    'Amazwi amasha osuku olusha',
    'Ngaphambi kokuba usuku lugcwale',
    'Umcabango omuhle wokuqala',
    'Yenza namuhla kube nentengo',
    'Vuka ufunde',
  ],
};

const _evening = <String, List<String>>{
  'en': [
    'Tonight’s reflection',
    'Before you wind down',
    'One thought for the evening',
    'Take a quiet minute',
    'End the day on this',
    'Something to sleep on',
    'A pause before tomorrow',
    'How the day looks from here',
  ],
  'es': [
    'La reflexión de esta noche',
    'Antes de ir cerrando el día',
    'Un pensamiento para la tarde',
    'Tómate un minuto en calma',
    'Cierra el día con esto',
    'Algo para dormir encima',
    'Una pausa antes de mañana',
    'Cómo se ve el día desde aquí',
  ],
  'fr': [
    'La réflexion de ce soir',
    'Avant de ralentir',
    'Une pensée pour le soir',
    'Prenez une minute calme',
    'Terminez la journée sur ceci',
    'Quelque chose à méditer la nuit',
    'Une pause avant demain',
    'Le jour vu d’ici',
  ],
  'pt': [
    'A reflexão desta noite',
    'Antes de abrandar',
    'Um pensamento para a noite',
    'Tira um minuto calmo',
    'Termina o dia com isto',
    'Algo para dormir sobre',
    'Uma pausa antes de amanhã',
    'Como o dia se vê daqui',
  ],
  'de': [
    'Die Überlegung für heute Abend',
    'Bevor du zur Ruhe kommst',
    'Ein Gedanke für den Abend',
    'Nimm dir eine stille Minute',
    'Beende den Tag damit',
    'Etwas zum Darüber-Schlafen',
    'Eine Pause vor morgen',
    'Wie der Tag von hier aussieht',
  ],
  'it': [
    'La riflessione di stasera',
    'Prima di rallentare',
    'Un pensiero per la sera',
    'Prenditi un minuto quieto',
    'Chiudi la giornata con questo',
    'Qualcosa su cui dormire',
    'Una pausa prima di domani',
    'Come si vede il giorno da qui',
  ],
  'ru': [
    'Вечернее размышление',
    'Перед тем как замедлиться',
    'Одна мысль на вечер',
    'Возьмите тихую минуту',
    'Завершите день этим',
    'На ночь подумать',
    'Пауза перед завтра',
    'Как день выглядит отсюда',
  ],
  'ar': [
    'تأمل هذه الليلة',
    'قبل أن تهدأ',
    'فكرة واحدة للمساء',
    'خذ دقيقة هادئة',
    'اختتم اليوم بهذا',
    'شيء تنام عليه',
    'وقفة قبل الغد',
    'كيف يبدو اليوم من هنا',
  ],
  'fa': [
    'تأمل امشب',
    'پیش از آرام شدن',
    'یک فکر برای شب',
    'یک دقیقه آرام بگیر',
    'روز را با این تمام کن',
    'چیزی برای خوابیدن روی آن',
    'وقفه پیش از فردا',
    'روز از اینجا چطور دیده می‌شود',
  ],
  'tr': [
    'Bu gecenin düşüncesi',
    'Yavaşlamadan önce',
    'Akşam için bir düşünce',
    'Sakin bir dakika ayır',
    'Günü bununla bitir',
    'Üzerine uyuyacak bir şey',
    'Yarından önce bir durak',
    'Gün buradan nasıl görünüyor',
  ],
  'hi': [
    'आज रात का विचार',
    'धीरे होने से पहले',
    'शाम के लिए एक विचार',
    'एक शांत मिनट लो',
    'दिन यहीं खत्म करो',
    'सोचकर सोने लायक',
    'कल से पहले एक ठहराव',
    'यहाँ से दिन कैसा दिखता है',
  ],
  'id': [
    'Renungan malam ini',
    'Sebelum kamu mereda',
    'Satu pikiran untuk malam',
    'Ambil satu menit yang tenang',
    'Akhiri hari dengan ini',
    'Sesuatu untuk ditiduri',
    'Jeda sebelum besok',
    'Bagaimana hari terlihat dari sini',
  ],
  'zh': [
    '今夜的一句',
    '在放慢之前',
    '给晚上的一个念头',
    '安静一分钟',
    '用这句话结束今天',
    '夜里可以想想的一行',
    '明天之前停一下',
    '从这里看这一天',
  ],
  'ja': [
    '今夜の一文',
    'ゆるむ前に',
    '夕方のための一つの考え',
    '静かな一分を',
    'これで一日を閉じる',
    '枕元に置く言葉',
    '明日の前のひと休み',
    'ここから見た今日',
  ],
  'ko': [
    '오늘 밤의 한 줄',
    '느려지기 전에',
    '저녁을 위한 한 생각',
    '고요한 1분을',
    '이것으로 하루를 닫기',
    '잠들기 전 한 줄',
    '내일 전의 멈춤',
    '여기서 본 오늘',
  ],
  'sw': [
    'Tafakari ya usiku huu',
    'Kabla hujatulia',
    'Wazo moja la jioni',
    'Chukua dakika tulivu',
    'Maliza siku kwa hii',
    'Kitu cha kulala nacho',
    'Pumziko kabla ya kesho',
    'Siku inavyoonekana kutoka hapa',
  ],
  'af': [
    'Vanaand se nadenke',
    'Voor jy afskaal',
    'Een gedagte vir die aand',
    'Neem ’n stil minuut',
    'Eindig die dag hiermee',
    'Iets om op te slaap',
    '’n Pouse voor môre',
    'Hoe die dag van hier af lyk',
  ],
  'zu': [
    'Ukucabanga kwalobubusuku',
    'Ngaphambi kokuba uthobe',
    'Umcabango owodwa wakusihlwa',
    'Thatha umzuzu othule',
    'Qeda usuku ngalokhu',
    'Into yokulala uyicabanga',
    'Ikhala ngaphambi kwakusasa',
    'Usuku lubonakala kanjani lapha',
  ],
};

const _streak = <String, List<_StreakForm>>{
  'en': [
    _StreakForm(
      'Keep your {count}-day streak going',
      'Keep your {count}-day streak going',
    ),
    _StreakForm(
      '{count} day in a row. Don’t stop now',
      '{count} days in a row. Don’t stop now',
    ),
    _StreakForm(
      'Your {count}-day streak is waiting',
      'Your {count}-day streak is waiting',
    ),
  ],
  'es': [
    _StreakForm(
      'Sigue tu racha de {count} día',
      'Sigue tu racha de {count} días',
    ),
    _StreakForm(
      '{count} día seguido. No pares ahora',
      '{count} días seguidos. No pares ahora',
    ),
    _StreakForm(
      'Tu racha de {count} día te espera',
      'Tu racha de {count} días te espera',
    ),
  ],
  'fr': [
    _StreakForm(
      'Gardez votre série de {count} jour',
      'Gardez votre série de {count} jours',
    ),
    _StreakForm(
      '{count} jour d’affilée. Ne vous arrêtez pas',
      '{count} jours d’affilée. Ne vous arrêtez pas',
    ),
    _StreakForm(
      'Votre série de {count} jour vous attend',
      'Votre série de {count} jours vous attend',
    ),
  ],
  'pt': [
    _StreakForm(
      'Mantém a tua série de {count} dia',
      'Mantém a tua série de {count} dias',
    ),
    _StreakForm(
      '{count} dia seguido. Não pares agora',
      '{count} dias seguidos. Não pares agora',
    ),
    _StreakForm(
      'A tua série de {count} dia espera',
      'A tua série de {count} dias espera',
    ),
  ],
  'de': [
    _StreakForm(
      'Halt deine Serie von {count} Tag',
      'Halt deine Serie von {count} Tagen',
    ),
    _StreakForm(
      '{count} Tag in Folge. Nicht jetzt aufhören',
      '{count} Tage in Folge. Nicht jetzt aufhören',
    ),
    _StreakForm(
      'Deine Serie von {count} Tag wartet',
      'Deine Serie von {count} Tagen wartet',
    ),
  ],
  'it': [
    _StreakForm(
      'Tieni la serie di {count} giorno',
      'Tieni la serie di {count} giorni',
    ),
    _StreakForm(
      '{count} giorno di fila. Non fermarti ora',
      '{count} giorni di fila. Non fermarti ora',
    ),
    _StreakForm(
      'La tua serie di {count} giorno ti aspetta',
      'La tua serie di {count} giorni ti aspetta',
    ),
  ],
  'ru': [
    _StreakForm(
      'Продолжайте серию из {count} дня',
      'Продолжайте серию из {count} дней',
      few: 'Продолжайте серию из {count} дней',
      many: 'Продолжайте серию из {count} дней',
    ),
    _StreakForm(
      '{count} день подряд. Не останавливайтесь',
      '{count} дней подряд. Не останавливайтесь',
      few: '{count} дня подряд. Не останавливайтесь',
      many: '{count} дней подряд. Не останавливайтесь',
    ),
    _StreakForm(
      'Ваша серия из {count} дня ждёт',
      'Ваша серия из {count} дней ждёт',
      few: 'Ваша серия из {count} дней ждёт',
      many: 'Ваша серия из {count} дней ждёт',
    ),
  ],
  'ar': [
    _StreakForm(
      'حافظ على سلسلتك ليوم {count}',
      'حافظ على سلسلتك لـ {count} أيام',
      two: 'حافظ على سلسلتك ليومين',
      few: 'حافظ على سلسلتك لـ {count} أيام',
      many: 'حافظ على سلسلتك لـ {count} يومًا',
    ),
    _StreakForm(
      'يوم {count} على التوالي. لا تتوقف الآن',
      '{count} أيام على التوالي. لا تتوقف الآن',
      two: 'يومان على التوالي. لا تتوقف الآن',
      few: '{count} أيام على التوالي. لا تتوقف الآن',
      many: '{count} يومًا على التوالي. لا تتوقف الآن',
    ),
    _StreakForm(
      'سلسلتك ليوم {count} بانتظارك',
      'سلسلتك لـ {count} أيام بانتظارك',
      two: 'سلسلتك ليومين بانتظارك',
      few: 'سلسلتك لـ {count} أيام بانتظارك',
      many: 'سلسلتك لـ {count} يومًا بانتظارك',
    ),
  ],
  'fa': [
    _StreakForm(
      'رشتهٔ {count} روزه‌ات را نگه دار',
      'رشتهٔ {count} روزه‌ات را نگه دار',
    ),
    _StreakForm(
      '{count} روز پیاپی. حالا نایست',
      '{count} روز پیاپی. حالا نایست',
    ),
    _StreakForm(
      'رشتهٔ {count} روزه‌ات منتظر است',
      'رشتهٔ {count} روزه‌ات منتظر است',
    ),
  ],
};

const _ui = <String, Map<String, String>>{
  'notifications': {
    'en': 'Notifications',
    'es': 'Notificaciones',
    'fr': 'Notifications',
    'pt': 'Notificações',
    'de': 'Mitteilungen',
    'it': 'Notifiche',
    'ru': 'Уведомления',
    'ar': 'الإشعارات',
    'fa': 'اعلان‌ها',
    'tr': 'Bildirimler',
    'hi': 'सूचनाएँ',
    'id': 'Notifikasi',
    'zh': '通知',
    'ja': '通知',
    'ko': '알림',
    'sw': 'Arifa',
    'af': 'Kennisgewings',
    'zu': 'Izaziso',
  },
  'notificationsOff': {
    'en': 'Notifications are off',
    'es': 'Las notificaciones están desactivadas',
    'fr': 'Les notifications sont désactivées',
    'pt': 'As notificações estão desligadas',
    'de': 'Mitteilungen sind aus',
    'it': 'Le notifiche sono disattivate',
    'ru': 'Уведомления выключены',
    'ar': 'الإشعارات متوقفة',
    'fa': 'اعلان‌ها خاموش‌اند',
    'tr': 'Bildirimler kapalı',
    'hi': 'सूचनाएँ बंद हैं',
    'id': 'Notifikasi mati',
    'zh': '通知已关闭',
    'ja': '通知はオフです',
    'ko': '알림이 꺼져 있습니다',
    'sw': 'Arifa zimezimwa',
    'af': 'Kennisgewings is af',
    'zu': 'Izaziso zicishiwe',
  },
  'notificationsOn': {
    'en': 'Notifications are on',
    'es': 'Las notificaciones están activadas',
    'fr': 'Les notifications sont activées',
    'pt': 'As notificações estão ligadas',
    'de': 'Mitteilungen sind an',
    'it': 'Le notifiche sono attive',
    'ru': 'Уведомления включены',
    'ar': 'الإشعارات قيد التشغيل',
    'fa': 'اعلان‌ها روشن‌اند',
    'tr': 'Bildirimler açık',
    'hi': 'सूचनाएँ चालू हैं',
    'id': 'Notifikasi nyala',
    'zh': '通知已开启',
    'ja': '通知はオンです',
    'ko': '알림이 켜져 있습니다',
    'sw': 'Arifa zimewashwa',
    'af': 'Kennisgewings is aan',
    'zu': 'Izaziso zivuliwe',
  },
  'openSystemSettings': {
    'en': 'Open system settings',
    'es': 'Abrir ajustes del sistema',
    'fr': 'Ouvrir les réglages système',
    'pt': 'Abrir definições do sistema',
    'de': 'Systemeinstellungen öffnen',
    'it': 'Apri le impostazioni di sistema',
    'ru': 'Открыть системные настройки',
    'ar': 'افتح إعدادات النظام',
    'fa': 'باز کردن تنظیمات سیستم',
    'tr': 'Sistem ayarlarını aç',
    'hi': 'सिस्टम सेटिंग खोलें',
    'id': 'Buka pengaturan sistem',
    'zh': '打开系统设置',
    'ja': 'システム設定を開く',
    'ko': '시스템 설정 열기',
    'sw': 'Fungua mipangilio ya mfumo',
    'af': 'Maak stelselinstellings oop',
    'zu': 'Vula izilungiselelo zohlelo',
  },
  'morning': {
    'en': 'Morning',
    'es': 'Mañana',
    'fr': 'Matin',
    'pt': 'Manhã',
    'de': 'Morgen',
    'it': 'Mattina',
    'ru': 'Утро',
    'ar': 'الصباح',
    'fa': 'صبح',
    'tr': 'Sabah',
    'hi': 'सुबह',
    'id': 'Pagi',
    'zh': '早晨',
    'ja': '朝',
    'ko': '아침',
    'sw': 'Asubuhi',
    'af': 'Oggend',
    'zu': 'Ekuseni',
  },
  'evening': {
    'en': 'Evening',
    'es': 'Noche',
    'fr': 'Soir',
    'pt': 'Noite',
    'de': 'Abend',
    'it': 'Sera',
    'ru': 'Вечер',
    'ar': 'المساء',
    'fa': 'عصر',
    'tr': 'Akşam',
    'hi': 'शाम',
    'id': 'Malam',
    'zh': '晚上',
    'ja': '夜',
    'ko': '저녁',
    'sw': 'Jioni',
    'af': 'Aand',
    'zu': 'Kusihlwa',
  },
  'whatToSend': {
    'en': 'What to send',
    'es': 'Qué enviar',
    'fr': 'Quoi envoyer',
    'pt': 'O que enviar',
    'de': 'Was gesendet wird',
    'it': 'Cosa inviare',
    'ru': 'Что присылать',
    'ar': 'ماذا نرسل',
    'fa': 'چه بفرستیم',
    'tr': 'Ne gönderilecek',
    'hi': 'क्या भेजें',
    'id': 'Apa yang dikirim',
    'zh': '发送什么',
    'ja': '何を送るか',
    'ko': '무엇을 보낼지',
    'sw': 'Nini cha kutuma',
    'af': 'Wat om te stuur',
    'zu': 'Okuzothunyelwa',
  },
  'followedFields': {
    'en': 'Followed fields',
    'es': 'Campos que sigues',
    'fr': 'Domaines suivis',
    'pt': 'Campos seguidos',
    'de': 'Gefolgte Felder',
    'it': 'Campi seguiti',
    'ru': 'Отслеживаемые области',
    'ar': 'المجالات المتابعة',
    'fa': 'زمینه‌های دنبال‌شده',
    'tr': 'Takip edilen alanlar',
    'hi': 'अनुसरण किए क्षेत्र',
    'id': 'Bidang yang diikuti',
    'zh': '已关注的领域',
    'ja': 'フォロー中の分野',
    'ko': '팔로우한 분야',
    'sw': 'Nyanja zinazofuatwa',
    'af': 'Gevolgde velde',
    'zu': 'Izinkambu ezilandelwayo',
  },
  'everything': {
    'en': 'Everything',
    'es': 'Todo',
    'fr': 'Tout',
    'pt': 'Tudo',
    'de': 'Alles',
    'it': 'Tutto',
    'ru': 'Всё',
    'ar': 'الكل',
    'fa': 'همه',
    'tr': 'Hepsi',
    'hi': 'सब कुछ',
    'id': 'Semuanya',
    'zh': '全部',
    'ja': 'すべて',
    'ko': '모두',
    'sw': 'Kila kitu',
    'af': 'Alles',
    'zu': 'Konke',
  },
  'aMood': {
    'en': 'A mood',
    'es': 'Un ánimo',
    'fr': 'Une humeur',
    'pt': 'Um humor',
    'de': 'Eine Stimmung',
    'it': 'Un umore',
    'ru': 'Настроение',
    'ar': 'مزاج',
    'fa': 'یک حال',
    'tr': 'Bir ruh hali',
    'hi': 'एक मूड',
    'id': 'Suasana hati',
    'zh': '一种心情',
    'ja': '気分',
    'ko': '기분',
    'sw': 'Hali ya moyo',
    'af': '’n Stemming',
    'zu': 'Isimo sengqondo',
  },
  'pauseWeek': {
    'en': 'Pause for a week',
    'es': 'Pausar una semana',
    'fr': 'Pause d’une semaine',
    'pt': 'Pausar uma semana',
    'de': 'Eine Woche pausieren',
    'it': 'Pausa di una settimana',
    'ru': 'Пауза на неделю',
    'ar': 'إيقاف لأسبوع',
    'fa': 'توقف برای یک هفته',
    'tr': 'Bir hafta duraklat',
    'hi': 'एक सप्ताह रोकें',
    'id': 'Jeda seminggu',
    'zh': '暂停一周',
    'ja': '1週間休む',
    'ko': '일주일 멈추기',
    'sw': 'Simamisha kwa wiki',
    'af': 'Pouse vir ’n week',
    'zu': 'Misa isonto',
  },
  'resume': {
    'en': 'Resume',
    'es': 'Reanudar',
    'fr': 'Reprendre',
    'pt': 'Retomar',
    'de': 'Fortsetzen',
    'it': 'Riprendi',
    'ru': 'Возобновить',
    'ar': 'استئناف',
    'fa': 'ادامه',
    'tr': 'Sürdür',
    'hi': 'फिर शुरू करें',
    'id': 'Lanjutkan',
    'zh': '继续',
    'ja': '再開',
    'ko': '다시 시작',
    'sw': 'Endelea',
    'af': 'Hervat',
    'zu': 'Qhubeka',
  },
  'capNote': {
    'en':
        'We send at most 2 a day. If you stop opening MotiScroll, we stop sending.',
    'es':
        'Enviamos como máximo 2 al día. Si dejas de abrir MotiScroll, dejamos de enviar.',
    'fr':
        'Nous envoyons au plus 2 par jour. Si vous n’ouvrez plus MotiScroll, nous arrêtons.',
    'pt':
        'Enviamos no máximo 2 por dia. Se deixares de abrir o MotiScroll, paramos.',
    'de':
        'Wir senden höchstens 2 am Tag. Wenn du MotiScroll nicht mehr öffnest, hören wir auf.',
    'it':
        'Ne inviamo al massimo 2 al giorno. Se smetti di aprire MotiScroll, smettiamo di inviare.',
    'ru':
        'Не больше двух в день. Если вы перестанете открывать MotiScroll, мы перестанем присылать.',
    'ar':
        'نرسل اثنتين في اليوم كحد أقصى. إذا توقفت عن فتح MotiScroll، نتوقف عن الإرسال.',
    'fa':
        'حداکثر دو تا در روز می‌فرستیم. اگر MotiScroll را باز نکنی، ارسال را قطع می‌کنیم.',
    'tr':
        'Günde en fazla 2 göndeririz. MotiScroll’u açmayı bırakırsan göndermeyi durdururuz.',
    'hi':
        'हम एक दिन में अधिकतम 2 भेजते हैं. MotiScroll खोलना बंद करोगे तो भेजना बंद हो जाएगा.',
    'id':
        'Paling banyak 2 sehari. Jika kamu berhenti membuka MotiScroll, kami berhenti mengirim.',
    'zh': '每天最多 2 条。如果你不再打开 MotiScroll，我们就停止发送。',
    'ja': '1日最大2通です。MotiScrollを開かなくなれば、送信を止めます。',
    'ko': '하루에 최대 2개입니다. MotiScroll을 열지 않으면 보내기를 멈춥니다.',
    'sw':
        'Tunatuma zisizozidi 2 kwa siku. Ukiacha kufungua MotiScroll, tunaacha kutuma.',
    'af':
        'Ons stuur hoogstens 2 per dag. As jy ophou om MotiScroll oop te maak, hou ons op stuur.',
    'zu':
        'Sithumela okungeqi kwangu-2 ngosuku. Uma uyeka ukuvula i-MotiScroll, siyayeka ukuthumela.',
  },
  'lockScreenNote': {
    'en': 'Notification text can appear on the lock screen.',
    'es': 'El texto de la notificación puede verse en la pantalla de bloqueo.',
    'fr':
        'Le texte de la notification peut apparaître sur l’écran verrouillé.',
    'pt':
        'O texto da notificação pode aparecer no ecrã bloqueado.',
    'de': 'Der Mitteilungstext kann auf dem Sperrbildschirm erscheinen.',
    'it':
        'Il testo della notifica può comparire sulla schermata di blocco.',
    'ru': 'Текст уведомления может быть виден на экране блокировки.',
    'ar': 'يمكن أن يظهر نص الإشعار على شاشة القفل.',
    'fa': 'متن اعلان ممکن است روی صفحهٔ قفل دیده شود.',
    'tr': 'Bildirim metni kilit ekranında görünebilir.',
    'hi': 'सूचना का पाठ लॉक स्क्रीन पर दिख सकता है.',
    'id': 'Teks notifikasi bisa muncul di layar kunci.',
    'zh': '通知文字可能出现在锁屏上。',
    'ja': '通知の文はロック画面に出ることがあります。',
    'ko': '알림 문구가 잠금 화면에 나타날 수 있습니다.',
    'sw': 'Maandishi ya arifa yanaweza kuonekana kwenye skrini iliyofungwa.',
    'af': 'Kennisgewingteks kan op die sluitskerm verskyn.',
    'zu': 'Umbhalo wesaziso ungavela esikrinini esikhiyiwe.',
  },
  'turnOn': {
    'en': 'Turn on',
    'es': 'Activar',
    'fr': 'Activer',
    'pt': 'Ligar',
    'de': 'Einschalten',
    'it': 'Attiva',
    'ru': 'Включить',
    'ar': 'تشغيل',
    'fa': 'روشن کردن',
    'tr': 'Aç',
    'hi': 'चालू करें',
    'id': 'Nyalakan',
    'zh': '开启',
    'ja': 'オンにする',
    'ko': '켜기',
    'sw': 'Washa',
    'af': 'Skakel aan',
    'zu': 'Vula',
  },
  'notNow': {
    'en': 'Not now',
    'es': 'Ahora no',
    'fr': 'Pas maintenant',
    'pt': 'Agora não',
    'de': 'Nicht jetzt',
    'it': 'Non ora',
    'ru': 'Не сейчас',
    'ar': 'ليس الآن',
    'fa': 'الان نه',
    'tr': 'Şimdi değil',
    'hi': 'अभी नहीं',
    'id': 'Tidak sekarang',
    'zh': '暂不',
    'ja': '今はしない',
    'ko': '지금은 아님',
    'sw': 'Sio sasa',
    'af': 'Nie nou nie',
    'zu': 'Hhayi manje',
  },
  'offerTitle': {
    'en': 'Two quiet reminders',
    'es': 'Dos avisos sosegados',
    'fr': 'Deux rappels calmes',
    'pt': 'Dois avisos calmos',
    'de': 'Zwei ruhige Erinnerungen',
    'it': 'Due richiami quieti',
    'ru': 'Два спокойных напоминания',
    'ar': 'تذكيران هادئان',
    'fa': 'دو یادآوری آرام',
    'tr': 'İki sakin anımsatma',
    'hi': 'दो शांत याद दिलाने वाले',
    'id': 'Dua pengingat yang tenang',
    'zh': '两条安静的提醒',
    'ja': '静かなリマインダーが2つ',
    'ko': '조용한 알림 두 개',
    'sw': 'Vikumbusho viwili vya utulivu',
    'af': 'Twee stil herinneringe',
    'zu': 'Izikhumbuzi ezimbili ezithule',
  },
  'offerBody': {
    'en':
        'A quote at {morning} in the morning and one at {evening} in the evening.',
    'es':
        'Una cita a las {morning} por la mañana y otra a las {evening} por la noche.',
    'fr':
        'Une citation à {morning} le matin et une à {evening} le soir.',
    'pt':
        'Uma citação às {morning} de manhã e outra às {evening} à noite.',
    'de':
        'Ein Zitat um {morning} am Morgen und eines um {evening} am Abend.',
    'it':
        'Una citazione alle {morning} al mattino e una alle {evening} di sera.',
    'ru':
        'Цитата в {morning} утром и ещё одна в {evening} вечером.',
    'ar':
        'اقتباس الساعة {morning} صباحًا وآخر الساعة {evening} مساءً.',
    'fa':
        'یک نقل‌قول ساعت {morning} صبح و یکی ساعت {evening} شب.',
    'tr':
        'Sabah {morning} ve akşam {evening} bir alıntı.',
    'hi':
        'सुबह {morning} पर एक पंक्ति और शाम {evening} पर एक पंक्ति.',
    'id':
        'Satu kutipan pukul {morning} pagi dan satu pukul {evening} malam.',
    'zh': '早上 {morning} 一句，晚上 {evening} 一句。',
    'ja': '朝は{morning}、夜は{evening}に一文。',
    'ko': '아침 {morning}에 한 줄, 저녁 {evening}에 한 줄.',
    'sw':
        'Nukuu saa {morning} asubuhi na nyingine saa {evening} jioni.',
    'af':
        '’n Aanhaling om {morning} in die oggend en een om {evening} in die aand.',
    'zu':
        'Isisho nge-{morning} ekuseni kanye nesinye nge-{evening} kusihlwa.',
  },
  'plannedNotifications': {
    'en': 'Planned notifications',
    'es': 'Notificaciones previstas',
    'fr': 'Notifications prévues',
    'pt': 'Notificações planeadas',
    'de': 'Geplante Mitteilungen',
    'it': 'Notifiche pianificate',
    'ru': 'Запланированные уведомления',
    'ar': 'الإشعارات المخططة',
    'fa': 'اعلان‌های برنامه‌ریزی‌شده',
    'tr': 'Planlanan bildirimler',
    'hi': 'नियोजित सूचनाएँ',
    'id': 'Notifikasi terencana',
    'zh': '已计划的通知',
    'ja': '予定された通知',
    'ko': '예정된 알림',
    'sw': 'Arifa zilizopangwa',
    'af': 'Beplande kennisgewings',
    'zu': 'Izaziso ezihleliwe',
  },
  'channelMorning': {
    'en': 'Morning quote',
    'es': 'Cita de la mañana',
    'fr': 'Citation du matin',
    'pt': 'Citação da manhã',
    'de': 'Morgenzitat',
    'it': 'Citazione del mattino',
    'ru': 'Утренняя цитата',
    'ar': 'اقتباس الصباح',
    'fa': 'نقل‌قول صبح',
    'tr': 'Sabah alıntısı',
    'hi': 'सुबह की पंक्ति',
    'id': 'Kutipan pagi',
    'zh': '晨间一句',
    'ja': '朝の一文',
    'ko': '아침 문장',
    'sw': 'Nukuu ya asubuhi',
    'af': 'Oggendaanhaling',
    'zu': 'Isisho sasekuseni',
  },
  'channelMorningDetail': {
    'en': 'An energizing line in the morning.',
    'es': 'Una línea que da ánimo por la mañana.',
    'fr': 'Une ligne qui donne de l’élan le matin.',
    'pt': 'Uma linha que dá ânimo de manhã.',
    'de': 'Eine ermutigende Zeile am Morgen.',
    'it': 'Una riga che dà slancio al mattino.',
    'ru': 'Бодрящая строка утром.',
    'ar': 'سطر يمنح نشاطًا في الصباح.',
    'fa': 'خطی انرژی‌بخش در صبح.',
    'tr': 'Sabah enerji veren bir satır.',
    'hi': 'सुबह ऊर्जा देने वाली पंक्ति.',
    'id': 'Baris yang memberi energi di pagi hari.',
    'zh': '早晨一句提神的话。',
    'ja': '朝の活力になる一文。',
    'ko': '아침에 힘을 주는 한 줄.',
    'sw': 'Mstari unaotia nguvu asubuhi.',
    'af': '’n Bemoedigende reël in die oggend.',
    'zu': 'Umugqa onika amandla ekuseni.',
  },
  'channelEvening': {
    'en': 'Evening reflection',
    'es': 'Reflexión de la noche',
    'fr': 'Réflexion du soir',
    'pt': 'Reflexão da noite',
    'de': 'Abendliche Überlegung',
    'it': 'Riflessione della sera',
    'ru': 'Вечернее размышление',
    'ar': 'تأمل المساء',
    'fa': 'تأمل شب',
    'tr': 'Akşam düşüncesi',
    'hi': 'शाम का विचार',
    'id': 'Renungan malam',
    'zh': '晚间一句',
    'ja': '夜の一文',
    'ko': '저녁의 한 줄',
    'sw': 'Tafakari ya jioni',
    'af': 'Aandnadenke',
    'zu': 'Ukucabanga kwakusihlwa',
  },
  'channelEveningDetail': {
    'en': 'A calmer line in the evening.',
    'es': 'Una línea más serena por la noche.',
    'fr': 'Une ligne plus calme le soir.',
    'pt': 'Uma linha mais calma à noite.',
    'de': 'Eine ruhigere Zeile am Abend.',
    'it': 'Una riga più calma di sera.',
    'ru': 'Более спокойная строка вечером.',
    'ar': 'سطر أهدأ في المساء.',
    'fa': 'خطی آرام‌تر در شب.',
    'tr': 'Akşam daha sakin bir satır.',
    'hi': 'शाम की शांत पंक्ति.',
    'id': 'Baris yang lebih tenang di malam hari.',
    'zh': '晚上一句更安静的话。',
    'ja': '夜の静かな一文。',
    'ko': '저녁의 고요한 한 줄.',
    'sw': 'Mstari tulivu jioni.',
    'af': '’n Stil reël in die aand.',
    'zu': 'Umugqa othule kusihlwa.',
  },
};

bool notificationTitlesCoverLanguages() {
  return widgetLanguageCodes.every(
    (code) =>
        (_morning[code]?.length ?? 0) >= 8 &&
        (_evening[code]?.length ?? 0) >= 8,
  );
}
