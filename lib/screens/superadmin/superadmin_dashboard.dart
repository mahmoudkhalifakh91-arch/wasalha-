import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../services/push_service.dart';
import '../../theme/app_theme.dart';
import 'villages_tab.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    PushService.instance.init(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const ['الإحصائيات', 'المستخدمين', 'المطاعم', 'إدارة المنوفية'];
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة العليا')),
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
                              fontSize: 10,
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
              children: const [_StatsTab(), _UsersTab(), _RestaurantsTab(), VillagesTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: FirebaseService.instance.allUsersStream(),
      builder: (context, usersSnap) {
        return StreamBuilder<List<Order>>(
          stream: FirebaseService.instance.allOrdersStream(),
          builder: (context, ordersSnap) {
            final users = usersSnap.data ?? [];
            final orders = ordersSnap.data ?? [];
            final systemBalance =
                users.fold<double>(0, (sum, u) => sum + u.wallet.balance);
            final driversCount = users.where((u) => u.role == UserRole.DRIVER).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      label: 'رصيد المنظومة',
                      value: '${systemBalance.toStringAsFixed(0)} ج.م',
                      color: AppColors.primary,
                      textColor: Colors.white,
                    ),
                    _StatCard(
                      label: 'إجمالي المستخدمين',
                      value: '${users.length}',
                      color: Colors.white,
                      textColor: Colors.black87,
                    ),
                    _StatCard(
                      label: 'كباتن المنوفية',
                      value: '$driversCount',
                      color: Colors.white,
                      textColor: AppColors.primary,
                    ),
                    _StatCard(
                      label: 'الرحلات المنفذة',
                      value: '${orders.length}',
                      color: Colors.black87,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('طلبات سحب الأرباح المعلّقة',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                const _PendingWithdrawalsList(),
              ],
            );
          },
        );
      },
    );
  }
}

class _PendingWithdrawalsList extends StatelessWidget {
  const _PendingWithdrawalsList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.pendingWithdrawalsStream(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text('لا توجد طلبات سحب معلّقة', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: items.map((w) {
            final amount = (w['amount'] as num).toDouble();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['driverName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${amount.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(
                                  color: AppColors.primaryDark, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => FirebaseService.instance.rejectWithdrawal(w['id']),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () => FirebaseService.instance
                          .approveWithdrawal(w['id'], w['driverId'], amount),
                      child: const Text('تحويل'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  const _StatCard(
      {required this.label, required this.value, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textColor.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: FirebaseService.instance.allUsersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final users = snap.data!
            .where((u) =>
                u.name.toLowerCase().contains(search.toLowerCase()) || u.phone.contains(search))
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'بحث عن اسم أو موبايل...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _UserCard(user: users[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final approved = user.status == UserStatus.APPROVED;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(user.name.isNotEmpty ? user.name[0] : '؟'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(user.phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(enumToStr(user.role), style: const TextStyle(fontSize: 10)),
                backgroundColor:
                    user.role == UserRole.DRIVER ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade200,
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(enumToStr(user.status), style: const TextStyle(fontSize: 10)),
                backgroundColor: approved ? Colors.blue.withOpacity(0.12) : Colors.amber.withOpacity(0.2),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (user.role == UserRole.DRIVER && !approved)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => FirebaseService.instance
                        .updateUserStatus(user.id, UserStatus.APPROVED),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('موافقة', style: TextStyle(fontSize: 12)),
                  ),
                ),
              if (user.role == UserRole.DRIVER && !approved) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => FirebaseService.instance.updateUserRole(
                      user.id, user.role == UserRole.DRIVER ? UserRole.CUSTOMER : UserRole.DRIVER),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  child: const Text('تغيير الرتبة', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantsTab extends StatefulWidget {
  const _RestaurantsTab();

  @override
  State<_RestaurantsTab> createState() => _RestaurantsTabState();
}

class _RestaurantsTabState extends State<_RestaurantsTab> {
  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  bool adding = false;

  Future<void> _save() async {
    if (nameCtrl.text.trim().isEmpty) return;
    await FirebaseService.instance
        .createRestaurant(nameCtrl.text.trim(), categoryCtrl.text.trim());
    nameCtrl.clear();
    categoryCtrl.clear();
    setState(() => adding = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: FirebaseService.instance.allRestaurantsStream(),
      builder: (context, snap) {
        final restaurants = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إدارة المطاعم',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ElevatedButton.icon(
                  onPressed: () => setState(() => adding = !adding),
                  icon: Icon(adding ? Icons.close : Icons.add),
                  label: Text(adding ? 'إلغاء' : 'إضافة مطعم'),
                ),
              ],
            ),
            if (adding) ...[
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المطعم'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'التصنيف (بيتزا، مشويات...)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _save, child: const Text('حفظ البيانات')),
            ],
            const SizedBox(height: 18),
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (restaurants.isEmpty)
              const Center(child: Text('لا يوجد مطاعم مضافة لسه'))
            else
              ...restaurants.map((r) => _RestaurantCard(restaurant: r)),
          ],
        );
      },
    );
  }
}

class _RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard> {
  final itemNameCtrl = TextEditingController();
  final itemPriceCtrl = TextEditingController();

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المطعم؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await FirebaseService.instance.deleteRestaurant(widget.restaurant.id);
  }

  Future<void> _addItem() async {
    final price = double.tryParse(itemPriceCtrl.text.trim());
    if (itemNameCtrl.text.trim().isEmpty || price == null || price <= 0) return;
    await FirebaseService.instance.addMenuItem(
        widget.restaurant.id, widget.restaurant.menu, itemNameCtrl.text.trim(), price);
    itemNameCtrl.clear();
    itemPriceCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.08)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    Text(r.category, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: r.isOpen,
                activeColor: AppColors.primary,
                onChanged: (v) => FirebaseService.instance.toggleRestaurantOpen(r.id, v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('الوجبات (${r.menu.length})',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...r.menu.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => FirebaseService.instance
                          .removeMenuItem(r.id, r.menu, item.id),
                      icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text('${item.price.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: itemNameCtrl,
                  decoration: const InputDecoration(
                      hintText: 'اسم الوجبة', isDense: true, contentPadding: EdgeInsets.all(10)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: itemPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'السعر', isDense: true, contentPadding: EdgeInsets.all(10)),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                child: const Text('إضافة', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
