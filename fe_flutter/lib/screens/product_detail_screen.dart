import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isAddingToCart = false;
  
  // --- State untuk Wishlist ---
  bool isWishlisted = false;
  bool isWishlistLoading = false;

  // --- State untuk Variasi Terpilih ---
  ProductVariation? selectedVariation;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    if (ApiService.token == null) return;
    try {
      final wishlist = await ApiService.getWishlist();
      if (mounted) {
        setState(() {
          isWishlisted = wishlist.any((item) => item.id == widget.product.id);
        });
      }
    } catch (e) {
      print("Gagal memuat status wishlist: $e");
    }
  }

  Future<void> _toggleWishlist() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login di menu Akun untuk menggunakan Wishlist")),
      );
      return;
    }

    setState(() => isWishlistLoading = true);
    bool success;
    if (isWishlisted) {
      success = await ApiService.removeFromWishlist(widget.product.id);
      if (success) {
        setState(() => isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dihapus dari Wishlist")));
      }
    } else {
      success = await ApiService.addToWishlist(widget.product.id);
      if (success) {
        setState(() => isWishlisted = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil ditambahkan ke Wishlist")));
      }
    }
    setState(() => isWishlistLoading = false);
  }

  Future<void> _addToCart() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login di menu Akun terlebih dahulu")),
      );
      return;
    }

    int currentStock = selectedVariation != null ? selectedVariation!.quantity : widget.product.quantity;

    if (currentStock <= 0 || widget.product.stockStatus != 'instock') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maaf, stok produk/variasi ini sedang kosong")),
      );
      return;
    }

    // Jika produk memiliki variasi, pastikan pembeli memilih salah satu sebelum add to cart
    if (widget.product.variations != null && widget.product.variations!.isNotEmpty && selectedVariation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih variasi produk terlebih dahulu")),
      );
      return;
    }

    setState(() => isAddingToCart = true);

    // Kirim product id dan quantity ke cart (Anda bisa memodifikasi API nanti jika variasi_id dibutuhkan)
    bool success = await ApiService.addToCart(widget.product.id, quantity);

    setState(() => isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk berhasil ditambahkan ke keranjang!")));
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menambahkan ke keranjang")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // LOGIKA PERHITUNGAN DINAMIS (Utama VS Variasi)
    // ==========================================
    
    // 1. Tentukan Harga Tampil (Variasi vs Utama)
    double displayPrice = selectedVariation != null
        ? (selectedVariation!.salePrice ?? selectedVariation!.regularPrice)
        : (widget.product.salePrice ?? widget.product.price);

    // 2. Tentukan Stok Tampil
    int displayStock = selectedVariation != null
        ? selectedVariation!.quantity
        : widget.product.quantity;

    // 3. Tentukan Berat Tampil
    int displayWeight = selectedVariation != null
        ? selectedVariation!.weight
        : 0; // Atur 0 jika produk utama tidak menyertakan response weight di modelnya

    // 4. Tentukan Gambar Tampil
    String? displayImage = selectedVariation?.image != null
        ? "http://127.0.0.1:8000/uploads/products/${selectedVariation!.image}"
        : (widget.product.image != null ? "http://127.0.0.1:8000/uploads/products/${widget.product.image}" : null);

    // Cek apakah produk / variasi habis
    bool isOutOfStock = displayStock <= 0 || widget.product.stockStatus != 'instock';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Detail Produk", style: TextStyle(color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          isWishlistLoading 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.black87,
                    size: 28,
                  ),
                  onPressed: _toggleWishlist,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GAMBAR PRODUK ---
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              child: displayImage != null
                  ? Image.network(
                      displayImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // --- 2. INFORMASI PRODUK ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Rp ${displayPrice.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(height: 16),

                  // Stok & Berat Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isOutOfStock ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          !isOutOfStock ? "Tersedia: $displayStock" : "Stok Habis",
                          style: TextStyle(
                            color: !isOutOfStock ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (displayWeight > 0)
                        Row(
                          children: [
                            const Icon(Icons.scale, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text("$displayWeight Gram", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
                          ],
                        ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // ==========================================
                  // 3. PILIHAN VARIASI PRODUK (WIDGET CHIP)
                  // ==========================================
                  if (widget.product.variations != null && widget.product.variations!.isNotEmpty) ...[
                    const Text("Pilih Variasi Produk:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: widget.product.variations!.map((variation) {
                        bool isSelected = selectedVariation == variation;
                        return ChoiceChip(
                          label: Text(variation.name, style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          )),
                          selected: isSelected,
                          selectedColor: Colors.deepOrange,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedVariation = selected ? variation : null;
                              quantity = 1; // Reset jumlah pesanan jika variasi diganti
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 40, thickness: 1),
                  ],

                  // --- 4. DESKRIPSI ---
                  const Text("Deskripsi Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description ?? 'Tidak ada deskripsi tersedia.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, -1), blurRadius: 10),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Pengatur Jumlah (Quantity)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (quantity < displayStock) {
                          setState(() => quantity++);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Batas maksimal stok tercapai!")));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Tombol Tambah ke Keranjang
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (isAddingToCart || isOutOfStock) ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isOutOfStock ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: isAddingToCart 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      isAddingToCart ? "Menambahkan..." : "Tambah ke Keranjang",
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}