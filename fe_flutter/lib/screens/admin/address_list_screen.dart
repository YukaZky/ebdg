import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'address_form_screen.dart'; // Nanti kita buat file ini

class AddressListScreen extends StatefulWidget {
  final bool storeSelectionMode;

  const AddressListScreen({Key? key, this.storeSelectionMode = false})
      : super(key: key);
  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<dynamic> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => isLoading = true);
    final data = await ApiService.getUserAddresses();
    if (mounted) {
      setState(() {
        addresses = data;
        isLoading = false;
      });
    }
  }

  Future<void> _setMain(int id) async {
    setState(() {
      for (var a in addresses) {
        a['isdefault'] = (a['id'] == id) ? 1 : 0;
      }
    });
    final success = await ApiService.setMainAddress(id);
    await _fetchAddresses();
    if (!mounted) return;
    if (success) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Gagal mengubah alamat utama."),
        backgroundColor: Colors.red));
  }

  Future<void> _setStore(int id) async {
    setState(() => isLoading = true);
    final success = await ApiService.setStoreAddress(id);
    await _fetchAddresses();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? "Lokasi toko berhasil diubah."
          : "Gagal mengubah lokasi toko."),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Future<void> _deleteAddress(int id, {required bool isStore}) async {
    bool confirm = await showDialog(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text("Hapus Alamat?"),
                  content: Text(isStore
                      ? "Alamat ini sedang dipakai sebagai lokasi toko. Menghapusnya akan mengosongkan lokasi toko."
                      : "Yakin ingin menghapus alamat ini?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text("Batal")),
                    TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.red))),
                  ],
                )) ??
        false;

    if (confirm) {
      setState(() => isLoading = true);
      await ApiService.deleteUserAddress(id);
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
            widget.storeSelectionMode ? 'Pilih Lokasi Toko' : 'Alamat Saya',
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C2442)))
          : addresses.isEmpty
              ? const Center(child: Text("Belum ada alamat tersimpan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _roleInfoCard();

                    final addr = addresses[index - 1];

                    // PERBAIKAN: Menangani tipe String, Integer, Boolean dan berbagai nama key dari backend
                    bool isMain = addr['isdefault'] == 1 ||
                        addr['isdefault'] == '1' ||
                        addr['isdefault'] == true ||
                        addr['is_main'] == 1 ||
                        addr['is_main'] == '1' ||
                        addr['is_main'] == true;

                    bool isStore = addr['store_owner_id'] != null ||
                        addr['is_store_address'] == 1 ||
                        addr['is_store_address'] == '1' ||
                        addr['is_store_address'] == true ||
                        addr['is_store'] == 1 ||
                        addr['is_store'] == '1' ||
                        addr['is_store'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMain
                              ? const Color(0xFFF39C12)
                              : (isStore ? Colors.blue : Colors.grey.shade300),
                          width: isMain || isStore ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(addr['label'] ?? 'Rumah',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black54)),
                                    if (isMain) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF39C12)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFF39C12))),
                                        child: const Text('Utama',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFD35400))),
                                      ),
                                    ],
                                    if (isStore) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border:
                                                Border.all(color: Colors.blue)),
                                        child: const Text('Alamat Toko',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue)),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text("${addr['name']} | ${addr['phone']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("${addr['address']}",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        height: 1.4)),
                                const SizedBox(height: 2),
                                Text(
                                    "${addr['district_name'] ?? addr['locality']}, ${addr['city_name']}, ${addr['province_name']} - ${addr['postal_code']}",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: isMain
                                          ? null
                                          : () => _setMain(addr['id']),
                                      child: Row(children: [
                                        Icon(
                                            isMain
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: isMain
                                                ? const Color(0xFFF39C12)
                                                : Colors.grey,
                                            size: 20),
                                        const SizedBox(width: 7),
                                        const Text("Alamat Utama",
                                            style: TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: isStore
                                          ? null
                                          : () => _setStore(addr['id']),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(
                                                isStore
                                                    ? Icons.store_rounded
                                                    : Icons.store_outlined,
                                                color: isStore
                                                    ? Colors.blue
                                                    : Colors.grey,
                                                size: 20),
                                            const SizedBox(width: 7),
                                            Text(
                                                isStore
                                                    ? "Lokasi Toko"
                                                    : "Jadikan Lokasi Toko",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: isStore
                                                        ? Colors.blue
                                                        : Colors.black87)),
                                          ]),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddressFormScreen(
                                                          existingAddress:
                                                              addr)))
                                          .then((_) => _fetchAddresses());
                                    },
                                    child: const Text("Ubah",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF0C2442))),
                                  ),
                                  const SizedBox(width: 20),
                                  InkWell(
                                    onTap: () => _deleteAddress(addr['id'],
                                        isStore: isStore),
                                    child: const Text("Hapus",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.red)),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text('TAMBAH ALAMAT BARU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddressFormScreen()))
                    .then((_) => _fetchAddresses());
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Alamat Utama dipakai sebagai tujuan checkout. Lokasi Toko dipakai sebagai asal pengiriman dan ongkir. Keduanya terpisah, tetapi boleh menunjuk alamat yang sama.',
              style: TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
