import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:flutter/material.dart';

class CityPickerScreen extends StatefulWidget {
  final CityRepository cities;

  const CityPickerScreen({super.key, required this.cities});

  static Route<Place> route(CityRepository cities) {
    return MaterialPageRoute(builder: (_) => CityPickerScreen(cities: cities));
  }

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  List<Place>? _shown;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    final found = await widget.cities.search(query);
    if (mounted) setState(() => _shown = found);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار مدينة'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              key: const ValueKey('city-search'),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ابحث عن مدينة',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: shown == null
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final city = shown[index];
                          return ListTile(
                            title: Text(city.name),
                            subtitle: Text(city.countryName),
                            onTap: () => Navigator.of(context).pop(city),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
