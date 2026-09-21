import 'package:flutter/material.dart';
import '../../data/menofia_data.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

/// تبويب "إدارة المنوفية" - عرض مراكز وقرى المحافظة، وتحميلها لقاعدة بيانات
/// Firestore (مجموعة zones) عشان تُستخدم في تحديد مناطق التوصيل والتسعير.
class VillagesTab extends StatefulWidget {
  const VillagesTab({super.key});

  @override
  State<VillagesTab> createState() => _VillagesTabState();
}

class _VillagesTabState extends State<VillagesTab> {
  bool seedingAll = false;
  String? seedingDistrictId;

  Future<void> _seedDistrict(DistrictData d) async {
    setState(() => seedingDistrictId = d.id);
    try {
      final villages = d.villages
          .map((v) => {
                'id': v.id,
                'name': v.name,
                'center': {'lat': v.lat, 'lng': v.lng},
              })
          .toList();
      await FirebaseService.instance.seedDistrict(d.id, d.name, villages);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم تحميل مركز ${d.name} بنجاح')));
      }
    } finally {
      if (mounted) setState(() => seedingDistrictId = null);
    }
  }

  Future<void> _seedAll() async {
    setState(() => seedingAll = true);
    try {
      for (final d in menofiaDistricts) {
        final villages = d.villages
            .map((v) => {
                  'id': v.id,
                  'name': v.name,
                  'center': {'lat': v.lat, 'lng': v.lng},
                })
            .toList();
        await FirebaseService.instance.seedDistrict(d.id, d.name, villages);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحميل كل مراكز المنوفية وقراها بنجاح')));
      }
    } finally {
      if (mounted) setState(() => seedingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Zone>>(
      stream: FirebaseService.instance.zonesStream(),
      builder: (context, snap) {
        final loadedIds = (snap.data ?? []).map((z) => z.id).toSet();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('مراكز وقرى محافظة المنوفية',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                ElevatedButton.icon(
                  onPressed: seedingAll ? null : _seedAll,
                  icon: seedingAll
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('تحميل الكل'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'كل المراكز التسعة محمّلة بقراها بالكامل (${menofiaDistricts.fold<int>(0, (s, d) => s + d.villages.length)} قرية إجمالاً)، ومركز أشمون هو المركز الأساسي للتطبيق.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...menofiaDistricts.map((d) {
              final loaded = loadedIds.contains(d.id);
              final isMain = d.id == 'd-ashmoun';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isMain ? AppColors.primary.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: isMain ? Border.all(color: AppColors.primary, width: 1.5) : null,
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Row(
                    children: [
                      Icon(isMain ? Icons.star : Icons.location_city,
                          color: isMain ? Colors.amber.shade700 : AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      if (loaded)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                    ],
                  ),
                  subtitle: Text('${d.villages.length} قرية'),
                  children: [
                    ...d.villages.map((v) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 18, color: Colors.grey),
                          title: Text(v.name, style: const TextStyle(fontSize: 13)),
                          trailing: Text('${v.lat.toStringAsFixed(3)}, ${v.lng.toStringAsFixed(3)}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: seedingDistrictId == d.id ? null : () => _seedDistrict(d),
                          icon: seedingDistrictId == d.id
                              ? const SizedBox(
                                  height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(loaded ? Icons.refresh : Icons.cloud_upload_outlined, size: 16),
                          label: Text(loaded ? 'إعادة تحميل هذا المركز' : 'تحميل هذا المركز'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
