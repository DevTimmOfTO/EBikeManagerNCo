import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_parking_location_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'deleting a bike cascades to its trips, battery, and parking data',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime(2026);

      await db.bikeDao.upsertBike(
        Bike(
          id: 'bike-1',
          nickname: 'Blitz',
          createdAt: now,
          updatedAt: now,
        ).toCompanion(),
      );
      await db.tripDao.upsertTrip(
        Trip(
          id: 'trip-1',
          bikeId: 'bike-1',
          startTime: now,
          source: TripSource.manual,
          createdAt: now,
          updatedAt: now,
        ).toCompanion(),
      );
      await db.batteryHistoryDao.insertEntry(
        BatteryHistoryEntry(
          id: 'entry-1',
          bikeId: 'bike-1',
          timestamp: now,
          eventType: BatteryEventType.chargeCycle,
          createdAt: now,
          updatedAt: now,
        ).toCompanion(),
      );
      await db.parkingLocationDao.setParkedLocation(
        ParkingLocation(
          id: 'pin-1',
          bikeId: 'bike-1',
          lat: 51.5,
          lng: 10.5,
          timestamp: now,
        ).toCompanion(),
      );

      await db.bikeDao.deleteBike('bike-1');

      expect(await db.select(db.bikes).get(), isEmpty);
      expect(await db.select(db.trips).get(), isEmpty);
      expect(await db.select(db.batteryHistoryEntries).get(), isEmpty);
      expect(await db.select(db.parkingLocations).get(), isEmpty);
    },
  );
}
