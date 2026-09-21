import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class OperatorDashboard extends StatefulWidget {
  final AppUser user;
  const OperatorDashboard({super.key, required this.user});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = const ['النشاط الحالي', 'الكباتن', 'السجل العام'];
    return Scaffold(
      appBar: AppBar(title: const Text('تحكم أشمون')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = tab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => tab = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.black87 : AppColors.bg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : Colors.black54)),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: const [_LiveOrdersTab(), _DriversTab(), _HistoryTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrdersTab extends StatelessWidget {
  const _LiveOrdersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.instance.allOrdersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final live = snap.data!
            .where((o) => o.status != OrderStatus.DELIVERED && o.status != OrderStatus.CANCELLED)
            .toList();
        if (live.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('لا توجد رحلات نشطة في أشمون حالياً',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: live.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _LiveOrderCard(order: live[i]),
        );
      },
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  final Order order;
  const _LiveOrderCard({required this.order});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الطلب؟'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await FirebaseService.instance.cancelOrder(order.id);
  }

  Future<void> _openAssignSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AssignDriverSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDriver = order.driverId != null;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasDriver ? AppColors.primary : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(enumToStr(order.status),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
                Text('${order.price.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${order.pickup.address} ← ${order.dropoff.address}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(order.notes!, style: const TextStyle(fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: hasDriver
                          ? ElevatedButton.icon(
                              onPressed: () => _call(order.driverPhone!),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('اتصال بالكابتن'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                            )
                          : ElevatedButton(
                              onPressed: () => _openAssignSheet(context),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                              child: const Text('توجيه كابتن فورًا'),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _cancel(context),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.08)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignDriverSheet extends StatelessWidget {
  final Order order;
  const _AssignDriverSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) {
        return FutureBuilder<List<AppUser>>(
          future: FirebaseService.instance.approvedDrivers(),
          builder: (context, snap) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('توجيه كابتن يدويًا',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  if (!snap.hasData)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (snap.data!.isEmpty)
                    const Expanded(
                        child: Center(child: Text('لا يوجد كباتن متاحين حالياً')))
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: snap.data!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final d = snap.data![i];
                          return ListTile(
                            tileColor: AppColors.bg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            leading: CircleAvatar(
                              backgroundColor: Colors.black87,
                              child: Text(d.name.isNotEmpty ? d.name[0] : 'ك',
                                  style: const TextStyle(color: AppColors.primary)),
                            ),
                            title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                                d.vehicleType != null ? enumToStr(d.vehicleType!) : 'توكتوك'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () async {
                              await FirebaseService.instance.assignDriverManually(order.id, d);
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DriversTab extends StatefulWidget {
  const _DriversTab();

  @override
  State<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<_DriversTab> {
  String search = '';

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: FirebaseService.instance.allDriversStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final drivers = snap.data!.where((d) => d.name.contains(search)).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'بحث عن كابتن...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: drivers.isEmpty
                  ? const Center(child: Text('لا يوجد كباتن'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = drivers[i];
                        final approved = d.status == UserStatus.APPROVED;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Text(d.name.isNotEmpty ? d.name[0] : 'ك',
                                    style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.name,
                                        style: const TextStyle(fontWeight: FontWeight.w800)),
                                    Text(d.phone,
                                        style:
                                            const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: approved ? AppColors.primary : Colors.red),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(enumToStr(d.status),
                                            style: const TextStyle(
                                                fontSize: 10, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _call(d.phone),
                                icon: const Icon(Icons.call),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.instance.allOrdersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final done = snap.data!
            .where((o) => o.status == OrderStatus.DELIVERED || o.status == OrderStatus.CANCELLED)
            .toList();
        if (done.isEmpty) return const Center(child: Text('مفيش طلبات في السجل لسه'));
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: done.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final o = done[i];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              leading: Icon(
                o.status == OrderStatus.DELIVERED ? Icons.check_circle : Icons.cancel,
                color: o.status == OrderStatus.DELIVERED ? AppColors.primary : Colors.red,
              ),
              title: Text('${o.pickup.address} ← ${o.dropoff.address}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(o.driverName ?? 'بدون كابتن'),
              trailing: Text('${o.price.toStringAsFixed(0)} ج.م'),
            );
          },
        );
      },
    );
  }
}
