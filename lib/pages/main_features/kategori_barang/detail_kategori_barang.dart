import 'package:flutter/material.dart';

class DetailKategoriBarangPage extends StatelessWidget {
  final Map<String, dynamic> kategoriData;

  const DetailKategoriBarangPage({super.key, required this.kategoriData});

  static const cucumberGreen = Color(0xFF85A947);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF123524),
                      Color(0xFF3E7B27),
                      Color(0xFF85A947),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(512),
                    bottomRight: Radius.circular(512),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            kategoriData['nama'] ?? 'Detail Kategori',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Container gambar produk
                    Container(
                      width: 280,
                      height: 280,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 0), 
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                color: const Color.fromARGB(0, 250, 250, 250),
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Nilai Tukar : ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: kategoriData['harga'] ?? '0 Pts/Kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cucumberGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Fun Fact Section
                    const Text(
                      'Fun Fact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fun Facts List
                    _buildFunFactItem(
                      'Mayoritas botol plastik terbuat dari PET (Polyethylene Terephthalate).',
                    ),
                    _buildFunFactItem(
                      'Butuh waktu sekitar 450 tahun untuk terurai di alam.',
                    ),
                    _buildFunFactItem(
                      'Lebih dari 500 miliar botol plastik diproduksi setiap tahun.',
                    ),
                    _buildFunFactItem(
                      '90% botol plastik dipakai sekali lalu dibuang.',
                    ),
                    _buildFunFactItem(
                      'Termasuk sampah paling banyak ditemukan di laut.',
                    ),
                    _buildFunFactItem(
                      'Saat terurai menghasilkan mikroplastik yang masuk rantai makanan.',
                    ),
                    _buildFunFactItem(
                      'Produksinya butuh 3 liter air + ¼ liter minyak untuk 1 botol ukuran 1 liter.',
                    ),
                    _buildFunFactItem(
                      'PET mudah didaur ulang jadi botol baru, serat kain, atau karpet.',
                    ),

                    const SizedBox(height: 32),

                    // Statistik Penukaranmu Section
                    const Text(
                      'Statistik Penukaranmu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Statistik Value
                    const Text(
                      '2.0 Kg',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: cucumberGreen,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunFactItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}