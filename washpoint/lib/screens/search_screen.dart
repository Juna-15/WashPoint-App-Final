import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    Color cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temukan Gerai',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Cari nama gerai atau layanan...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primaryAqua,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _searchQuery.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        Text(
                          'KATEGORI POPULER',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,

                          children:
                              [
                                    'Coating Keramik',
                                    'Cuci Interior',
                                    'Cuci Eksterior',
                                    'Auto Detailing',
                                    'Glass Protection',
                                  ]
                                  .map(
                                    (cat) => GestureDetector(
                                      onTap: () {
                                        _searchController.text = cat
                                            .toLowerCase();
                                        setState(
                                          () =>
                                              _searchQuery = cat.toLowerCase(),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('services')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryAqua,
                            ),
                          );
                        if (!snapshot.hasData) return const SizedBox();

                        var filteredDocs = snapshot.data!.docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;

                          String title = (data['title'] ?? '')
                              .toString()
                              .toLowerCase();
                          String category = (data['category'] ?? '')
                              .toString()
                              .toLowerCase();
                          return title.contains(_searchQuery) ||
                              category.contains(_searchQuery);
                        }).toList();

                        if (filteredDocs.isEmpty)
                          return const Center(
                            child: Text(
                              'Tidak ada hasil ditemukan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            var doc = filteredDocs[index];
                            var data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(
                                      imageUrl: data['imageUrl'] ?? '',
                                      title: data['title'] ?? '',
                                      rating: data['rating'] ?? '5.0',
                                      description: data['description'] ?? '',
                                      latitude: data['latitude'],
                                      longitude: data['longitude'],
                                      docId: doc.id,
                                    ),
                                  ),
                                ),
                                tileColor: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      data['imageUrl'] != null &&
                                          data['imageUrl'].toString().length >
                                              100
                                      ? Image.memory(
                                          base64Decode(data['imageUrl']),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.directions_car),
                                ),
                                title: Text(
                                  data['title'] ?? 'Tanpa Judul',
                                  style: GoogleFonts.dmSans(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  data['category'] ?? 'Layanan',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
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
}