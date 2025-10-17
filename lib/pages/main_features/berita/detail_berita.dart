import 'package:flutter/material.dart';
import '../../../models/article_item.dart';

class DetailBeritaPage extends StatelessWidget {
  final ArticleItem article;

  const DetailBeritaPage({super.key, required this.article});

  static const primaryGreen = Color(0xFF3E7B27);
  static const lightGreen = Color(0xFF85A947);
  static const darkGreen = Color(0xFF123524);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar dengan gambar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryGreen,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image,
                      color: Colors.grey.shade500,
                      size: 64,
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Badge "Terbaru" jika artikel baru
                  if (article.isNew)
                    Positioned(
                      top: 100,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Terbaru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Konten artikel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul artikel
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Meta informasi
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source,
                          style: const TextStyle(
                            fontSize: 12,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  const SizedBox(height: 24),

                  // Konten artikel
                  Text(
                    _getArticleContent(article),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Call to action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryGreen.withValues(alpha: 0.1),
                          lightGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 48,
                          color: primaryGreen,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mari Bersama Jaga Lingkungan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai dari hal kecil untuk dampak yang besar bagi bumi kita',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getArticleContent(ArticleItem article) {
    // Generate konten artikel berdasarkan judul
    final title = article.title.toLowerCase();
    
    if (title.contains('memilah sampah')) {
      return '''Memilah sampah di rumah merupakan langkah awal yang sangat penting dalam pengelolaan sampah yang berkelanjutan. Dengan memilah sampah sejak dari sumber, kita dapat membantu mengurangi beban tempat pembuangan akhir dan meningkatkan efektivitas daur ulang.

Langkah pertama adalah menyediakan tempat sampah terpisah untuk berbagai jenis sampah. Minimal sediakan tiga tempat sampah: organik, anorganik, dan B3 (Bahan Berbahaya dan Beracun).

Sampah organik meliputi sisa makanan, daun, dan bahan-bahan yang mudah terurai. Sampah ini dapat diolah menjadi kompos yang berguna untuk tanaman.

Sampah anorganik seperti plastik, kertas, kaleng, dan kaca dapat didaur ulang menjadi produk baru. Pastikan untuk membersihkan wadah sebelum membuangnya.

Sampah B3 seperti baterai, lampu, dan obat-obatan memerlukan penanganan khusus karena dapat mencemari lingkungan jika tidak dikelola dengan benar.

Dengan memilah sampah, kita tidak hanya membantu lingkungan tetapi juga dapat memperoleh manfaat ekonomi melalui penjualan sampah yang dapat didaur ulang.''';
    } else if (title.contains('daur ulang plastik')) {
      return '''Daur ulang plastik memiliki manfaat yang sangat besar bagi lingkungan. Proses ini dapat mengurangi jumlah sampah plastik yang berakhir di tempat pembuangan akhir atau mencemari lautan.

Plastik membutuhkan waktu ratusan tahun untuk terurai secara alami. Dengan mendaur ulang, kita dapat mengubah sampah plastik menjadi produk baru yang berguna, seperti pakaian, tas, atau bahkan furniture.

Proses daur ulang plastik dimulai dengan pengumpulan dan pemilahan berdasarkan jenis plastik. Setiap jenis plastik memiliki kode angka 1-7 yang biasanya tertera di bagian bawah kemasan.

Setelah dipilah, plastik dicuci bersih untuk menghilangkan label dan sisa-sisa makanan. Kemudian plastik dihancurkan menjadi serpihan kecil yang disebut flakes.

Flakes plastik kemudian dilelehkan dan dibentuk menjadi pelet yang dapat digunakan sebagai bahan baku untuk membuat produk plastik baru.

Industri daur ulang plastik terus berkembang dengan teknologi yang semakin canggih, memungkinkan daur ulang plastik yang lebih efisien dan menghasilkan produk berkualitas tinggi.''';
    } else if (title.contains('mengurangi sampah plastik')) {
      return '''Mengurangi penggunaan plastik dalam kehidupan sehari-hari adalah salah satu cara paling efektif untuk mengatasi masalah sampah plastik. Setiap individu dapat berkontribusi dengan mengubah kebiasaan kecil yang berdampak besar.

Mulailah dengan membawa tas belanja sendiri saat berbelanja. Tas kain atau tas yang dapat digunakan berulang kali dapat menggantikan kantong plastik sekali pakai.

Gunakan botol minum dan tempat makan yang dapat digunakan berulang. Investasi kecil ini dapat menghemat ratusan botol dan wadah plastik dalam setahun.

Pilih produk dengan kemasan minimal atau kemasan yang dapat didaur ulang. Banyak merek sekarang menawarkan alternatif kemasan yang lebih ramah lingkungan.

Hindari penggunaan sedotan plastik dan peralatan makan sekali pakai. Bawa peralatan makan sendiri atau pilih alternatif yang terbuat dari bahan alami.

Dukung bisnis dan produk yang berkomitmen mengurangi penggunaan plastik. Pilihan konsumen dapat mendorong perubahan positif di industri.

Edukasi keluarga dan teman tentang pentingnya mengurangi sampah plastik. Perubahan kolektif dimulai dari kesadaran individu.''';
    } else {
      return '''${article.title} merupakan topik yang sangat penting dalam upaya pelestarian lingkungan dan pengelolaan sampah yang berkelanjutan.

Artikel ini membahas berbagai aspek yang berkaitan dengan pengelolaan sampah, daur ulang, dan upaya pelestarian lingkungan. Setiap langkah kecil yang kita lakukan dapat memberikan dampak positif yang besar bagi lingkungan.

Pengelolaan sampah yang baik dimulai dari kesadaran setiap individu untuk bertanggung jawab terhadap sampah yang dihasilkan. Dengan memilah, mengurangi, dan mendaur ulang sampah, kita dapat berkontribusi dalam menjaga kelestarian bumi.

Teknologi dan inovasi terus berkembang untuk mendukung pengelolaan sampah yang lebih efektif. Namun, peran serta masyarakat tetap menjadi kunci utama keberhasilan program pengelolaan sampah.

Mari bersama-sama membangun kesadaran dan mengambil tindakan nyata untuk menciptakan lingkungan yang lebih bersih dan sehat untuk generasi mendatang.

Setiap tindakan kecil yang kita lakukan hari ini akan berdampak besar bagi masa depan bumi kita. Mulailah dari diri sendiri, keluarga, dan lingkungan sekitar.''';
    }
  }
}