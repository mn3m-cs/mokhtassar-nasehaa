/// A saying shown under a reminder's title, with the line that names its
/// speaker and who reported and graded it.
class ReminderQuote {
  final String text;
  final String source;

  const ReminderQuote(this.text, this.source);
}

const _prophet = 'النبي ﷺ';

const _hundredTasbih = ReminderQuote(
  'من قال حين يصبح، وحين يمسي: سبحان الله وبحمده، مائة مرة، لم يأت أحد يوم '
      'القيامة بأفضل مما جاء به، إلا أحد قال مثل ما قال، أو زاد عليه',
  '$_prophet — اتفق عليه الشيخان',
);

const _ikhlasAndMuawwidhatayn = ReminderQuote(
  '﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾ والمعوذتين حين تمسي وحين تصبح ثلاث مرات، '
      'تكفيك من كل شيء',
  '$_prophet — رواه الترمذي وصححه الألباني',
);

const _bestOfDeeds = ReminderQuote(
  'ألا أنبئكم بخير أعمالكم وأزكاها عند مليككم، وأرفعها في درجاتكم، وخير لكم '
      'من إنفاق الذهب والوَرِق، وخير لكم من أن تلقوا عدوكم فتضربوا أعناقهم '
      'ويضربوا أعناقكم، قالوا: بلى، قال: ذكر الله عز وجل',
  '$_prophet — رواه أحمد والترمذي وصححه الألباني',
);

const _generalVirtues = [
  ReminderQuote(
    'مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
    '$_prophet — متفق عليه',
  ),
  ReminderQuote(
    'لا يزال لسانك رطباً من ذكر الله',
    '$_prophet — رواه الترمذي وحسنه',
  ),
  _bestOfDeeds,
  ReminderQuote(
    'ما عمل آدمي عملاً أنجى له من العذاب من ذكر الله',
    '$_prophet — رواه الطبراني وصححه الألباني',
  ),
  ReminderQuote(
    'أفضل الذكر لا إله إلا الله',
    '$_prophet — رواه ابن ماجه والترمذي وحسنه',
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
    ),
    ..._generalVirtues,
  ],
  18: [
    ReminderQuote(
      'الآيتان من آخر سورة البقرة من قرأهما في ليلة كفتاه',
      '$_prophet — متفق عليه',
    ),
    ReminderQuote(
      'ألا أدلكما على ما هو خير لكما من خادم إذا أويتما إلى فراشكما أو '
          'أخذتما مضاجعكما فكبرا ثلاثا وثلاثين وسبحا ثلاثا وثلاثين واحمدا ثلاثا '
          'وثلاثين فهذا خير لكما من خادم',
      '$_prophet — رواه البخاري',
    ),
    ..._generalVirtues,
  ],
};

/// The quote a reminder shows on [date]: the set turns one quote a day, so
/// two days in a row never show the same one, and re-planning the list
/// keeps each day's quote. Null when the title has no set.
ReminderQuote? quoteFor(int titleId, DateTime date) {
  final set = kReminderQuotes[titleId];
  if (set == null || set.isEmpty) return null;
  final days = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;
  return set[days % set.length];
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
