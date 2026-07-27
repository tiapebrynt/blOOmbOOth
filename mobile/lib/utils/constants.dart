/// ======================================================================
/// AppConstants
/// ======================================================================
///
/// Class ini digunakan untuk menyimpan seluruh konstanta (constant values)
/// yang digunakan oleh aplikasi.
///
/// Dengan menyimpan nilai-nilai penting pada satu tempat,
/// aplikasi menjadi lebih mudah dikelola dan dipelihara.
///
/// Contohnya:
/// - Base URL API
/// - Base URL penyimpanan gambar
/// - Konstanta lain yang akan digunakan bersama di berbagai file.
///
/// Karena seluruh variabel menggunakan keyword `static const`,
/// nilainya bersifat tetap (immutable) dan dapat diakses langsung
/// tanpa perlu membuat object AppConstants.
class AppConstants {

  /// ==================================================================
  /// Base URL API
  /// ==================================================================
  ///
  /// URL dasar yang digunakan aplikasi untuk berkomunikasi
  /// dengan Backend API.
  ///
  /// Seluruh request HTTP seperti GET, POST, PUT, dan DELETE
  /// akan menggunakan alamat ini sebagai endpoint utama.
  ///
  /// Contoh penggunaan:
  ///
  /// ApiClient.get('${AppConstants.baseUrl}/frames');
  ///
  /// Nilai URL harus disesuaikan dengan environment yang digunakan:
  ///
  /// - Emulator Android
  ///     http://10.0.2.2:3000/api
  ///
  /// - Device fisik (WiFi yang sama)
  ///     http://<IP-LAPTOP-KAMU>:3000/api
  ///
  /// - Backend Online / Hosting
  ///     https://domain-kamu.com/api
  static const String baseUrl = 'http://172.16.11.173:3000/api';

  /// ==================================================================
  /// Storage URL
  /// ==================================================================
  ///
  /// URL dasar yang digunakan untuk mengambil file statis,
  /// seperti gambar frame, thumbnail, maupun file upload lainnya.
  ///
  /// Berbeda dengan baseUrl, URL ini tidak menggunakan "/api"
  /// karena langsung mengarah ke folder penyimpanan (uploads)
  /// yang disediakan oleh backend.
  ///
  /// Contoh penggunaan:
  ///
  /// Image.network(
  ///   '${AppConstants.storageUrl}/uploads/frame.png',
  /// );
  static const String storageUrl = 'http://172.16.11.173:3000';
}