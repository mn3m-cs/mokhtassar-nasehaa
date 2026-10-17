import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class ZikrReportDialog extends StatefulWidget {
  final Zikr zikr;
  final ZikrTitle zikrTitle;

  const ZikrReportDialog({
    super.key,
    required this.zikr,
    required this.zikrTitle,
  });

  @override
  State<ZikrReportDialog> createState() => _ZikrReportDialogState();
}

class _ZikrReportDialogState extends State<ZikrReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reportController = TextEditingController();

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String userReportText = _reportController.text.trim();

    // Construct the email subject/title
    // "title contain app name and version and misspell"
    final String subject = "[زاد الذاكر - v$kAppVersion] تبليغ عن خطأ";

    // Construct the email body
    // "body contain the zikr number and title number and user report"
    final String body = """
[${widget.zikrTitle.id}] ${widget.zikrTitle.name}

[رقم: ${widget.zikr.id} | ترتيب: ${widget.zikr.order}]
"${widget.zikr.body}"

• بلاغ المستخدم عن الخطأ:
$userReportText
""";

    final Email email = Email(
      body: body,
      subject: subject,
      recipients: [kDeveloperEmail],
    );

    // Close the dialog first
    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      await FlutterEmailSender.send(email);
      showToast("تم فتح تطبيق البريد الإلكتروني لإرسال التقرير");
    } catch (e) {
      // If native email client fails to launch (e.g. no client set up on emulator/device),
      // we copy the report to clipboard so they don't lose their input.
      await Clipboard.setData(ClipboardData(text: "$subject\n\n$body"));
      showToast(
          "لم نتمكن من فتح تطبيق البريد. تم نسخ التقرير للحافظة لإرساله يدوياً.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.report_problem_outlined,
                      color: colorScheme.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "الإبلاغ عن خطأ",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Text(
                  "هل وجدت خطأً في هذا الذكر؟ اكتب لنا موضعه، وسنراجعه على الكتاب ونصحّحه إن شاء الله.",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                Text(
                  "الذكر:",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .5),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.zikr.body,
                      style: TextStyle(
                        fontFamily: "Kitab",
                        fontSize: 16,
                        height: 1.6,
                        color: textColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reportController,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: "تفاصيل الخطأ",
                    labelStyle: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 13,
                    ),
                    alignLabelWithHint: true,
                    hintText: "مثال: كلمة مكتوبة بغير ما في الكتاب",
                    hintStyle: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "لا يمكن إرسال بلاغ فارغ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sendReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  child: const Text(
                    "إرسال",
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
