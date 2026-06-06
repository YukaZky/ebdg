import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    final data = await ApiService.getAdminProducts();
    setState(() {
      products = data;
      isLoading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    bool success = await ApiService.deleteAdminProduct(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk berhasil dihapus")));
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus produk")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Produk"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Navigasi ke Form Tambah Produk Baru
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("Tidak ada produk tersedia."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.shopping_bag, color: Colors.white)),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Stok: ${item['quantity']} | Rp ${item['regular_price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Apakah Anda yakin ingin menghapus produk ini secara permanen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}