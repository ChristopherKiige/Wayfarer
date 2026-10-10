import 'package:flutter/material.dart';

const _brandBlue = Color(0xFF2B5BA8);

class _Place {
  const _Place(this.name, this.distance, this.category, this.rating, this.color, this.icon);

  final String name;
  final String distance;
  final String category;
  final double rating;
  final Color color;
  final IconData icon;
}

const _places = <_Place>[
  _Place("Mooney's Bay Park", '3.2 km', 'Outdoors', 4.6, Color(0xFFBBD7FA), Icons.park),
  _Place('Byward Market', '4.1 km', 'Food', 4.5, Color(0xFFFFD9A8), Icons.restaurant),
  _Place('Canadian War Museum', '5.0 km', 'Culture', 4.7, Color(0xFFD9C8F5), Icons.museum),
];

const _categories = ['All', 'Outdoors', 'Food', 'Culture', 'Fun'];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        title: const Text('Wayfarer', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.account_circle_outlined, size: 28),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildLocationRow(),
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              itemCount: _places.length,
              itemBuilder: (context, i) => _PlaceCard(place: _places[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: const [
          Icon(Icons.place, size: 16, color: _brandBlue),
          SizedBox(width: 4),
          Text('Near Oshawa, ON', style: TextStyle(fontWeight: FontWeight.w600)),
          Spacer(),
          Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
          SizedBox(width: 4),
          Text('18°C'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search outings...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DAE3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DAE3)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = _categories[i];
          final selected = label == _selected;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            selectedColor: _brandBlue,
            labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            onSelected: (_) => setState(() => _selected = label),
          );
        },
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final _Place place;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: place.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(place.icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.distance} · ${place.category}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${place.rating}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.bookmark_border, color: _brandBlue),
          ],
        ),
      ),
    );
  }
}
