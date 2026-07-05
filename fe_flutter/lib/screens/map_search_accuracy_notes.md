# Map Search Accuracy Notes

Perbaikan pada branch ini:

- Pencarian lokasi memakai Nominatim OpenStreetMap terlebih dahulu, lalu fallback ke geocoder device.
- Query pencarian dibuat lebih pintar dengan normalisasi `Jl/Jln` menjadi `Jalan`, `No` menjadi `Nomor`, dan ditambah konteks wilayah toko.
- Jika ada beberapa hasil lokasi, admin bisa memilih hasil yang paling sesuai.
- Setelah hasil dipilih, peta zoom lebih dekat agar pin mudah digeser manual.
- Preview map pada form alamat toko dipaksa rebuild sesuai koordinat terbaru dan diberi pin tengah agar tidak menampilkan tile/lokasi lama.
