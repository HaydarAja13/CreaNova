import 'package:flutter/material.dart';
import '../../../models/trash_category.dart';

class DetailKategoriBarangPage extends StatelessWidget {
  final TrashCategory category;

  const DetailKategoriBarangPage({
    super.key, 
    required this.category,
  });

  // Backward compatibility constructor
  DetailKategoriBarangPage.fromMap({
    super.key,
    required Map<String, dynamic> kategoriData,
  }) : category = TrashCategory(
          id: 0,
          categoryName: kategoriData['nama'] ?? 'Unknown',
          point: int.tryParse(kategoriData['harga']?.toString().replaceAll(RegExp(r'[^\d]'), '') ?? '0') ?? 0,
          stock: 100,
          totalBalance: 1000,
          status: 'T',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

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
                            category.categoryName,
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
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: category.imageUrl != null
                                ? Image.network(
                                    category.imageUrl!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.green,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
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
                              text: category.formattedPrice,
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
                    ..._getFunFacts(category.categoryName).map((fact) => _buildFunFactItem(fact)),

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
                    Text(
                      '${(category.totalBalance / 1000).toStringAsFixed(1)} Kg',
                      style: const TextStyle(
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

  List<String> _getFunFacts(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'plastik':
      case 'botol plastik':
        return [
          'Mayoritas botol plastik terbuat dari PET (Polyethylene Terephthalate).',
          'Butuh waktu sekitar 450 tahun untuk terurai di alam.',
          'Lebih dari 500 miliar botol plastik diproduksi setiap tahun.',
          '90% botol plastik dipakai sekali lalu dibuang.',
          'Termasuk sampah paling banyak ditemukan di laut.',
          'Saat terurai menghasilkan mikroplastik yang masuk rantai makanan.',
          'Produksinya butuh 3 liter air + ¼ liter minyak untuk 1 botol ukuran 1 liter.',
          'PET mudah didaur ulang jadi botol baru, serat kain, atau karpet.',
        ];
      case 'kertas':
      case 'kardus':
      case 'koran':
        return [
          'Kertas dapat didaur ulang hingga 5-7 kali sebelum seratnya rusak.',
          'Daur ulang 1 ton kertas dapat menyelamatkan 17 pohon dewasa.',
          'Proses daur ulang kertas menggunakan 60% lebih sedikit energi.',
          'Kertas terurai dalam 2-6 minggu di lingkungan yang tepat.',
          'Indonesia menghasilkan 64 juta ton sampah kertas per tahun.',
          'Kertas bekas dapat dijadikan tissue, kertas tulis, atau kardus baru.',
          'Industri kertas adalah penyumbang polusi air terbesar ketiga.',
          'Daur ulang kertas mengurangi emisi gas rumah kaca hingga 74%.',
        ];
      case 'kaca':
      case 'botol kaca':
        return [
          'Kaca dapat didaur ulang 100% tanpa kehilangan kualitas.',
          'Kaca tidak pernah aus dan dapat didaur ulang berkali-kali.',
          'Daur ulang kaca menghemat energi hingga 30%.',
          'Kaca butuh waktu 1 juta tahun untuk terurai di alam.',
          'Setiap ton kaca daur ulang menghemat 1,2 ton bahan baku.',
          'Proses daur ulang kaca mengurangi polusi udara hingga 20%.',
          'Kaca daur ulang meleleh pada suhu lebih rendah dari bahan baku.',
          'Indonesia menghasilkan 700 ribu ton sampah kaca per tahun.',
        ];
      case 'logam':
      case 'kaleng':
      case 'kaleng besi':
        return [
          'Aluminium dapat didaur ulang tanpa batas tanpa kehilangan kualitas.',
          'Daur ulang aluminium menghemat energi hingga 95%.',
          'Kaleng aluminium dapat kembali ke rak toko dalam 60 hari.',
          'Besi dan baja adalah material paling banyak didaur ulang di dunia.',
          'Daur ulang logam mengurangi emisi CO2 hingga 58%.',
          'Setiap ton baja daur ulang menghemat 1,1 ton bijih besi.',
          'Logam tidak pernah kehilangan sifat magnetiknya saat didaur ulang.',
          'Industri daur ulang logam menyerap 500 ribu pekerja di Indonesia.',
        ];
      default:
        return [
          'Sampah organik dapat diolah menjadi kompos dalam 3-6 bulan.',
          'Kompos dapat meningkatkan kesuburan tanah hingga 40%.',
          'Sampah organik menyumbang 60% dari total sampah rumah tangga.',
          'Proses pengomposan mengurangi volume sampah hingga 50%.',
          'Kompos mengandung nutrisi penting untuk pertumbuhan tanaman.',
          'Pengomposan mengurangi emisi gas metana dari TPA.',
          'Sampah daun dapat diolah menjadi pupuk organik berkualitas tinggi.',
          'Kompos membantu tanah menyerap dan menyimpan air lebih baik.',
        ];
    }
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