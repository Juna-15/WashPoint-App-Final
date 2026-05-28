import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import 'new_entry_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'Semua Layanan',
    'Coating Keramik',
    'Cuci Interior',
    'Cuci Eksterior',
    'Auto Detailing',
    'Glass Protection',
  ];
  String _activeCategory = 'Semua Layanan';

  Future<void> _deletePost(String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Layanan?'),
            content: const Text('Data ini akan dihapus secara permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(docId)
            .delete();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewEntryScreen()),
        ),
        backgroundColor: AppColors.primaryAqua,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.primaryAqua,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WashPoint',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: textColor,
                  ),
                  children: const [
                    TextSpan(text: 'Segarkan\n'),
                    TextSpan(
                      text: 'perjalanan Anda.',
                      style: TextStyle(color: AppColors.primaryAqua),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari layanan...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories
                      .map(
                        (cat) => _buildCategoryChip(
                          cat,
                          isActive: _activeCategory == cat,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 30),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAqua,
                      ),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(child: Text('Belum ada layanan.'));

                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String title = (data['title'] ?? '')
                        .toString()
                        .toLowerCase();
                    String category = data['category'] ?? '';

                    bool matchesSearch = title.contains(_searchQuery);
                    bool matchesCategory =
                        _activeCategory == 'Semua Layanan' ||
                        category == _activeCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredDocs.isEmpty)
                    return const Center(child: Text('Tidak ditemukan.'));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var document = filteredDocs[index];
                      var data = document.data() as Map<String, dynamic>;

                      String postUserId = data['userId'] ?? '';
                      bool isOwner = currentUserId == postUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: _buildPostCard(
                          context: context,
                          docId: document.id,
                          data: data,
                          isOwner: isOwner,
                          isDarkMode: isDarkMode,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, {required bool isActive}) {
    return GestureDetector(
      onTap: () =>
          setState(() => _activeCategory = label), // Update state filter
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryAqua
              : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required bool isOwner,
    required bool isDarkMode,
  }) {
    String imageUrl = data['imageUrl'] ?? '';
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: imageUrl.isEmpty
                ? Container(height: 200, color: Colors.grey)
                : imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.memory(
                    base64Decode(imageUrl),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Tanpa Judul',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data['description'] ?? '',
                  style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Share.share(
                            'Lihat layanan detailing keren ini: ${data['title']}!\nDeskripsi: ${data['description']}',
                          ),
                          icon: const Icon(
                            Icons.share_outlined,
                            color: AppColors.primaryAqua,
                            size: 22,
                          ),
                          padding: const EdgeInsets.only(right: 15),
                        ),

                        if (isOwner) ...[
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewEntryScreen(
                                  docId: docId,
                                  existingData: data,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.orange,
                              size: 22,
                            ),
                            padding: const EdgeInsets.only(right: 15),
                          ),
                          IconButton(
                            onPressed: () => _deletePost(docId),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                        ],
                      ],
                    ),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            imageUrl: imageUrl,
                            title: data['title'] ?? '',
                            rating: data['rating'] ?? '5.0',
                            description: data['description'] ?? '',
                            latitude: data['latitude'],
                            longitude: data['longitude'],
                            docId: docId,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black26
                              : const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LIHAT DETAIL',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAqua,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}