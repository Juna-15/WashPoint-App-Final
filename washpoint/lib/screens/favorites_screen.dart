import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // PERBAIKAN: Judul diubah menjadi Gerai Favorit
        title: Text(
          'Gerai Favorit',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tersimpan',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Akses cepat ke tempat detailing pilihan Anda.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : AppColors.textSubtitle,
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('favorites')
                    .orderBy('savedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAqua,
                      ),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Belum ada favorit.',
                            style: GoogleFonts.dmSans(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: _buildFavoriteCard(
                          context: context,
                          docId: doc.id,
                          imageUrl: data['imageUrl'] ?? '',
                          title: data['title'] ?? 'Tanpa Judul',
                          rating: data['rating'] ?? '5.0',
                          description: data['description'] ?? '',
                          latitude: data['latitude'],
                          longitude: data['longitude'],
                          isDarkMode: isDarkMode,
                          textColor: textColor,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard({
    required BuildContext context,
    required String docId,
    required String imageUrl,
    required String title,
    required String rating,
    required String description,
    required double? latitude,
    required double? longitude,
    required bool isDarkMode,
    required Color textColor,
  }) {
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              imageUrl: imageUrl,
              title: title,
              rating: rating,
              description: description,
              latitude: latitude,
              longitude: longitude,
              docId: docId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl.isEmpty
                  ? Container(width: 90, height: 90, color: Colors.grey)
                  : imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Image.memory(
                      base64Decode(imageUrl),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryAqua,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : AppColors.textSubtitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}