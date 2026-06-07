import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  @override
  _AdminCategoriesScreenState createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.getAdminCategories();
      setState(() => _categories = categories);
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kategori?'),
        content: Text('Kategori yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    bool success = await ApiService.deleteAdminCategory(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kategori berhasil dihapus")));
      _fetchCategories(); // Refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus kategori")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Kategori"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchCategories),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                // Sesuaikan URL gambar dengan URL server Laravel Anda
                String? imageUrl = cat['image'] != null 
                    ? "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/categories/${cat['image']}" 
                    : null;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                      child: imageUrl == null ? Icon(Icons.category) : null,
                    ),
                    title: Text(cat['name']),
                    subtitle: Text(cat['slug']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AdminCategoryFormScreen(category: cat)),
                            );
                            _fetchCategories(); // Refresh setelah kembali
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(cat['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminCategoryFormScreen()),
          );
          _fetchCategories(); // Refresh setelah kembali
        },
        child: Icon(Icons.add),
        tooltip: "Tambah Kategori",
      ),
    );
  }
}