import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;
  List posts = [];

  bool isLoadingPosts = false;
  bool hasMore = false;
  bool isLoadingFirstSearch = false;

  int limit = 10;
  int skip = 0;
  String query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingPosts &&
          hasMore &&
          query.isNotEmpty) {
        loadSearchPosts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadSearchPosts({bool isRefresh = false}) async {
    if (isLoadingPosts) return;

    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        posts.clear();
        hasMore = false;
        skip = 0;
        isLoadingFirstSearch = false;
      });
      return;
    }

    setState(() {
      isLoadingPosts = true;
      if (isRefresh) {
        isLoadingFirstSearch = true;
      }
    });

    if (isRefresh) {
      skip = 0;
      hasMore = true;
      posts.clear();
    }

    try {
      final response = await AuthService.searchPosts(
        query: trimmed,
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
          isLoadingFirstSearch = false;
        });
      } else {
        setState(() {
          isLoadingPosts = false;
          isLoadingFirstSearch = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoadingPosts = false;
        isLoadingFirstSearch = false;
      });
    }
  }

  void onSearchChanged(String value) {
    setState(() {
      query = value;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      loadSearchPosts(isRefresh: true);
    });
  }

  void toggleLike(int index) {
    setState(() {
      posts[index]['isLiked'] = !posts[index]['isLiked'];
      if (posts[index]['isLiked']) {
        posts[index]['reactions']['likes'] += 1;
      } else {
        posts[index]['reactions']['likes'] -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F6265)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '// Cari Fess',
          style: TextStyle(
            color: Color(0xFF131414),
            fontWeight: FontWeight.w700,
            fontSize: 28 / 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icons/profile.png',
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
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDFE0E0)),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/katakunci.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari kata kunci ...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7E8084),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      suffixIcon: query.trim().isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF7E8084),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: query.trim().isEmpty
                ? const SizedBox.shrink()
                : isLoadingFirstSearch
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada hasil',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => loadSearchPosts(isRefresh: true),
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

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(post: post),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                        'assets/icons/anonim_biru.svg',
                                        width: 30,
                                        height: 30,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Anonim',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(post['body'] ?? post['title'] ?? ''),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => toggleLike(index),
                                        child: SvgPicture.asset(
                                          post['isLiked']
                                              ? 'assets/icons/lovered.svg'
                                              : 'assets/icons/love.svg',
                                          width: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${post['reactions']['likes']} suka',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
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
          ),
        ],
      ),
    );
  }
}
