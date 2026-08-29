import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/domain/unit_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('metric', () {
    const formatter = UnitFormatter(UnitSystem.metric);

    test('formats distance in km', () {
      expect(formatter.distance(8200), '8.2 km');
    });

    test('formats speed in km/h', () {
      expect(formatter.speed(16.4), '16.4 km/h');
    });

    test('formats elevation in metres', () {
      expect(formatter.elevation(45), '45 m');
    });
  });

  group('imperial', () {
    const formatter = UnitFormatter(UnitSystem.imperial);

    test('formats distance in miles', () {
      expect(formatter.distance(1609.344), '1.0 mi');
    });

    test('formats speed in mph', () {
      expect(formatter.speed(100), '62.1 mph');
    });

    test('formats elevation in feet', () {
      expect(formatter.elevation(100), '328 ft');
    });
  });

  test('returns an em dash for null values regardless of unit system', () {
    const formatter = UnitFormatter(UnitSystem.imperial);
    expect(formatter.distance(null), '—');
    expect(formatter.speed(null), '—');
    expect(formatter.elevation(null), '—');
  });
}
