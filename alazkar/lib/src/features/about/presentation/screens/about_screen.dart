import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/utils/open_url.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  static const String routeName = "/about";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const AboutScreen(),
    );
  }

  const AboutScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "عن التطبيق",
          style: TextStyle(fontFamily: "Uthmanic"),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 15),
          ListTile(
            leading: ClipOval(
              child: Image.asset(
                "assets/icons/logo-round.png",
              ),
            ),
            title: Text(
                "تطبيق زاد الذاكر الإصدار ${kAppVersion.split(" ").first}"),
            subtitle: const Text("تطبيق مجاني خالٍ من الإعلانات ومفتوح المصدر"),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.handshake),
            title: Text("نسألكم الدعاء لنا ولوالدينا"),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.source_outlined),
            title: Text("المصدر"),
            isThreeLine: true,
            subtitle: Text(
              "الكتاب: مختصر النصيحة في الأذكار والأدعية الصحيحة\n"
              "إعداد: محمد أحمد إسماعيل المقدم\n"
              "النشر: دار الأمل ودار التميز، 1443هـ - 2022م",
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: const Text("رابط المشروع المفتوح المصدر"),
            onTap: () {
              openURL("https://github.com/mn3m-cs/mokhtassar-nasehaa");
            },
          ),
        ],
      ),
    );
  }
}
