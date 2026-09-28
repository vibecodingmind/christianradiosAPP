import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/widgets/audio_wave_indicator.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/station_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCountry;
  String? _selectedCategoryId;
  String _searchQuery = '';

  static const _countries = [
    ('All Countries', null, '🌍'),
    ('USA', 'US', '🇺🇸'),
    ('UK', 'GB', '🇬🇧'),
    ('Nigeria', 'NG', '🇳🇬'),
    ('Kenya', 'KE', '🇰🇪'),
    ('South Africa', 'ZA', '🇿🇦'),
    ('Ghana', 'GH', '🇬🇭'),
    ('Tanzania', 'TZ', '🇹🇿'),
    ('Uganda', 'UG', '🇺🇬'),
    ('Canada', 'CA', '🇨🇦'),
    ('Brazil', 'BR', '🇧🇷'),
    ('Australia', 'AU', '🇦🇺'),
    ('Rwanda', 'RW', '🇷🇼'),
    ('Zambia', 'ZM', '🇿🇲'),
    ('Zimbabwe', 'ZW', '🇿🇼'),
    ('Malawi', 'MW', '🇲🇼'),
    ('Ethiopia', 'ET', '🇪🇹'),
    ('DR Congo', 'CD', '🇨🇩'),
    ('Cameroon', 'CM', '🇨🇲'),
    ('India', 'IN', '🇮🇳'),
    ('Philippines', 'PH', '🇵🇭'),
    ('Germany', 'DE', '🇩🇪'),
    ('France', 'FR', '🇫🇷'),
    ('Mexico', 'MX', '🇲🇽'),
    ('South Korea', 'KR', '🇰🇷'),
  ];

  StationFilter get _filter => StationFilter(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategoryId,
        country: _selectedCountry,
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _selectedCountryLabel() {
    if (_selectedCountry == null) return '🌍 Country';
    for (final c in _countries) {
      if (c.$2 == _selectedCountry) return '${c.$3} ${c.$1}';
    }
    return '🌍 $_selectedCountry';
  }

  String _selectedCategoryLabel(List<RadioCategory> categories) {
    if (_selectedCategoryId == null) return 'Category';
    for (final cat in categories) {
      if (cat.id == _selectedCategoryId || cat.slug == _selectedCategoryId) {
        return cat.name;
      }
    }
    return 'Category';
  }

  void _showCountryPicker(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);
    String countryQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filteredCountries = _countries.where((c) {
            if (countryQuery.isEmpty) return true;
            final q = countryQuery.toLowerCase();
            final matchesName = c.$1.toLowerCase().contains(q);
            final matchesCode = (c.$2 ?? '').toLowerCase().contains(q);
            return matchesName || matchesCode;
          }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by Country',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Search Country Input inside Country Dropdown
                    SizedBox(
                      height: 44,
                      child: TextField(
                        autofocus: false,
                        onChanged: (val) => setModalState(() => countryQuery = val.trim()),
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search country name or code...',
                          hintStyle: TextStyle(fontSize: 13, color: textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 19, color: textMuted),
                          suffixIcon: countryQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, size: 17, color: textMuted),
                                  onPressed: () => setModalState(() => countryQuery = ''),
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.scaffoldBg(context),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: border, height: 8),
                    Flexible(
                      child: filteredCountries.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Text(
                                  'No country matching "$countryQuery"',
                                  style: TextStyle(fontSize: 13.5, color: textMuted),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredCountries.length,
                              itemBuilder: (_, idx) {
                                final (label, code, flag) = filteredCountries[idx];
                                final isSel = _selectedCountry == code;
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: Text(flag, style: const TextStyle(fontSize: 18)),
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? AppColors.royalBlue : textPrimary,
                                    ),
                                  ),
                                  trailing: isSel
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.royalBlue, size: 20)
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedCountry = code);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<RadioCategory> categories) {
    final textPrimary = AppColors.textPrimary(context);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted(context)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: border, height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.grid_view_rounded, size: 19, color: AppColors.royalBlue),
                      title: Text(
                        'All Categories',
                        style: TextStyle(
                          fontWeight: _selectedCategoryId == null ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedCategoryId == null ? AppColors.royalBlue : textPrimary,
                        ),
                      ),
                      trailing: _selectedCategoryId == null
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.royalBlue, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategoryId = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...categories.map((cat) {
                      final isSel = _selectedCategoryId == cat.id;
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.radio_rounded, size: 19, color: AppColors.royalBlue),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? AppColors.royalBlue : textPrimary,
                          ),
                        ),
                        trailing: isSel
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.royalBlue, size: 20)
                            : null,
                        onTap: () {
                          setState(() => _selectedCategoryId = cat.id);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(allStationsProvider(_filter));
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? const <RadioCategory>[];
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg(context),
        title: const Text('Explore Radios'),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: Column(
        children: [
          // ── Single Row: Glassy Search Bar + Country Filter + Category Filter ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              children: [
                // 1. Glassy Search Pill
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      style: TextStyle(fontSize: 13.5, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search radios...',
                        hintStyle: TextStyle(fontSize: 13, color: textMuted),
                        prefixIcon: Icon(Icons.search_rounded, size: 19, color: primaryColor),
                        prefixIconConstraints: const BoxConstraints(minWidth: 36),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(Icons.close_rounded, size: 16, color: textMuted),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(minWidth: 28),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: primaryColor, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Country Filter Dropdown Button (Same Row)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showCountryPicker(context),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _selectedCountry != null
                            ? primaryColor.withValues(alpha: 0.14)
                            : cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _selectedCountry != null ? primaryColor : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCountryLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedCountry != null ? FontWeight.w700 : FontWeight.w600,
                                color: _selectedCountry != null ? primaryColor : textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: _selectedCountry != null ? primaryColor : textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Category Filter Dropdown Button (Same Row)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showCategoryPicker(context, categories),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _selectedCategoryId != null
                            ? primaryColor.withValues(alpha: 0.14)
                            : cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _selectedCategoryId != null ? primaryColor : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: _selectedCategoryId != null ? primaryColor : textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedCategoryLabel(categories),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedCategoryId != null ? FontWeight.w700 : FontWeight.w600,
                                color: _selectedCategoryId != null ? primaryColor : textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: _selectedCategoryId != null ? primaryColor : textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Glassy Station Cards List
          Expanded(
            child: stationsAsync.when(
              loading: () => const AudioWavePreloader(
                label: 'Tuning radio stations...',
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load stations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allStationsProvider(_filter)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (stations) {
                if (stations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radio_outlined, size: 56, color: textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No radios found',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try clearing your search, country, or category filter.',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCountry != null ||
                            _selectedCategoryId != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reset Filters'),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCountry = null;
                                _selectedCategoryId = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final cols = context.stationGridColumns;
                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async => ref.invalidate(allStationsProvider(_filter)),
                  child: cols > 1
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 88,
                          ),
                          itemCount: stations.length,
                          itemBuilder: (_, i) => StationCard(
                            station: stations[i],
                            compact: true,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                          itemCount: stations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => StationCard(
                            station: stations[i],
                            compact: true,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
