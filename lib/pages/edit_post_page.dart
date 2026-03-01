import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditPostPage extends StatefulWidget {
  final Map? post; // Jika null berarti Add Post, jika ada berarti Edit Post
  const EditPostPage({super.key, this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final TextEditingController _controller = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null && widget.post!.containsKey("body")) {
      _controller.text = widget.post!["body"] ?? "";
    }
    _controller.addListener(() {
      setState(() {}); // Update character count
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> submitPost() async {
    // Validasi: Field kosong
    if (_controller.text.trim().isEmpty) {
      _showCustomSnackBar(
        context,
        "Fess tidak boleh kosong",
        "assets/icons/fesskosongicon.svg",
        const Color(0xFFFDE7D3),
        const Color(0xFFFAB67C),
      );
      return;
    }

    setState(() => isSubmitting = true);

    bool isEdit = widget.post != null;
    String url = isEdit
        ? 'https://dummyjson.com/posts/${widget.post!['id']}'
        : 'https://dummyjson.com/posts/add';

    try {
      final response = isEdit
          ? await http
                .put(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'title': widget.post!['title'] ?? 'User Post',
                    'body': _controller.text,
                    'userId': widget.post!['userId'] ?? 5,
                  }),
                )
                .timeout(const Duration(seconds: 10))
          : await http
                .post(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'title': 'User Post',
                    'body': _controller.text,
                    'userId': 5,
                  }),
                )
                .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);

        // Pastikan body selalu dari input user (controller), bukan dari response API
        data["body"] = _controller.text;

        if (isEdit && widget.post != null) {
          // Pertahankan data lama saat edit
          data["isLiked"] = widget.post!["isLiked"] ?? false;
          data["reactions"] =
              widget.post!["reactions"] ?? {"likes": 0, "dislikes": 0};
          data["userId"] = widget.post!["userId"] ?? 5;
          data["id"] = widget.post!["id"]; // Pastikan ID tetap sama
          data["localDate"] =
              widget.post!["localDate"] ??
              DateTime.now(); // Pertahankan tanggal lokal
        } else {
          // Data default untuk post baru
          data["isLiked"] = false;
          data["reactions"] = {"likes": 0, "dislikes": 0};
          data["userId"] = 5;
          data["localDate"] =
              DateTime.now(); // Set tanggal lokal untuk post baru
        }

        // Tunggu sebentar sebelum menutup untuk menghindari race condition
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pop(context, data);
        }
      } else {
        // Jika status code tidak 200/201, coba parse response dan kembalikan data
        try {
          var data = jsonDecode(response.body);

          // Pastikan body selalu dari input user
          data["body"] = _controller.text;

          if (isEdit && widget.post != null) {
            data["isLiked"] = widget.post!["isLiked"] ?? false;
            data["reactions"] =
                widget.post!["reactions"] ?? {"likes": 0, "dislikes": 0};
            data["userId"] = widget.post!["userId"] ?? 5;
            data["id"] = widget.post!["id"];
            data["localDate"] = widget.post!["localDate"] ?? DateTime.now();
          } else {
            data["isLiked"] = false;
            data["reactions"] = {"likes": 0, "dislikes": 0};
            data["userId"] = 5;
            data["localDate"] = DateTime.now();
          }
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.pop(context, data);
          }
        } catch (e) {
          _showCustomSnackBar(
            context,
            "Gagal mengirim Fess!",
            "assets/icons/fessinterneticon.svg",
            const Color(0xFFFBD7D4),
            const Color(0xFFF2887F),
          );
        }
      }
    } on http.ClientException {
      // No internet connection
      _showCustomSnackBar(
        context,
        "Internet-mu terputus!",
        "assets/icons/fessinterneticon.svg",
        const Color(0xFFFBD7D4),
        const Color(0xFFF2887F),
      );
    } catch (e) {
      // Network timeout or other errors
      _showCustomSnackBar(
        context,
        "Internet-mu terputus!",
        "assets/icons/fessinterneticon.svg",
        const Color(0xFFFBD7D4),
        const Color(0xFFF2887F),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message,
    String iconPath,
    Color bgColor,
    Color accentColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            "assets/icons/kembali.svg",
            width: 22,
            height: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.post != null ? "Edit Fess" : "Kirim Fess",
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  left: BorderSide(color: Color(0xFF5295FA), width: 4),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/anonim_biru.svg",
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Anonim",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: "Lagi mikirin apa?",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      counterText: "",
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "(${_controller.text.length}/500)",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF689BFF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Kirim",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
