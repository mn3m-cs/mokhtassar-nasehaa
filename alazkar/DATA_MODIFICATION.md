# دليل التعديل الآمن على بيانات تطبيق زاد الذاكر

> نسخة معتمدة من طريقة تعديل البيانات دون إفساد التطبيق.
> **القاعدة الذهبية:** لا تعدّل أبدًا بنية الجداول أو الحقول المطلوبة (NOT NULL)، ولا تكسر الترقيم `order` داخل أي قسم، وارفع `user_version` + `dbVersion` معًا بعد أي تغيير في البيانات.

---

## 1. مكان البيانات

هي **قاعدتا SQLite** مرفقتان ضمن الـ assets (تُنسخان إلى جهاز المستخدم عند أول تشغيل):

| الملف | المحتوى |
|---|---|
| `assets/db/Al-Azkar.db` | بيانات الأذكار (جدولا `titles` و`contents`) — هدف أي تعديل |
| `assets/db/quran.ar.uthmani.v2.db` | نص القرآن كاملًا، جدول واحدة `arabic_text(sura, ayah, text)` (6236 آية) |

التطبيق **لا يقرأ بيانات أذكار من القرص المحلي**؛ أي بيانات مستخدم (مفضلة/علامات/إعدادات) محفوظة في **Hive** منفصلة، فلا تتأثر بتعديل القاعدة.

## 2. بنية `Al-Azkar.db`

### جدول `titles` — أقسام الأذكار (حاليًا 80 صفًا)
| العمود | النوع | المعنى |
|---|---|---|
| `id` | INTEGER PK | مفتاح أساسي |
| `order` | INTEGER NOT NULL | ترتيب العرض (فريد، ولا يلزم أن يساوي `id`) |
| `name` | TEXT | اسم القسم |
| `freq` | TEXT | رموز زمنية: `d` يومي، `w` أسبوعي، `m` شهري، `y` سنوي؛ البادئة `e` = قسم «إضافي» يظهر أيضًا ضمن الفئة الأساسية (مثل `ed`، `em`) |

ملاحظة: فلترة التطبيق (`titles_freq_enum.dart`) تتحقق عبر `freq.contains(firstLetterOf(enum))` أي d/w/m/y — لا تُدخل رموزًا أخرى.

### جدول `contents` — نصوص الأذكار (حاليًا 786 صفًا)
| العمود | النوع | المعنى | إلزامي؟ |
|---|---|---|---|
| `id` | INTEGER PK | مفتاح أساسي فريد | نعم |
| `titleId` | INTEGER NOT NULL | FK → `titles.id` | نعم |
| `order` | INTEGER NOT NULL | الترقيم **داخل القسم** 1..N متصل بلا فجوات | نعم |
| `body` | TEXT NOT NULL | نص الذكر (يدعم `\n` للأسطر) | نعم |
| `count` | INTEGER NOT NULL | عدد مرات التكرار | نعم |
| `source` | TEXT | المصدر، كل مرجع في سطر منفصل يفصل بينها `\n` | لا |
| `hokm` | TEXT | الحكم المنقول من المصدر | لا؛ لا تعتمد أي قيمة جديدة قبل مراجعتها على الكتاب |
| `fadl` | TEXT | الفضل | لا |
| `search` | TEXT | نسخة مبسطة (بدون تشكيل) من النص للبحث فقط — استعلام البحث يعمل `LIKE` على هذا العمود | لا (ولكن إذا تُرك فارغًا لن يظهر الذكر في البحث) |
| `sourceIndex` | TEXT | رقم الذكر في طبعة دار ابن حزم — عرض فقط | لا |

### تنسيق `body` الخاص بـ `QuranText`
157 ذكرًا يضمّن آيات قرآنية تُعرض بخط عثماني. الصيغة الحرفية المطلوبة (تطبيقها في `range_text_formatter.dart`):

```
QuranText[(السورة:من:إلى),(السورة:من:إلى)]
```

أمثلة حقيقية:
- `QuranText[(3:190:200)]`
- `QuranText[(112:1:4)]`

متى وُجدت الكلمة `QuranText` في `body` يستدير التطبيق إلى `quran.ar.uthmani.v2.db` لجلب الآيات. **لا تُدخل أي صيغة أخرى.**

## 3. منطق التحميل و«الإصدار» (الأهم لتفعيل التعديل)

الملفات المرجعية:
- `lib/src/core/helpers/db_helper.dart` — منطق النسخ/الحذف.
- `lib/src/core/helpers/azkar_helper.dart` — الثابت `dbVersion = 102` (سطر ~15) وكل استعلامات القراءة.

السلوك الحالي:
1. عند أول تشغيل: تُنسخ قاعدة الـ assets إلى مسار قاعدة بيانات التطبيق.
2. عند كل تشغيل: يُقارن `user_version` المخزنة في الجهاز مع `dbVersion` في الكود.
3. إذا كانت المخزنة **أقل** من `dbVersion` → **حذف القاعدة القديمة وإعادة نسخ قاعدة الـ assets**.
4. لذلك محتوى الـ assets هو المرجع النهائي دائمًا.

> **استنتاج إلزامي:** أي تعديل على `assets/db/Al-Azkar.db` لن يصله المستخدم إلا إذا أصبحت القيمة الجديدة المخزنة فيه ≥ قيمة `dbVersion` الجديدة في الكود.

## 4. أصل البيانات (Excel + المحوّل)

- قاعدة `.db` مبنية على ملف Excel رئيسي عبر `excel2sqflite/main.py` بتعيين `excel2sqflite/config.json` (أوراق `titles` و`contents` → الجدولين مع الأنواع والـ FK).
- **ملف Excel نفسه غير موجود في المستودع** (مُستثنى في `.gitignore`).
- ⚠️ `config.json` المسجّل **لا يتضمن عمود `sourceIndex`** → القاعدة الجارية حُدّثت خارج الأداة؛ لا تعتمد على إعادة تشغيل الأداة كما هي دون تحديث `config.json` أولًا.
- لا حاجة لتعديل `config.json` إن كنت تعدّل القاعدة مباشرة.

## 5. إجراء التعديل الآمن (خطوة بخطوة)

### أ. فقط تعديل محتوى القاعدة المرفقة (الطريقة الأقصر الموصى بها)
1. **نسخ احتياطي** لـ `assets/db/Al-Azkar.db` قبل أي شيء.
2. نفّذ التعديل **داخل معاملة**: `BEGIN; ... COMMIT;` مع `PRAGMA foreign_keys=ON;` (تكشف أخطاء `titleId` فورًا).
3. التزم قواعد منع الفساد في القسم 6.
4. بعد التعديل، حدّث الإصدار ليلتقطه الجهاز:
   - في القاعدة: `PRAGMA user_version = N;` حيث `N` أكبر من الإصدار الحالي (102).
   - في الكود: غيّر `AzkarDBHelper.dbVersion` في `lib/src/core/helpers/azkar_helper.dart` إلى **نفس** `N`.
5. أعد البناء (أدناه) واختبر.
6. لا تنسَ أن الملفين الجديدين اللذين ولّدهما `flutterfire` (فقط لمشروع noor) يخصان مشروع آخر — لا علاقة لهما بإجراءات هذا المشروع.

### ب. التعديل «الرسمي» عبر المصدر
- عدّل ملف Excel الرئيس ثم حدّث `excel2sqflite/config.json` ليغطي كل الأعمدة الحالية (بما فيها `sourceIndex`)، ثم شغّل `python3 main.py` داخل `excel2sqflite/` لتوليد القاعدة، وطبق خطوة الإصدار (4 أعلاه).

### ج. البناء والاختبار
```bash
cd ~/workspace/azkar-apps/alazkar_naseeha/alazkar
fvm flutter analyze
fvm flutter build apk --debug --flavor dev
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
adb shell am start -n com.menemlabs.zaadalthakir.dev/com.menemlabs.zaadalthakir.MainActivity
```
- للمحاكي: شغّله أولًا `emulator -avd pixel_7 &` (لا يعمل حاليًا).
- إعادة تثبيت الـ APK تمسح قاعدة القاعدة المحلية في الاختبار المحلي، لذا تكفي لاختبار التعديل على المحاكي دون آليات الإصدار.

## 6. قواعد منع الفساد (Don'ts)

| القاعدة | السبب |
|---|---|
| ❌ لا تغيّر بنية الجداول أو أنواع الأعمدة | النموذجان `Zikr`/`ZikrTitle` (`lib/src/core/models/`) يقرآن الأعمدة بالأسماء وأنواعها الحرفية؛ أي `null` في `body`/`titleId`/`count`/`order` أو `hokm` سيكسر `fromMap` |
| ❌ لا تترك `id` مكررًا | المفتاحان الأساسيان |
| ❌ لا تغيّر `order` بلا مراجعة المصدر (انظر بند «الترقيم») | `getContentByTitleId` يرتب به عناصر القسم |
| ❌ لا تدخل `titleId` غير موجود | FK — رقابته فعالة الآن |
| ❌ لا تعدّل `hokm` اعتمادًا على القاعدة الحالية وحدها | الحكم يحتاج مراجعة على المصدر المعتمد |
| ❌ لا تُدخل رموزًا غير d/w/m/y في `freq` | فلترة التطبيق تعتمد عليها |
| ❌ لا تُدخل آيات بغير صيغة `QuranText[(...) ]` | لن تُعرض وربما تكسر العرض |
| ❌ لا تعدّل `quran.ar.uthmani.v2.db` إلا بفهم كامل | تُستخدم عبر `UthmaniRepository` (سورة/آية) لمئات الأذكار |
| ❌ لا تغيّر بيانات دون رفع `user_version` و`dbVersion` معًا | الأجهزة المثبتة ستقرأ النسخة القديمة |

### الترقيم `order` (الأخطر)
- `contents.order` يحدد ترتيب العرض داخل كل `titleId`؛ وجود فجوة رقمية لا يثبت وحده فقدان ذكر أو خطأ في المحتوى.
- عند **إضافة** ذكر في قسم: عيّن له `order = آخر ترتيب القسم + 1` (أو أعد ترقيم 1..N بعد إعادة الترتيب).
- عند **حذف** ذكر: لا تُعد ترقيم بقية الصفوف إلا بعد التحقق من أن الأرقام ليست مرتبطة بترتيب المصدر.
- لا علاقة لأرقام `contents.order` العالمية بأي شيء خارج قسمها؛ لكن استعلام النتائج في البحث يمر عليها، فالالتزام بالترقيم يحفظ اتساق العرض.

## 7. نقاط تحقق جاهزة (تُستخدم في الاختبار)
- عدد الأقسام: `SELECT COUNT(*) FROM titles;` → 80
- عدد الأذكار: `SELECT COUNT(*) FROM contents;` → 786
- لا صفوف معطوبة:
  ```sql
  SELECT COUNT(*) FROM contents WHERE body IS NULL OR count IS NULL OR titleId IS NULL; -- يجب 0
  SELECT COUNT(*) FROM contents WHERE titleId NOT IN (SELECT id FROM titles);      -- يجب 0
  SELECT COUNT(*) FROM contents WHERE hokm IS NULL;                                -- يجب 0
  ```
- فحص سريع بصري عبر المحاكي بعد التثبيت: افتح القسم المُعدَّل وتأكد من الترتيب والنص.

## 8. ملفات مرجعية في الكود
| الملف | المسؤولية |
|---|---|
| `lib/src/core/helpers/db_helper.dart` | نسخ/حذف قاعدة الـ assets + مقارنة الإصدار |
| `lib/src/core/helpers/azkar_helper.dart` | `dbVersion` + كل استعلامات القراءة (titles/contents/search) |
| `lib/src/core/models/zikr.dart` | نموذج صف `contents` (يطابق الأعمدة بالأسماء) |
| `lib/src/core/models/zikr_title.dart` | نموذج صف `titles` |
| `lib/src/features/home/data/models/titles_freq_enum.dart` | منطق فلترة `freq` |
| `lib/src/features/search/data/models/sql_query.dart` | بناء استعلامات البحث |
| `lib/src/core/utils/range_text_formatter.dart` | تحليل صيغة `QuranText[(s:f:to)]` |
| `lib/src/features/quran/data/repository/uthmani_repository.dart` | قراءة آيات من قاعدة القرآن |
| `excel2sqflite/main.py` + `config.json` | (الأصل) توليد `.db` من Excel — لاحظ نقص `sourceIndex` في config |
