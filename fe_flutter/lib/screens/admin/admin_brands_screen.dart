import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_brand_form_screen.dart';

class AdminBrandsScreen extends StatefulWidget {
  @override
  _AdminBrandsScreenState createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  List<dynamic> _brands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoading = true);
    try {
      final brands = await ApiService.getAdminBrands();
      setState(() => _brands = brands);
    } catch (e) {
      print("Error fetching brands: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBrand(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Brand?'),
        content: Text('Brand yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    bool success = await ApiService.deleteAdminBrand(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Brand berhasil dihapus")));
      _fetchBrands(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus brand")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Brand"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchBrands),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final brand = _brands[index];
                String? imageUrl = brand['image'] != null 
                    ? "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/brands/${brand['image']}" 
                    : null;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                      child: imageUrl == null ? Icon(Icons.branding_watermark) : null,
                    ),
                    title: Text(brand['name']),
                    subtitle: Text(brand['slug']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => AdminBrandFormScreen(brand: brand)));
                            _fetchBrands(); 
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBrand(brand['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => AdminBrandFormScreen()));
          _fetchBrands(); 
        },
        child: Icon(Icons.add),
        tooltip: "Tambah Brand",
      ),
    );
  }
}