import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final String docId;
  final String imageUrl;
  final String title;
  final String rating;
  final String description;
  final double? latitude;
  final double? longitude;

  const DetailScreen({
    super.key,
    required this.docId,
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.description,
    this.latitude,
    this.longitude,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _replyingToReviewId;
  String? _replyingToUserName;

  String get currentUserName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
      'Pengguna';

  Future<void> _openMap() async {
    if (widget.latitude == null || widget.longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lokasi tidak tersedia.')));
      return;
    }
    final Uri url = Uri.parse(
      'http://googleusercontent.com/maps.google.com/maps?q=${widget.latitude},${widget.longitude}',
    );
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka peta.')),
      );
    }
  }

  Future<void> _addReview() async {
    if (_reviewController.text.trim().isEmpty) return;
    try {
      if (_replyingToReviewId != null) {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.docId)
            .collection('reviews')
            .doc(_replyingToReviewId)
            .collection('replies')
            .add({
              'userName': currentUserName,
              'text': _reviewController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() {
          _replyingToReviewId = null;
          _replyingToUserName = null;
        });
      } else {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.docId)
            .collection('reviews')
            .add({
              'userName': currentUserName,
              'text': _reviewController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      _reviewController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _toggleFavorite(bool isCurrentlyFavorite) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(widget.docId);
    try {
      if (isCurrentlyFavorite) {
        await docRef.delete();
      } else {
        await docRef.set({
          'title': widget.title,
          'imageUrl': widget.imageUrl,
          'rating': widget.rating,
          'description': widget.description,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    const SizedBox(height: 260, width: double.infinity),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: widget.imageUrl.isEmpty
                          ? Container(height: 200, color: Colors.grey)
                          : widget.imageUrl.startsWith('http')
                          ? Image.network(
                              widget.imageUrl,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              base64Decode(widget.imageUrl),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: textColor,
                            size: 26,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .collection('favorites')
                            .doc(widget.docId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool isFavorite =
                              snapshot.hasData && snapshot.data!.exists;
                          return Center(
                            child: GestureDetector(
                              onTap: () => _toggleFavorite(isFavorite),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red
                                          : textColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFavorite
                                          ? 'Tersimpan'
                                          : 'Tambah ke Favorit',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.black26
                                  : const Color(0xFFE6F3FB),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppColors.primaryAqua,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${widget.rating} Rating',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryAqua,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.description,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : AppColors.textSubtitle,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 35),

                      Text(
                        'Lokasi',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _openMap,
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/map_location.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Buka di Google Maps',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      Text(
                        'Ulasan Komunitas',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _replyingToReviewId != null
                                ? AppColors.primaryAqua
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_replyingToReviewId != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Membalas $_replyingToUserName',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.primaryAqua,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _replyingToReviewId = null;
                                        _replyingToUserName = null;
                                      }),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            TextField(
                              controller: _reviewController,
                              style: TextStyle(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _replyingToReviewId != null
                                    ? 'Tulis balasan...'
                                    : 'Bagikan pengalaman Anda...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                              maxLines: 2,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _addReview,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.black26
                                        : const Color(0xFFD6EEFA),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Kirim',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryAqua,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // DAFTAR ULASAN & BALASAN
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('services')
                            .doc(widget.docId)
                            .collection('reviews')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                            return const Text(
                              'Belum ada ulasan.',
                              style: TextStyle(color: Colors.grey),
                            );
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var reviewDoc = snapshot.data!.docs[index];
                              var rev =
                                  reviewDoc.data() as Map<String, dynamic>;
                              return _buildReviewCard(
                                reviewDoc.id,
                                rev['userName'] ?? 'User',
                                rev['text'] ?? '',
                                isDarkMode,
                                textColor,
                                cardColor,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String reviewId,
    String name,
    String text,
    bool isDarkMode,
    Color textColor,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            // Tombol Balas (Reply)
            GestureDetector(
              onTap: () {
                setState(() {
                  _replyingToReviewId = reviewId;
                  _replyingToUserName = name;
                });
              },
              child: Text(
                'Balas',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAqua,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade400 : AppColors.textSubtitle,
            height: 1.5,
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .doc(widget.docId)
              .collection('reviews')
              .doc(reviewId)
              .collection('replies')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 30.0),
              child: Column(
                children: snapshot.data!.docs.map((replyDoc) {
                  var reply = replyDoc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black26
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                reply['userName'] ?? 'User',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            reply['text'] ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : AppColors.textSubtitle,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        Divider(color: Colors.grey.shade200),
      ],
    );
  }
}