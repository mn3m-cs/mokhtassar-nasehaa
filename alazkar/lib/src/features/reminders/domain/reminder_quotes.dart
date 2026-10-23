/// A saying shown under a reminder's title.
///
/// A saying from outside the book carries [source], the line under it that
/// names its speaker and who reported and graded it, and [reference], the
/// saying as [page] prints it, so a test can tell a shown text that was cut
/// or changed from its source.
///
/// A saying from the book shows alone, with no [source]. A verse carries
/// [zikrId], the record whose verses the app shows in the same words; any
/// other saying carries [reference], the book's words on [page].
class ReminderQuote {
  final String text;
  final String? source;
  final String? reference;
  final String page;
  final int? zikrId;

  const ReminderQuote(
    this.text,
    this.source, {
    this.reference,
    required this.page,
    this.zikrId,
  });
}

/// The morning and evening set: what the book says on pages 29 and 30 in
/// favour of these remembrances, in its order. Each verse is its own saying,
/// as the app shows it for its record, with nothing before or after it.
const _morningAndEvening = [
  ReminderQuote(
    '﴿ يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ ٱذۡكُرُواْ ٱللَّهَ ذِكۡرٗا كَثِيرٗا ٤١ وَسَبِّحُوهُ بُكۡرَةٗ وَأَصِيلًا ٤٢ ﴾',
    null,
    page: 'ص29',
    zikrId: 1228,
  ),
  ReminderQuote(
    '﴿ وَٱذۡكُر رَّبَّكَ فِي نَفۡسِكَ تَضَرُّعٗا وَخِيفَةٗ وَدُونَ ٱلۡجَهۡرِ مِنَ ٱلۡقَوۡلِ بِٱلۡغُدُوِّ وَٱلۡأٓصَالِ وَلَا تَكُن مِّنَ ٱلۡغَٰفِلِينَ ٢٠٥ ﴾',
    null,
    page: 'ص29',
    zikrId: 1229,
  ),
  ReminderQuote(
    '﴿ فَسُبۡحَٰنَ ٱللَّهِ حِينَ تُمۡسُونَ وَحِينَ تُصۡبِحُونَ ١٧ ﴾',
    null,
    page: 'ص29',
    zikrId: 1230,
  ),
  ReminderQuote(
    'إنَّ ذكرَ الله عَزَّ وَجَلَّ في الصباحِ والمساء من أشرفِ الوظائف اليومية '
    'الراتبة، وهو أوسع أبواب الأذكار المقيدة روايةً، وأعظمُها أجرًا.',
    null,
    reference: 'إنَّ ذكرَ الله عَزَّ وَجَلَّ في الصباحِ والمساء من أشرفِ '
        'الوظائف اليومية الراتبة، وهو أوسع أبواب الأذكار المقيدة روايةً، '
        'وأعظمُها أجرًا.',
    page: 'ص29',
  ),
  ReminderQuote(
    'ومِن أكثرِ الأذكارِ أجورًا، وأعظمِها جزاءً: الأدعية الثابتة في الصباح '
    'والمساء؛ فإنَّ فيها من النفع والدَّفْع ما هي مشتملة عليه. فعلى مَنْ '
    'أحبَّ السلامةَ مِنَ الآفات في الدنيا، والفوزَ بالخير الآجِل والعاجلِ '
    'أن يُلازِمَها ويفعلَها في كلِّ صباحٍ ومساء، فإنْ عَسُرَ عليه الإتيانُ '
    'بجميعها أتى ببعضٍ منها.',
    null,
    reference: '«ومِن أكثرِ الأذكارِ أجورًا، وأعظمِها جزاءً: الأدعية الثابتة '
        'في الصباح والمساء؛ فإنَّ فيها من النفع والدَّفْع ما هي مشتملة عليه.\n'
        'فعلى مَنْ أحبَّ السلامةَ مِنَ الآفات في الدنيا، والفوزَ بالخير الآجِل '
        'والعاجلِ أن يُلازِمَها ويفعلَها في كلِّ صباحٍ ومساء، فإنْ عَسُرَ عليه '
        'الإتيانُ بجميعها أتى ببعضٍ منها».',
    page: 'ص30',
  ),
  ReminderQuote(
    'وقد عَيَّن الصادقُ المصدوق ﷺ لهذين الوقتين المباركَينِ أذكارًا كثيرةً '
    'عظيمةَ الفضائل والبركات، وهي حِصْنٌ حصين لِمَن لَزِمها، ولأهله وولدِه '
    'وماله، وحِرْزٌ مَنيعٌ من كيدِ شيطانِ الجِنَّةِ وشيطانِ الناس، ووسيلةٌ '
    'لتحصيل عافيةِ الدُّنيا والآخرة.',
    null,
    reference: 'وقد عَيَّن الصادقُ المصدوق ﷺ لهذين الوقتين المباركَينِ '
        'أذكارًا كثيرةً عظيمةَ الفضائل والبركات، وهي حِصْنٌ حصين لِمَن لَزِمها، '
        'ولأهله وولدِه وماله، وحِرْزٌ مَنيعٌ من كيدِ شيطانِ الجِنَّةِ وشيطانِ '
        'الناس، ووسيلةٌ لتحصيل عافيةِ الدُّنيا والآخرة.',
    page: 'ص30',
  ),
  ReminderQuote(
    'فمن وُفِّقَ للعمل بها كُلِّها فهي نعمةٌ وفضلٌ من الله عَزَّ وَجَلَّ، ومَن '
    'عجز عن جميعها فلْيقتصِر على قدرٍ يداومُ عليه ولو كان ذكرًا واحدًا، '
    'وفضلُ الأكثر الأكثر، والأوسط أقصد، وهو أجدر بأن يدومَ عليه.',
    null,
    reference: 'فمن وُفِّقَ للعمل بها كُلِّها فهي نعمةٌ وفضلٌ من الله عَزَّ '
        'وَجَلَّ، ومَن عجز عن جميعها فلْيقتصِر على قدرٍ يداومُ عليه ولو كان '
        'ذكرًا واحدًا، وفضلُ الأكثر الأكثر، والأوسط أقصد، وهو أجدر بأن يدومَ '
        'عليه.',
    page: 'ص30، الحاشية 2',
  ),
];

const _prophet = 'النبي ﷺ';

const _bestOfDeeds = ReminderQuote(
  'ألا أنبئكم بخير أعمالكم وأزكاها عند مليككم، وأرفعها في درجاتكم، وخير لكم '
      'من إنفاق الذهب والوَرِق، وخير لكم من أن تلقوا عدوكم فتضربوا أعناقهم '
      'ويضربوا أعناقكم، قالوا: بلى، قال: ذكر الله عز وجل',
  '$_prophet — رواه أحمد والترمذي وصححه الألباني',
  reference:
      'ألا أنبئكم بخير أعمالكم وأزكاها عند مليككم، وأرفعها في درجاتكم، وخير '
      'لكم من إنفاق الذهب والوَرِق، وخير لكم من أن تلقوا عدوكم فتضربوا '
      'أعناقهم ويضربوا أعناقكم، قالوا: بلى، قال: ذكر الله عز وجل',
  page: 'https://www.islamweb.net/ar/fatwa/183667/',
);

const _generalVirtues = [
  ReminderQuote(
    'مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
    '$_prophet — متفق عليه',
    reference: 'مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
    page: 'https://www.islamweb.net/ar/fatwa/72887/',
  ),
  ReminderQuote(
    'لا يزال لسانك رطباً من ذكر الله',
    '$_prophet — رواه الترمذي وحسنه',
    reference: 'لا يزال لسانك رطباً من ذكر الله',
    page: 'https://www.islamweb.net/ar/fatwa/46667/',
  ),
  _bestOfDeeds,
  ReminderQuote(
    'ما عمل آدمي عملاً أنجى له من العذاب من ذكر الله',
    '$_prophet — رواه الطبراني وصححه الألباني',
    reference: 'ما عمل آدمي عملاً أنجى له من العذاب من ذكر الله',
    page: 'https://www.islamweb.net/ar/fatwa/183667/',
  ),
  ReminderQuote(
    'أفضل الذكر لا إله إلا الله، وأفضل الدعاء الحمد لله',
    '$_prophet — رواه ابن ماجه والترمذي وحسنه',
    reference: 'أفضل الذكر لا إله إلا الله، وأفضل الدعاء الحمد لله',
    page: 'https://www.islamweb.net/ar/fatwa/46667/',
  ),
];

/// Each reminder's own set, keyed by the title it shows. A set has seven
/// quotes or more, so no quote returns within a week. Morning and evening
/// share the book's set.
const Map<int, List<ReminderQuote>> kReminderQuotes = {
  1: _morningAndEvening,
  2: _morningAndEvening,
  18: [
    ReminderQuote(
      'الآيتان من آخر سورة البقرة من قرأهما في ليلة كفتاه',
      '$_prophet — متفق عليه',
      reference: 'الآيتان من آخر سورة البقرة من قرأهما في ليلة كفتاه',
      page: 'https://www.islamweb.net/ar/fatwa/23112/',
    ),
    ReminderQuote(
      'ألا أدلكما على ما هو خير لكما من خادم إذا أويتما إلى فراشكما أو '
          'أخذتما مضاجعكما فكبرا ثلاثا وثلاثين وسبحا ثلاثا وثلاثين واحمدا ثلاثا '
          'وثلاثين فهذا خير لكما من خادم',
      '$_prophet — رواه البخاري',
      reference: 'ألا أدلكما على ما هو خير لكما من خادم إذا أويتما إلى فراشكما '
          'أو أخذتما مضاجعكما فكبرا ثلاثا وثلاثين وسبحا ثلاثا وثلاثين واحمدا '
          'ثلاثا وثلاثين فهذا خير لكما من خادم',
      page: 'https://www.islamweb.net/ar/library/content/0/6059/',
    ),
    ..._generalVirtues,
  ],
};

/// How many days each reminder's turn runs ahead of the morning's. Morning
/// and evening turn through one set, and this shift puts each quote on a
/// different weekday in each, so no quote shows in two reminders on the same
/// day.
const Map<int, int> _dayShift = {1: 0, 2: 3, 18: 1};

/// The quote a reminder shows on [date]. A set is laid out a week to a row:
/// each weekday has its column, and a column holding more than one quote
/// turns through them week by week. So two days in a row, or in one week,
/// never show the same quote, and re-planning the list keeps each day's
/// quote. Null when the title has no set.
ReminderQuote? quoteFor(int titleId, DateTime date) {
  final set = kReminderQuotes[titleId];
  if (set == null || set.isEmpty) return null;
  final day = DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(1970))
          .inDays +
      (_dayShift[titleId] ?? 0);
  final column = day % 7;
  final rows = (set.length - 1 - column) ~/ 7 + 1;
  return set[column + 7 * (day ~/ 7 % rows)];
}

/// The notification's text: the quote, then its source on its own line when
/// it has one. The first line is what the collapsed notification shows. In
/// the last week the renewal line comes first.
String reminderBody(ReminderQuote? quote, {String? renewHint}) {
  return [
    if (renewHint != null) renewHint,
    if (quote != null) quote.text,
    if (quote?.source case final source?) source,
  ].join('\n');
}
