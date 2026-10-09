import 'package:flutter/material.dart';

import '../../models/counselor_models.dart';
import '../../services/booking_service.dart';
import '../../services/privacy_service.dart';
import '../booking/book_appointment_screen.dart';

/// Screen 3: Counselor Directory Screen
/// Allows students to browse certified wellness counselors, filter by specialty,
/// verify 100% confidentiality credentials, and initiate appointment bookings.
class CounselorDirectoryScreen extends StatefulWidget {
  const CounselorDirectoryScreen({
    this.bookingService,
    this.privacyService,
    super.key,
  });

  final BookingService? bookingService;
  final PrivacyService? privacyService;

  @override
  State<CounselorDirectoryScreen> createState() =>
      _CounselorDirectoryScreenState();
}

class _CounselorDirectoryScreenState extends State<CounselorDirectoryScreen> {
  late final BookingService _bookingService;
  late final PrivacyService _privacyService;

  final TextEditingController _searchController = TextEditingController();

  List<CounselorModel> _allCounselors = [];
  List<CounselorModel> _filteredCounselors = [];

  bool _isLoading = true;
  String _selectedFilter = 'All';

  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);

  final List<String> _filters = const [
    'All',
    'Anxiety',
    'Academic Stress',
    'Available Today',
  ];

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService.defaultInstance;
    _privacyService = widget.privacyService ?? PrivacyService.defaultInstance;
    _loadCounselors();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCounselors() async {
    setState(() => _isLoading = true);
    try {
      final counselors = await _bookingService.fetchCounselors();
      if (mounted) {
        setState(() {
          _allCounselors = counselors;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCounselors = _allCounselors.where((c) {
        final matchesQuery = query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.title.toLowerCase().contains(query) ||
            c.location.toLowerCase().contains(query) ||
            c.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!matchesQuery) return false;

        if (_selectedFilter == 'All') return true;
        if (_selectedFilter == 'Available Today') {
          return c.availableSlots.isNotEmpty;
        }
        return c.tags.any(
          (tag) => tag.toLowerCase() == _selectedFilter.toLowerCase(),
        );
      }).toList();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  void _navigateToBooking(CounselorModel counselor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(
          counselor: counselor,
          bookingService: _bookingService,
          privacyService: _privacyService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Find a Counselor',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _mintTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _mintBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: _emeraldGreen),
                SizedBox(width: 4),
                Text(
                  'Encrypted',
                  style: TextStyle(
                    color: _darkEmerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounselors,
        color: _emeraldGreen,
        child: Column(
          children: [
            // Search Bar & Filter Strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Counselor List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _emeraldGreen),
                    )
                  : _filteredCounselors.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _filteredCounselors.length,
                          itemBuilder: (context, index) {
                            return _buildCounselorCard(
                              _filteredCounselors[index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by counselor name, specialty, or location...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => _selectFilter(filter),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
            ),
            backgroundColor: const Color(0xFFF8FAFC),
            selectedColor: _emeraldGreen,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? _emeraldGreen : const Color(0xFFCBD5E1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          );
        },
      ),
    );
  }

  Widget _buildCounselorCard(CounselorModel counselor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Info + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Counselor Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  color: _mintTint,
                  child: counselor.image.isNotEmpty
                      ? Image.network(
                          counselor.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildAvatarFallback(counselor.name),
                        )
                      : _buildAvatarFallback(counselor.name),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Title, Location, and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            counselor.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      counselor.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _emeraldGreen,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            counselor.displayLocation,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          counselor.rating,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${counselor.reviewCount} reviews)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confidential Badge & Specialization Tags
          Row(
            children: [
              if (counselor.isConfidentialSupported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _mintTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _mintBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: _emeraldGreen,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '100% Confidential',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _darkEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: counselor.tags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Bottom Bar: Available Slots Preview & Primary "Book Session" Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT AVAILABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: _emeraldGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        counselor.availableSlots.isNotEmpty
                            ? counselor.availableSlots.first
                            : 'Today, 09:30 AM',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FilledButton(
                onPressed: () => _navigateToBooking(counselor),
                style: FilledButton.styleFrom(
                  backgroundColor: _emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  shadowColor: _emeraldGreen.withValues(alpha: 0.3),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Book Session'),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'MC';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _emeraldGreen,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: _mintTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: _emeraldGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No counselors found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search terms or filter selection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _selectFilter('All');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _emeraldGreen,
                side: const BorderSide(color: _emeraldGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
