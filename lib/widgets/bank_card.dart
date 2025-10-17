// bank_card.dart
import 'package:flutter/material.dart';
import '../pages/main_features/home_screen.dart';
import '../models/bank_site.dart';
import '../pages/main_features/maps/map_utils.dart';

class BankCard extends StatelessWidget {
  final BankSite site;
  final String? staticMapsApiKey; // jika null, tampilkan placeholder map

  const BankCard({
    super.key,
    required this.site,
    this.staticMapsApiKey,
  });

  @override
  Widget build(BuildContext context) {
    final mapUrl = (staticMapsApiKey == null)
        ? null
        : buildStaticMapUrl(
      lat: site.lat,
      lng: site.lng,
      apiKey: staticMapsApiKey!,
      width: 800,   // lebih tajam
      height: 240,  // lebih tinggi
      scale: 2,
      zoom: 15,
    );

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      clipBehavior: Clip.antiAlias, // agar radius juga memotong thumbnail
      child: InkWell(
        onTap: () => openInMaps(lat: site.lat, lng: site.lng, label: site.name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail peta di atas
            if (mapUrl != null)
              Image.network(
                mapUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _mapPlaceholder(),
              )
            else
              _mapPlaceholder(),

            // Detail lokasi
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58, height: 58,
                  color: const Color(0xFFE8EEE6),
                  child: Image.network(
                    site.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                site.name,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.kText),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Text(
                    site.hours,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              trailing: const Icon(Icons.directions, color: AppColors.kGreen),
              isThreeLine: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPlaceholder() => Container(
    height: 160,
    width: double.infinity,
    color: const Color(0xFFE8EEE6),
    child: const Center(
      child: Icon(Icons.map_outlined, color: AppColors.kGreen),
    ),
  );
}
