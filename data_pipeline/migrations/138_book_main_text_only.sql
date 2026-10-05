PRAGMA foreign_keys = ON;
BEGIN;

-- Virtue lines show only what the book prints in its main text under the
-- zikr. Excerpts cut from the takhrij hadiths (which stay whole in source)
-- are removed; the four printed in the main text keep the book's wording.
UPDATE contents SET fadl = '' WHERE TRIM(fadl) <> '' AND id NOT IN (274, 277, 334, 906);
UPDATE contents SET fadl = 'قال رسول الله صلى الله عليه وسلم: «مَنْ رُزِقَهُنَّ عند موته لم تَمَسَّه النارُ».' WHERE id = 274;
UPDATE contents SET fadl = 'قال رسول الله صلى الله عليه وسلم: «مَنْ كان آخِرُ كلامِه: لا إلهَ إلا اللهُ دَخَلَ الجنةَ».' WHERE id = 277;
UPDATE contents SET fadl = 'قال رسول الله صلى الله عليه وسلم: «أفضلُ الدعاءِ دعاءُ يومِ عرفةَ، وأفضلُ ما قلتُه أنا والنبيُّون من قبلي».' WHERE id = 334;
UPDATE contents SET fadl = 'لقول رسول الله صلى الله عليه وسلم: «الدعاءُ بين الأذانِ والإقامةِ مُستجابٌ، فادعوا».' WHERE id = 906;

-- «أو:» marks an alternative, as the book prints it (p14, p19).
UPDATE contents SET body = 'أو: ' || body, search = 'أو ' || search WHERE id IN (22, 50);

-- The morning section's «تنبيه» before the expiation of the gathering (p15).
UPDATE contents SET "order" = 29 WHERE id = 28;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex)
VALUES (
  1194, 1, 28,
  'تنبيه:
فإذا فرغ من الأذكار الموظفة؛ استُحِبَّ له أن يَشرعَ في الأذكار والأدعية المطلقة، وأفضلُها على الإطلاق قراءة القرآن الكريم، ثم الصلاة على النبي صلى الله عليه وسلم، والتهليل، والاستغفار، والتسبيح، والتحميد، والتكبير، والحوقلة، وغيرها.
- فإذا قام عن مجلسه ختمه بكفارة المجلس:',
  0,
  'تنبيه بعد أذكار الصباح. (ص15)

حاشية: التي لا تختص بوقت معين.',
  '', '',
  'تنبيه فإذا فرغ من الأذكار الموظفة استحب له أن يشرع في الأذكار والأدعية المطلقة وأفضلها على الإطلاق قراءة القرآن الكريم ثم الصلاة على النبي صلى الله عليه وسلم والتهليل والاستغفار والتسبيح والتحميد والتكبير والحوقلة وغيرها فإذا قام عن مجلسه ختمه بكفارة المجلس',
  ''
);

PRAGMA user_version = 138;
COMMIT;
