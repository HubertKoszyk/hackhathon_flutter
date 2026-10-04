import 'package:flutter_test/flutter_test.dart';
import 'package:hackhathon_flutter/models/accessible_place.dart';
import 'package:hackhathon_flutter/providers/app_state.dart';
import 'package:hackhathon_flutter/services/krakow_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Miejsca postojowe dla niepełnosprawnych (Koperty) & Hotele i budynki bez barier',
    () {
      test(
        'KrakowDataService contains expanded disabled parking spots (35 spots)',
        () {
          final spots = KrakowDataService.getParkingSpots();
          expect(spots.length, greaterThanOrEqualTo(35));

          for (final spot in spots) {
            expect(spot.id, isNotEmpty);
            expect(spot.street, isNotEmpty);
            expect(spot.district, isNotEmpty);
            expect(spot.spotsCount, greaterThan(0));
            expect(spot.location.latitude, inInclusiveRange(50.0, 50.15));
            expect(spot.location.longitude, inInclusiveRange(19.85, 20.05));
          }
        },
      );

      test(
        'KrakowDataService contains accessible hotels and cultural venues with social links',
        () {
          final places = KrakowDataService.getAccessiblePlaces();
          expect(places.length, greaterThanOrEqualTo(16));

          final hotels = KrakowDataService.getHotels();
          expect(hotels.length, greaterThanOrEqualTo(6));

          final buildings = KrakowDataService.getCulturalAndPublicBuildings();
          expect(buildings.length, greaterThanOrEqualTo(10));

          for (final hotel in hotels) {
            expect(hotel.category, equals(AccessiblePlaceCategory.hotel));
            expect(hotel.hasAdaptedRooms, isTrue);
            expect(hotel.websiteUrl, isNotEmpty);
            expect(hotel.instagramUrl, isNotNull);
            expect(hotel.phoneNumber, isNotNull);
            expect(hotel.accessibilityScore, greaterThanOrEqualTo(90));
          }

          for (final building in buildings) {
            expect(building.websiteUrl, isNotEmpty);
            expect(building.accessibilityScore, greaterThanOrEqualTo(90));
          }
        },
      );

      test(
        'AppState manages selection and filters for parking and accessible places',
        () {
          final state = AppState();

          expect(state.parkingSpots.length, greaterThanOrEqualTo(35));
          expect(state.accessiblePlaces.length, greaterThanOrEqualTo(16));

          // Wybór parkingu
          final testSpot = state.parkingSpots.first;
          state.selectParking(testSpot);
          expect(state.selectedParking?.id, equals(testSpot.id));
          expect(state.selectedAccessiblePlace, isNull);

          // Wybór miejsca/hotelu (powinien odznaczyć parking)
          final testPlace = state.accessiblePlaces.first;
          state.selectAccessiblePlace(testPlace);
          expect(state.selectedAccessiblePlace?.id, equals(testPlace.id));
          expect(state.selectedParking, isNull);

          // Filtrowanie kategorii
          state.setPlaceCategoryFilter('hotel');
          expect(
            state.accessiblePlaces.every(
              (p) => p.category == AccessiblePlaceCategory.hotel,
            ),
            isTrue,
          );

          state.setPlaceCategoryFilter('building');
          expect(
            state.accessiblePlaces.every(
              (p) => p.category != AccessiblePlaceCategory.hotel,
            ),
            isTrue,
          );

          state.setPlaceCategoryFilter('all');
          expect(
            state.accessiblePlaces.length,
            equals(state.allAccessiblePlaces.length),
          );
        },
      );
    },
  );
}
