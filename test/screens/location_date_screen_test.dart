import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marineguard/screens/location_date_screen.dart';

void main() {
  group('LocationDateScreen Tests', () {
    testWidgets('LocationDateScreen renders correctly', (
      WidgetTester tester,
    ) async {
      // Widget'ı oluştur
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // Temel elementlerin varlığını kontrol et
      expect(find.text('MarineGuard'), findsOneWidget);
      expect(find.text('Search place or coordinates…'), findsOneWidget);
      expect(find.text('Dropped Pin'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Search bar is present and functional', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // Arama çubuğunu bul
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Arama çubuğuna metin gir
      await tester.enterText(searchField, 'İstanbul');
      await tester.pump();

      // Metnin girildiğini kontrol et
      expect(find.text('İstanbul'), findsOneWidget);
    });

    testWidgets('Date selection dropdowns are present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // Dropdown'ları bul
      expect(find.text('Month (1-12)'), findsOneWidget);
      expect(find.text('Day (1-31)'), findsOneWidget);
    });

    testWidgets('Next button is initially disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // Next butonunu bul
      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextButton, findsOneWidget);

      // Butonun devre dışı olduğunu kontrol et
      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('FAB buttons are present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // FAB'leri bul
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });

    testWidgets('Coordinate chips display current location', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LocationDateScreen()));

      // Koordinat chip'lerini kontrol et
      expect(find.textContaining('Latitude:'), findsOneWidget);
      expect(find.textContaining('Longitude:'), findsOneWidget);
    });
  });
}
