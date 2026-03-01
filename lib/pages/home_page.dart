import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'edit_post_page.dart';
import '../services/auth_service.dart';
import 'detail_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List posts = [];
  bool isLoadingPosts = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool isFabPressed = false;

  int limit = 10;
  int skip = 0;

  @override
  void initState() {
    super.initState();
    loadPosts(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingPosts &&
          hasMore) {
        loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void sortPostsByMeFirst() {
    posts.sort((a, b) {
      if (a["userId"] == 5 && b["userId"] != 5) return -1;
      if (a["userId"] != 5 && b["userId"] == 5) return 1;
      return 0;
    });
  }

  Future<void> loadPosts({bool isRefresh = false}) async {
    if (isLoadingPosts) return;

    setState(() => isLoadingPosts = true);

    if (isRefresh) {
      skip = 0;
      hasMore = true;
      posts.clear();
    }

    try {
      final response = await AuthService.getPosts(limit: limit, skip: skip);

      if (response.statusCode == 200) {
        List newPosts = response.data["posts"] ?? [];

        for (var p in newPosts) {
          p["isLiked"] ??= false;
          if (p["reactions"] is! Map) {
            final int likes = p["reactions"] is num
                ? (p["reactions"] as num).toInt()
                : 0;
            p["reactions"] = {"likes": likes, "dislikes": 0};
          } else {
            p["reactions"]["likes"] ??= 0;
            p["reactions"]["dislikes"] ??= 0;
          }
        }

        final int? totalPosts = response.data["total"] is int
            ? response.data["total"] as int
            : null;

        setState(() {
          posts.addAll(newPosts);
          skip += newPosts.length;
          hasMore = totalPosts != null
              ? posts.length < totalPosts
              : newPosts.length == limit;
          isLoadingPosts = false;
          sortPostsByMeFirst();
        });
      } else {
        setState(() => isLoadingPosts = false);
      }
    } catch (e) {
      setState(() => isLoadingPosts = false);
    }
  }

  Future<void> deletePost(int id, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://dummyjson.com/posts/$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          // Hapus berdasarkan id, bukan index (karena index bisa berubah)
          posts.removeWhere((p) => p["id"] == id);
        });
        _showSuccessSnackBar("Fess berhasil dihapus");
      } else {
        // Jika status code berbeda, masih hapus dari lokal
        setState(() {
          posts.removeWhere((p) => p["id"] == id);
        });
        _showSuccessSnackBar("Fess berhasil dihapus");
      }
    } catch (e) {
      debugPrint(e.toString());
      // Jika ada error network, tetap hapus dari lokal
      setState(() {
        posts.removeWhere((p) => p["id"] == id);
      });
      _showSuccessSnackBar("Fess berhasil dihapus");
    }
  }

  void toggleLike(int index) {
    setState(() {
      posts[index]["isLiked"] = !posts[index]["isLiked"];

      if (posts[index]["isLiked"]) {
        posts[index]["reactions"]["likes"] += 1;
      } else {
        posts[index]["reactions"]["likes"] -= 1;
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFCEEEE3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6CCDAB), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6CCDAB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    "assets/icons/fessterkirimicon.svg",
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
                decoration: const BoxDecoration(
                  color: Color(0xFF6CCDAB),
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
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            SvgPicture.asset("assets/icons/logo.svg", width: 30),
            const SizedBox(width: 8),
            const Text(
              "E-Code Fess",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              child: Container(
                width: 40,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDFE0E0), width: 1),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    "assets/icons/search.svg",
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: Image.asset(
                "assets/icons/profile.png",
                width: 35,
                height: 35,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 35),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadPosts(isRefresh: true);
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = posts[index];
            bool isMe = post["userId"] == 5;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(post: post)),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/anonim_biru.svg",
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Anonim",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          if (isMe)
                            const Text(
                              "Saya",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          const Spacer(),
                          if (isMe)
                            PopupMenuButton<String>(
                              icon: SvgPicture.asset(
                                "assets/icons/titiktiga.svg",
                                width: 20,
                              ),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditPostPage(post: post),
                                    ),
                                  );

                                  if (result != null && result is Map) {
                                    // Update post yang sudah diedit
                                    setState(() {
                                      int postIndex = posts.indexWhere(
                                        (p) => p["id"] == result["id"],
                                      );
                                      if (postIndex != -1) {
                                        posts[postIndex] = result;
                                      }
                                      sortPostsByMeFirst();
                                    });
                                    _showSuccessSnackBar("SORA telah diupdate");
                                  }
                                } else if (value == 'delete') {
                                  // Hapus menggunakan id, bukan index
                                  deletePost(post['id'], index);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/editbgputih.svg",
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Edit SORA",
                                        style: TextStyle(
                                          color: Color(0xFF131414),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/trashred.svg",
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Hapus SORA",
                                        style: TextStyle(
                                          color: Color(0xFFEA3829),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(post["body"] ?? post["title"] ?? ""),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => toggleLike(index),
                            child: SvgPicture.asset(
                              post["isLiked"]
                                  ? "assets/icons/lovered.svg"
                                  : "assets/icons/love.svg",
                              width: 20,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${post["reactions"]["likes"]} suka",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => isFabPressed = true),
        onTapUp: (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!context.mounted) return;
          setState(() => isFabPressed = false);

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditPostPage()),
          );
          if (!context.mounted) return;

          //EDIT AGAR POST BARU LANGSUNG MUNCUL DI HOME PAGE TANPA HARUS RELOAD
          if (result != null && result is Map) {
            setState(() {
              // Untuk post baru, selalu insert di posisi 0 (tidak perlu removeWhere)
              // removeWhere hanya untuk edit post (sudah ada id dari API)
              bool isNewPost = !posts.any((p) => p["id"] == result["id"]);

              if (!isNewPost) {
                // Jika post sudah ada (edit case), hapus yang lama
                posts.removeWhere((p) => p["id"] == result["id"]);
              }

              posts.insert(0, result);
              sortPostsByMeFirst();
            });

            _showSuccessSnackBar("SORA telah terkirim");
          }
        },
        onTapCancel: () => setState(() => isFabPressed = false),
        child: SvgPicture.asset(
          isFabPressed
              ? "assets/icons/editbgputih.svg"
              : "assets/icons/editbgbiru.svg",
          width: 56,
          height: 56,
        ),
      ),
    );
  }
}
