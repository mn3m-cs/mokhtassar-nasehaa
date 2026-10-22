/// A saying shown under a reminder's title, with the line that names its
/// speaker and who reported and graded it.
///
/// [reference] is the saying as [page] prints it, copied from that page, so a
/// test can tell a shown text that was cut or changed from its source.
class ReminderQuote {
  final String text;
  final String source;
  final String reference;
  final String page;

  const ReminderQuote(
    this.text,
    this.source, {
    required this.reference,
    required this.page,
  });
}

const _prophet = 'النبي ﷺ';

const _hundredTasbih = ReminderQuote(
  'من قال حين يصبح، وحين يمسي: سبحان الله وبحمده، مائة مرة، لم يأت أحد يوم '
      'القيامة بأفضل مما جاء به، إلا أحد قال مثل ما قال، أو زاد عليه',
  '$_prophet — رواه مسلم',
  reference:
      'من قال حين يصبح وحين يمسي سبحان الله وبحمده مائة مرة لم يأت أحد يوم '
      'القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد عليه',
  page: 'https://www.islamweb.net/ar/library/content/1/4930/',
);

const _ikhlasAndMuawwidhatayn = ReminderQuote(
  'قُلْ: ﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾ والمعوذتين حين تمسي وحين تصبح ثلاث مرات، '
      'تكفيك من كل شيء',
  '$_prophet — رواه أبو داود وحسّنه الألباني',
  reference: 'قل قل هو الله أحد والمعوذتين حين تمسي وحين تصبح ثلاث مرات '
      'تكفيك من كل شيء',
  page: 'https://islamweb.net/ar/library/index.php?page=bookcontents&flag=1'
      '&bk_no=55&ID=8805',
);

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
/// quotes or more, so no quote returns within a week.
const Map<int, List<ReminderQuote>> kReminderQuotes = {
  1: [_hundredTasbih, _ikhlasAndMuawwidhatayn, ..._generalVirtues],
  2: [
    _hundredTasbih,
    _ikhlasAndMuawwidhatayn,
    ReminderQuote(
      'من قال حين يمسي ثلاث مرات أعوذ بكلمات الله التامات من شر ما خلق لم '
          'يضره حمة تلك الليلة',
      '$_prophet — رواه الترمذي وصححه الألباني',
      reference: 'من قال حين يمسي ثلاث مرات أعوذ بكلمات الله التامات من شر ما '
          'خلق لم يضره حمة تلك الليلة',
      page: 'https://www.islamweb.net/ar/fatwa/print.php?id=130963',
    ),
    ..._generalVirtues,
  ],
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

/// How many days each reminder's turn runs ahead of the morning's. The sets
/// share quotes, and these shifts put a shared quote on a different weekday
/// in each set, so no quote shows in two reminders on the same day.
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

/// The notification's text: the quote, then its source on its own line. The
/// first line is what the collapsed notification shows. In the last week the
/// renewal line comes first.
String reminderBody(ReminderQuote? quote, {String? renewHint}) {
  return [
    if (renewHint != null) renewHint,
    if (quote != null) ...[quote.text, quote.source],
  ].join('\n');
}
