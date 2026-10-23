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

  /// The book's page on the author's site, opened by the «المصدر» tile.
  static const String kBookPageUrl = "https://almukaddem.com/ar/3240";

  /// Opens a link; tests pass their own to see which link is tapped.
  final Future<void> Function(String url) openUrl;

  const AboutScreen({
    super.key,
    this.openUrl = openURL,
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
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text("المصدر"),
            isThreeLine: true,
            subtitle: const Text(
              "الكتاب: مختصر النصيحة في الأذكار والأدعية الصحيحة\n"
              "تأليف: محمد أحمد إسماعيل المقدم\n"
              "الطبعة العاشرة المعدلة، ١٤٤٦هـ - ٢٠٢٥م\n"
              "قوبل نص التطبيق بهذه الطبعة صفحة صفحة\n"
              "almukaddem.com",
            ),
            onTap: () => openUrl(kBookPageUrl),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.location_city_outlined),
            title: Text("بيانات المدن"),
            isThreeLine: true,
            subtitle: Text(
              "المواقع من جيونيمز (geonames.org) برخصة المشاع الإبداعي، النسبة ٤٫٠\n"
              "والأسماء العربية من ويكي بيانات",
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: const Text("رابط المشروع المفتوح المصدر"),
            onTap: () {
              openUrl("https://github.com/mn3m-cs/mokhtassar-nasehaa");
            },
          ),
        ],
      ),
    );
  }
}
