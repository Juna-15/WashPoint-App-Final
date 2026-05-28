import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../main.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _logout() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar Akun?'),
            content: const Text(
              'Anda harus masuk kembali untuk memesan layanan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _editProfileName() async {
    TextEditingController nameController = TextEditingController(
      text: currentUser?.displayName,
    );

    bool? save = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Edit Nama Profil',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Masukkan nama baru',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryAqua),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: AppColors.primaryAqua,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (save == true && nameController.text.trim().isNotEmpty) {
      try {
        await currentUser?.updateDisplayName(nameController.text.trim());
        await currentUser?.reload();
        setState(() {}); // Segarkan UI
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    Color subTextColor = isDarkMode
        ? Colors.grey.shade400
        : AppColors.textSubtitle;
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color dividerColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade100;

    String displayName =
        currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'Pengguna';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: isDarkMode
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryAqua,
                          child: Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,

                        child: GestureDetector(
                          onTap: _editProfileName,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    currentUser?.email ?? 'Tidak ada email',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black26
                          : const Color(0xFFD6EEFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'MEMBER ELITE',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAqua,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            Row(
              children: [
                _buildStatCard(
                  'Total Cuci',
                  '12',
                  Icons.local_car_wash_outlined,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  'Poin',
                  '2,450',
                  Icons.workspace_premium_outlined,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              ],
            ),
            const SizedBox(height: 35),

            _buildSectionTitle('AKUN & LAYANAN', subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.directions_car_outlined,
                    'Garasi Kendaraan Saya',
                    textColor,
                    () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: dividerColor,
                  ),
                  _buildMenuItem(
                    Icons.history_outlined,
                    'Riwayat Transaksi',
                    textColor,
                    () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: dividerColor,
                  ),
                  _buildMenuItem(
                    Icons.discount_outlined,
                    'Voucher & Promo',
                    textColor,
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('PREFERENSI APLIKASI', subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.notifications_none_outlined,
                    'Notifikasi Peringatan',
                    textColor,
                    () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: dividerColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.nights_stay_outlined,
                              color: Colors.amber,
                              size: 22,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'Mode Malam',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isDarkMode,
                          activeColor: AppColors.primaryAqua,
                          onChanged: (bool value) {
                            themeNotifier.value = value
                                ? ThemeMode.dark
                                : ThemeMode.light;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('BANTUAN', subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.help_outline,
                    'Pusat Bantuan (FAQ)',
                    textColor,
                    () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: dividerColor,
                  ),
                  _buildMenuItem(
                    Icons.info_outline,
                    'Tentang WashPoint',
                    textColor,
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Keluar Akun',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'WashPoint v1.0.0',
              style: GoogleFonts.dmSans(fontSize: 12, color: subTextColor),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryAqua, size: 26),
            const SizedBox(height: 15),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 13, color: subTextColor),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color subTextColor) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: subTextColor,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color textColor,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: AppColors.primaryDark, size: 22),
    title: Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    ),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    onTap: onTap,
  );
}