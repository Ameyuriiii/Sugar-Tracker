import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lib/home_screen.dart';

import '../tests/test/home_screen_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, FirebaseFirestore, CollectionReference, QuerySnapshot, QueryDocumentSnapshot, http.Client])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockQuerySnapshot mockSnapshot;
  late MockQueryDocumentSnapshot mockDoc;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockSnapshot = MockQuerySnapshot();
    mockDoc = MockQueryDocumentSnapshot();
    mockHttpClient = MockHttpClient();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('testUid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockFirestore.collection('meals')).thenReturn(mockCollection);
    when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockCollection);
    when(mockCollection.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockCollection);
    when(mockCollection.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));
  });

  group('HomeScreen Logic Tests', () {
    test('Sum Meal Sugar calculates correctly', () {
      final homeScreenState = _HomeScreenState();
      homeScreenState._productsInMeal.add({'name': 'Apple', 'sugar': 10.0});
      homeScreenState._productsInMeal.add({'name': 'Banana', 'sugar': 15.0});

      expect(homeScreenState._sumMealSugar, 25.0);
    });

    test('Sum Meal Sugar returns 0 for empty list', () {
      final homeScreenState = _HomeScreenState();
      expect(homeScreenState._sumMealSugar, 0.0);
    });

    test('Get Weekly Sugar Data processes snapshot correctly', () {
      final now = DateTime(2025, 4, 3); // Thursday
      final timestamp = Timestamp.fromDate(now);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn({
        'userId': 'testUid',
        'sugar': 20.0,
        'timestamp': timestamp,
      });

      final homeScreenState = _HomeScreenState();
      final spots = homeScreenState._getWeeklySugarData(AsyncSnapshot.withData(ConnectionState.done, mockSnapshot));
      expect(spots.length, 1);
      expect(spots[0].x, 3.0);
      expect(spots[0].y, 20.0);
    });

    test('Compute Today Sugar filters by date', () {
      final now = DateTime(2025, 4, 3);
      final timestamp = Timestamp.fromDate(now);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn({
        'userId': 'testUid',
        'sugar': 15.0,
        'timestamp': timestamp,
      });

      final homeScreenState = _HomeScreenState();
      final total = homeScreenState._computeTodaySugar(AsyncSnapshot.withData(ConnectionState.done, mockSnapshot));
      expect(total, 15.0);
    });

    test('Search Product API handles successful response', () async {
      final homeScreenState = _HomeScreenState();
      when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(
        '{"products": [{"product_name": "Coca Cola", "nutriments": {"sugars_100g": 10.6}}]}',
        200,
      ));

      await homeScreenState._searchProductAPI('coca cola');
      expect(homeScreenState._searchResults.length, 1);
      expect(homeScreenState._searchResults[0]['product_name'], 'Coca Cola');
      expect(homeScreenState._searchResults[0]['nutriments']['sugars_100g'], '10.6');
    });

    test('Search Product API handles empty query', () async {
      final homeScreenState = _HomeScreenState();
      await homeScreenState._searchProductAPI('');
      expect(homeScreenState._searchResults.isEmpty, true);
      verifyNever(mockHttpClient.get(any));
    });
  });
}