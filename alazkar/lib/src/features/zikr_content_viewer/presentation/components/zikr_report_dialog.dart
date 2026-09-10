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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: Colors.amber,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "تبليغ عن خطأ",
                        style: TextStyle(
                          fontFamily: "Cairo",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  "يرجى كتابة تفاصيل الخطأ في هذا الذكر وسنقوم بتعديله في أسرع وقت إن شاء الله.",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: .5),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.zikr.body,
                      style: const TextStyle(
                        fontFamily: "Kitab",
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
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
                    hintText: "اكتب الخطأ الذي تراه",
                    hintStyle: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "إلغاء",
                        style: TextStyle(
                          fontFamily: "Cairo",
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _sendReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        "إرسال",
                        style: TextStyle(
                          fontFamily: "Cairo",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
