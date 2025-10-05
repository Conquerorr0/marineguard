import 'package:flutter/material.dart';

/// Event Selection - grid kartlardan oluşan, tek seçimli ekran
/// Bu ekran konum/tarih seçildikten sonra açılır. Seçilen olayı
/// Navigator.pop(context, selectedEventKey) ile geri döndürür.
class EventSelectionScreen extends StatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  State<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  // İkonlar: lib/assets/icons/events altında bekleniyor
  // Not: pubspec.yaml'da assets tanımı yapılmalı.
  final List<_EventItem> _items = const [
    _EventItem('wind_high', 'High Wind', 'lib/assets/icons/events/ruzgar.jpg'),
    _EventItem('rain_high', 'Heavy Rain', 'lib/assets/icons/events/yagmur.jpg'),
    _EventItem('wave_high', 'High Wave', 'lib/assets/icons/events/dalga.jpg'),
    _EventItem('storm_high', 'Storm', 'lib/assets/icons/events/firtina.jpg'),
    _EventItem('fog_low', 'Low Visibility', 'lib/assets/icons/events/sis.jpg'),
    _EventItem(
      'sst_high',
      'High Sea Temperature',
      'lib/assets/icons/events/deniz_sicakliği.jpg',
    ),
    _EventItem(
      'current_strong',
      'Strong Current',
      'lib/assets/icons/events/akinti.jpg',
    ),
    // tide_high kaldırıldı
    _EventItem(
      'ssha_high',
      'Sea Level Anomaly',
      'lib/assets/icons/events/deniz_yüksekliği.jpg',
    ),
  ];

  String? _selectedKey; // tek seçim
  int _navIndex = 0; // alt nav placeholder

  @override
  Widget build(BuildContext context) {
    final canProceed = _selectedKey != null && _selectedKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Event Selection',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Marine Weather Events',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final isSelected = _selectedKey == item.key;
                    return _EventCard(
                      title: item.title,
                      assetPath: item.assetPath,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedKey = item.key);
                        // Kartlar buton gibi çalışsın istendi; hemen geri dönebiliriz.
                        Navigator.pop(context, item.key);
                      },
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: canProceed
                        ? () => Navigator.pop(context, _selectedKey)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      disabledBackgroundColor: const Color(0xFF9ECFE6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // bottom navigation kaldırıldı
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('How selection works?'),
        content: Text(
          'Kartlara dokunarak tek bir olayı seçin. Next ile devam edin.',
        ),
      ),
    );
  }
}

class _EventItem {
  final String key;
  final String title;
  final String assetPath;
  const _EventItem(this.key, this.title, this.assetPath);
}

class _EventCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;
  const _EventCard({
    required this.title,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 16.0;
    return Semantics(
      button: true,
      label: title,
      value: selected ? 'selected' : 'not selected',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(assetPath, fit: BoxFit.cover),
                      AnimatedOpacity(
                        opacity: selected ? 0.22 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(color: Colors.black),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          scale: selected ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
