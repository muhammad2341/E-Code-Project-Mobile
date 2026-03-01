import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class DetailPage extends StatefulWidget {
  final Map post;

  const DetailPage({super.key, required this.post});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List comments = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool isSendPressed = false;

  @override
  void initState() {
    super.initState();
    loadPostDetail();
    loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> loadPostDetail() async {
    try {
      final response = await AuthService.getPost(widget.post["id"]);

      if (response.statusCode == 200) {
        Map postDetail = response.data;

        // Gabungkan data baru dengan data lokal yang sudah ada
        setState(() {
          widget.post["body"] = postDetail["body"] ?? widget.post["body"];
          widget.post["reactions"] =
              postDetail["reactions"] ??
              widget.post["reactions"] ??
              {"likes": 0, "dislikes": 0};
          widget.post["isLiked"] = widget.post["isLiked"] ?? false;
        });
      }
    } catch (e) {
      print("Error loading post detail: $e");
    }
  }

  Future<void> loadComments() async {
    try {
      final response = await AuthService.getPostComments(widget.post["id"]);

      if (response.statusCode == 200) {
        List fetchedComments = response.data["comments"];

        // Tambahkan field lokal untuk like komentar
        for (var c in fetchedComments) {
          c["isLiked"] = false;
          c["likes"] = 0; // dummy like awal
        }

        setState(() {
          comments = fetchedComments;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= LIKE POST =================
  void togglePostLike() {
    setState(() {
      widget.post["isLiked"] = !(widget.post["isLiked"] ?? false);

      if (widget.post["isLiked"]) {
        widget.post["reactions"]["likes"]++;
      } else {
        widget.post["reactions"]["likes"]--;
      }
    });
  }

  // ================= LIKE COMMENT =================
  void toggleCommentLike(int index) {
    setState(() {
      comments[index]["isLiked"] = !(comments[index]["isLiked"] ?? false);

      if (comments[index]["isLiked"]) {
        comments[index]["likes"]++;
      } else {
        comments[index]["likes"]--;
      }
    });
  }

  void sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      comments.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch,
        "body": _commentController.text,
        "user": {"username": "Anonim"},
        "isLiked": false,
        "likes": 0,
      });
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Balasan terkirim")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("// Balasan", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              "assets/icons/profile.png",
              width: 35,
              height: 35,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 35),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= POST =================
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
                    const SizedBox(width: 10),
                    const Text(
                      "Anonim",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Text(
                      "2 Jan",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.post["body"]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: togglePostLike,
                      child: SvgPicture.asset(
                        (widget.post["isLiked"] ?? false)
                            ? "assets/icons/lovered.svg"
                            : "assets/icons/love.svg",
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text("${widget.post["reactions"]["likes"]} suka"),
                  ],
                ),
              ],
            ),
          ),

          // ================= HEADER BALASAN =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: const Text(
              "Balasan E-Coders",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          const Divider(height: 1),

          // ================= COMMENTS =================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada balasan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.white,
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
                                const SizedBox(width: 10),
                                Text(
                                  comment["user"]["username"] ?? "Anonim",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  "2 Jan",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment["body"]),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => toggleCommentLike(index),
                                  child: SvgPicture.asset(
                                    (comment["isLiked"] ?? false)
                                        ? "assets/icons/lovered.svg"
                                        : "assets/icons/love.svg",
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${comment["likes"]} suka",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ================= INPUT BALASAN =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Tulis balasan...",
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTapDown: (_) => setState(() => isSendPressed = true),
                    onTapUp: (_) async {
                      await Future.delayed(const Duration(milliseconds: 100));
                      sendComment();
                      setState(() => isSendPressed = false);
                    },
                    onTapCancel: () => setState(() => isSendPressed = false),
                    child: SvgPicture.asset(
                      isSendPressed
                          ? "assets/icons/teruskan.svg"
                          : "assets/icons/teruskanbgbiru.svg",
                      width: 44,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
