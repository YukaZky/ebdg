import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'address_form_screen.dart'; // Nanti kita buat file ini

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({Key? key}) : super(key: key);
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
    await ApiService.setMainAddress(id);
    _fetchAddresses(); // Segarkan dari database agar 100% presisi
  }

  Future<void> _deleteAddress(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hapus Alamat?"),
        content: const Text("Yakin ingin menghapus alamat ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

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
        title: const Text('Alamat Saya', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C2442)))
        : addresses.isEmpty 
          ? const Center(child: Text("Belum ada alamat tersimpan."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                
                // PERBAIKAN: Menangani tipe String, Integer, Boolean dan berbagai nama key dari backend
                bool isMain = addr['isdefault'] == 1 || addr['isdefault'] == '1' || addr['isdefault'] == true ||
                              addr['is_main'] == 1 || addr['is_main'] == '1' || addr['is_main'] == true;
                              
                bool isStore = addr['is_store_address'] == 1 || addr['is_store_address'] == '1' || addr['is_store_address'] == true ||
                               addr['is_store'] == 1 || addr['is_store'] == '1' || addr['is_store'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMain ? const Color(0xFFF39C12) : Colors.grey.shade300, width: isMain ? 1.5 : 1),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
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
                                Text(addr['label'] ?? 'Rumah', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                                if (isMain) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFF39C12).withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFF39C12))),
                                    child: const Text('Utama', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD35400))),
                                  ),
                                ],
                                if (isStore) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue)),
                                    child: const Text('Alamat Toko', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("${addr['name']} | ${addr['phone']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("${addr['address']}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 2),
                            Text("${addr['locality']}, Kode Pos: ${addr['postal_code']}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => !isMain ? _setMain(addr['id']) : null,
                              child: Row(
                                children: [
                                  Icon(isMain ? Icons.check_circle : Icons.radio_button_unchecked, color: isMain ? const Color(0xFFF39C12) : Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text("Jadikan Alamat Utama", style: TextStyle(fontSize: 12, color: isMain ? Colors.black87 : Colors.grey)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddressFormScreen(existingAddress: addr))).then((_) => _fetchAddresses());
                              },
                              child: const Text("Ubah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0C2442))),
                            ),
                            const SizedBox(width: 20),
                            InkWell(
                              onTap: () => _deleteAddress(addr['id']),
                              child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                            ),
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
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39C12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text('TAMBAH ALAMAT BARU', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressFormScreen())).then((_) => _fetchAddresses());
              },
            ),
          ),
        ),
      ),
    );
  }
}