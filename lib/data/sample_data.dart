import '../models/place.dart';
import '../models/trip.dart';

/// Where distances are measured from (downtown Oshawa).
const String homeLabel = 'Oshawa, ON';
const double homeLatitude = 43.8971;
const double homeLongitude = -78.8658;

/// Sample places around Durham Region. Ratings are placeholder values until
/// the Places API is connected.
const List<Place> samplePlaces = <Place>[
  Place(
    id: 'lakeview-park',
    name: 'Lakeview Park',
    category: PlaceCategory.outdoors,
    description: 'Sandy beach, picnic spots and a waterfront trail along Lake Ontario.',
    address: 'Lakeview Park Ave, Oshawa',
    latitude: 43.8623,
    longitude: -78.8362,
    rating: 4.6,
  ),
  Place(
    id: 'second-marsh',
    name: 'Second Marsh Wildlife Area',
    category: PlaceCategory.outdoors,
    description: 'Coastal wetland with boardwalks, a viewing tower and good bird-watching.',
    address: 'Colonel Sam Dr, Oshawa',
    latitude: 43.8711,
    longitude: -78.8064,
    rating: 4.5,
  ),
  Place(
    id: 'botanical-gardens',
    name: 'Oshawa Valley Botanical Gardens',
    category: PlaceCategory.outdoors,
    description: 'Peony gardens and walking paths in the Oshawa Creek valley.',
    address: '155 Arena St, Oshawa',
    latitude: 43.9033,
    longitude: -78.8505,
    rating: 4.6,
  ),
  Place(
    id: 'whitby-harbour',
    name: 'Whitby Harbour',
    category: PlaceCategory.outdoors,
    description: 'Marina, harbour views and a stretch of the Waterfront Trail.',
    address: 'Port Whitby, Whitby',
    latitude: 43.8560,
    longitude: -78.9370,
    rating: 4.4,
  ),
  Place(
    id: 'parkwood',
    name: 'Parkwood Estate',
    category: PlaceCategory.culture,
    description: 'Historic home of R. S. McLaughlin with formal gardens and house tours.',
    address: '270 Simcoe St N, Oshawa',
    latitude: 43.9103,
    longitude: -78.8587,
    rating: 4.7,
  ),
  Place(
    id: 'auto-museum',
    name: 'Canadian Automotive Museum',
    category: PlaceCategory.culture,
    description: 'Vintage and classic cars that tell the story of Oshawa\'s car industry.',
    address: '99 Simcoe St S, Oshawa',
    latitude: 43.8957,
    longitude: -78.8636,
    rating: 4.5,
  ),
  Place(
    id: 'rmg',
    name: 'Robert McLaughlin Gallery',
    category: PlaceCategory.culture,
    description: 'Art gallery known for Canadian modern art, including Painters Eleven.',
    address: '72 Queen St, Oshawa',
    latitude: 43.8997,
    longitude: -78.8653,
    rating: 4.6,
  ),
  Place(
    id: 'bistro-67',
    name: 'Bistro \'67',
    category: PlaceCategory.food,
    description: 'Durham College\'s teaching restaurant, serving local and seasonal dishes.',
    address: 'Champlain Ave, Whitby',
    latitude: 43.8762,
    longitude: -78.9118,
    rating: 4.5,
  ),
  Place(
    id: 'oshawa-centre',
    name: 'Oshawa Centre Food Court',
    category: PlaceCategory.food,
    description: 'Big food court inside the region\'s largest mall. Easy group stop.',
    address: '419 King St W, Oshawa',
    latitude: 43.8920,
    longitude: -78.8814,
    rating: 4.1,
  ),
  Place(
    id: 'tribute-centre',
    name: 'Tribute Communities Centre',
    category: PlaceCategory.fun,
    description: 'Home of the Oshawa Generals, plus concerts and big events.',
    address: '99 Athol St E, Oshawa',
    latitude: 43.8972,
    longitude: -78.8589,
    rating: 4.4,
  ),
  Place(
    id: 'campus-ice',
    name: 'Campus Ice Centre',
    category: PlaceCategory.fun,
    description: 'Public skating rinks right next to the north Oshawa campus.',
    address: 'Simcoe St N, Oshawa',
    latitude: 43.9455,
    longitude: -78.8968,
    rating: 4.2,
  ),
  Place(
    id: 'lakeridge',
    name: 'Lakeridge Ski Resort',
    category: PlaceCategory.fun,
    description: 'Ski and snowboard hills about half an hour north of Oshawa.',
    address: 'Chalk Lake Rd, Uxbridge',
    latitude: 44.0740,
    longitude: -78.9930,
    rating: 4.3,
  ),
];

/// Looks up a place by id; null if it isn't in the list.
Place? placeById(String? id) {
  if (id == null) return null;
  for (final Place p in samplePlaces) {
    if (p.id == id) return p;
  }
  return null;
}

/// Trips loaded on first launch so no screen starts empty. Dates are relative
/// to today so the demo always has an upcoming and a past trip.
List<Trip> buildSampleTrips() {
  final DateTime today = dateOnly(DateTime.now());
  DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);

  final DateTime w = day(6);
  final DateTime m = day(20);
  final DateTime p = day(-25);

  return <Trip>[
    Trip(
      id: 'sample-waterfront',
      name: 'Waterfront weekend',
      destination: 'Oshawa & Whitby',
      startDate: w,
      endDate: day(7),
      notes: 'Bring a jacket for the lake wind.',
      colorIndex: 0,
      stops: <TripStop>[
        TripStop(
          id: 's1',
          title: 'Lakeview Park',
          date: w,
          minutes: 600,
          placeId: 'lakeview-park',
          note: 'Beach walk',
        ),
        TripStop(
          id: 's2',
          title: 'Second Marsh Wildlife Area',
          date: w,
          minutes: 780,
          placeId: 'second-marsh',
        ),
        TripStop(
          id: 's3',
          title: 'Bistro \'67',
          date: day(7),
          minutes: 720,
          placeId: 'bistro-67',
          note: 'Book a table',
        ),
        TripStop(
          id: 's4',
          title: 'Whitby Harbour',
          date: day(7),
          minutes: 870,
          placeId: 'whitby-harbour',
        ),
      ],
    ),
    Trip(
      id: 'sample-museums',
      name: 'Rainy day museum hop',
      destination: 'Downtown Oshawa',
      startDate: m,
      endDate: m,
      colorIndex: 2,
      stops: <TripStop>[
        TripStop(
          id: 's5',
          title: 'Canadian Automotive Museum',
          date: m,
          minutes: 630,
          placeId: 'auto-museum',
        ),
        TripStop(
          id: 's6',
          title: 'Robert McLaughlin Gallery',
          date: m,
          minutes: 780,
          placeId: 'rmg',
        ),
        TripStop(
          id: 's7',
          title: 'Parkwood Estate',
          date: m,
          minutes: 900,
          placeId: 'parkwood',
          note: 'Last tour slot',
        ),
      ],
    ),
    Trip(
      id: 'sample-fall',
      name: 'Fall colours walk',
      destination: 'Oshawa Creek valley',
      startDate: p,
      endDate: p,
      colorIndex: 3,
      reminder: false,
      stops: <TripStop>[
        TripStop(
          id: 's8',
          title: 'Oshawa Valley Botanical Gardens',
          date: p,
          minutes: 660,
          placeId: 'botanical-gardens',
        ),
      ],
    ),
  ];
}
