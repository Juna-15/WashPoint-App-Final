import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';

class NewEntryScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const NewEntryScreen({super.key, this.docId, this.existingData});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Coating Keramik',
    'Cuci Interior',
    'Cuci Eksterior',
    'Auto Detailing',
    'Glass Protection',
  ];
  String _selectedCategory = 'Coating Keramik';

  Uint8List? _imageBytes;
  String? _base64Image;

  String _locationText = "Lokasi GPS belum diatur";
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _descriptionController.text = widget.existingData!['description'] ?? '';
      _base64Image = widget.existingData!['imageUrl'];

      if (widget.existingData!['category'] != null &&
          _categories.contains(widget.existingData!['category'])) {
        _selectedCategory = widget.existingData!['category'];
      }

      if (widget.existingData!['latitude'] != null) {
        _latitude = widget.existingData!['latitude'];
        _longitude = widget.existingData!['longitude'];
        _locationText =
            "Koordinat: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktifkan akses lokasi pada browser Anda.'),
        ),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText =
            "Koordinat: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePost() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi gambar, nama, dan deskripsi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      Map<String, dynamic> dataToSave = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'userId': currentUserId,
        'rating': widget.existingData?['rating'] ?? '5.0',
        'timeAgo': widget.existingData?['timeAgo'] ?? 'BARU SAJA',
        'imageUrl': _base64Image,
        'isBase64': true,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (widget.docId == null) {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('services').add(dataToSave);
      } else {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.docId)
            .update(dataToSave);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.docId == null ? 'Postingan ditambahkan!' : 'Diperbarui!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : AppColors.textMain;
    Color inputColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.docId != null ? 'Edit Laporan' : 'Laporan Baru',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : (_base64Image != null &&
                          !_base64Image!.startsWith('http'))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          base64Decode(_base64Image!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_enhance_outlined,
                            color: AppColors.primaryAqua,
                            size: 36,
                          ),
                          Text(
                            'Unggah Gambar',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),

            _buildLabel('KATEGORI LAYANAN', textColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: inputColor,
                  style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
                  items: _categories
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedCategory = newValue!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('NAMA TEMPAT', textColor),
            _buildTextField(
              controller: _titleController,
              hintText: 'Misal: Sapphire Detail',
              maxLines: 1,
              color: inputColor,
              textCol: textColor,
            ),
            const SizedBox(height: 20),

            _buildLabel('DESKRIPSI', textColor),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Fasilitas...',
              maxLines: 4,
              color: inputColor,
              textCol: textColor,
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('LOKASI GPS', textColor),
                GestureDetector(
                  onTap: _getCurrentLocation,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: AppColors.primaryAqua,
                        size: 14,
                      ),
                      Text(
                        ' Atur Saat Ini',
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _locationText,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAqua,
                    ),
                  )
                : _buildGradientButton(
                    text: widget.docId != null
                        ? 'Perbarui Postingan'
                        : 'Unggah Postingan',
                    onPressed: _savePost,
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
    child: Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
    required Color color,
    required Color textCol,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.dmSans(fontSize: 15, color: textCol),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
