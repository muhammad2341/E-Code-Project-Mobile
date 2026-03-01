import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import 'detail_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? authUser;
  List posts = [];

  bool isLoadingUser = true;
  bool isLoadingPosts = false;
  bool hasMore = true;

  int limit = 10;
  int skip = 0;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingPosts &&
          hasMore &&
          userId != null) {
        _loadUserPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadAuthUser();
    if (userId != null) {
      await _loadUserPosts(isRefresh: true);
    }
  }

  Future<void> _loadAuthUser() async {
    setState(() {
      isLoadingUser = true;
    });

    try {
      final response = await AuthService.getAuthUserMe();
      if (response.statusCode == 200 && response.data is Map) {
        setState(() {
          authUser = Map<String, dynamic>.from(response.data as Map);
          userId = authUser!['id'] as int?;
          isLoadingUser = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final response = await AuthService.getUser();
      if (response.statusCode == 200 && response.data is Map) {
        setState(() {
          authUser = Map<String, dynamic>.from(response.data as Map);
          userId = authUser!['id'] as int?;
          isLoadingUser = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      isLoadingUser = false;
    });
  }

  Future<void> _loadUserPosts({bool isRefresh = false}) async {
    if (isLoadingPosts || userId == null) return;

    setState(() {
      isLoadingPosts = true;
      if (isRefresh) {
        skip = 0;
        hasMore = true;
        posts.clear();
      }
    });

    try {
      final response = await AuthService.getPostsByUserId(
        userId: userId!,
        limit: limit,
        skip: skip,
        select: 'title,body,reactions,userId',
      );

      if (response.statusCode == 200) {
        final List newPosts = response.data['posts'] ?? [];

        for (final post in newPosts) {
          post['isLiked'] ??= false;
          if (post['reactions'] is! Map) {
            final int likes = post['reactions'] is num
                ? (post['reactions'] as num).toInt()
                : 0;
            post['reactions'] = {'likes': likes, 'dislikes': 0};
          } else {
            post['reactions']['likes'] ??= 0;
            post['reactions']['dislikes'] ??= 0;
          }
        }

        final int? totalPosts = response.data['total'] is int
            ? response.data['total'] as int
            : null;

        setState(() {
          posts.addAll(newPosts);
          skip += newPosts.length;
          hasMore = totalPosts != null
              ? posts.length < totalPosts
              : newPosts.length == limit;
          isLoadingPosts = false;
        });
      } else {
        setState(() {
          isLoadingPosts = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _refreshPage() async {
    await _loadAuthUser();
    if (userId != null) {
      await _loadUserPosts(isRefresh: true);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _toggleLike(int index) {
    setState(() {
      posts[index]['isLiked'] = !posts[index]['isLiked'];
      if (posts[index]['isLiked']) {
        posts[index]['reactions']['likes'] += 1;
      } else {
        posts[index]['reactions']['likes'] -= 1;
      }
    });
  }

  String _buildUserName() {
    final firstName = (authUser?['firstName'] ?? '').toString();
    final lastName = (authUser?['lastName'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : 'User';
  }

  String _buildUsernameHandle() {
    final username = (authUser?['username'] ?? '').toString();
    return username.isNotEmpty ? '@$username' : '@user';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/kembali.svg',
            width: 22,
            height: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBD7D4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/setengaharroww.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 1 + posts.length + (hasMore && posts.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/icons/profile.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, size: 40),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isLoadingUser)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      Text(
                        _buildUserName(),
                        style: const TextStyle(
                          fontSize: 32 / 2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF131414),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildUsernameHandle(),
                        style: const TextStyle(
                          fontSize: 16 / 2,
                          color: Color(0xFF7E8084),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'Fess yang kamu kirim',
                      style: TextStyle(
                        fontSize: 26 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF131414),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (index == posts.length + 1) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = posts[index - 1];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(post: post)),
                );
              },
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/anonim_biru.svg',
                                width: 28,
                                height: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Anonim',
                                style: TextStyle(
                                  color: Color(0xFF131414),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Saya',
                                style: TextStyle(
                                  color: Color(0xFF9B9EA3),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                (post['createdAt'] ?? '-').toString(),
                                style: const TextStyle(
                                  color: Color(0xFF7E8084),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post['body'] ?? post['title'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF131414),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleLike(index - 1),
                                child: SvgPicture.asset(
                                  post['isLiked']
                                      ? 'assets/icons/lovered.svg'
                                      : 'assets/icons/love.svg',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post['reactions']['likes']} suka',
                                style: const TextStyle(
                                  color: Color(0xFF9B9EA3),
                                  fontSize: 12,
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
          },
        ),
      ),
    );
  }
}
