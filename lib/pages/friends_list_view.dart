import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../api/api_client.dart';

typedef FriendSelectCallback = void Function(Friend friend);

class FriendsListView extends StatefulWidget {
  /// 嵌入手机用：true 时不建议在这里 Navigator.push
  final bool embedded;

  /// 选中好友的回调：手机内用它来切到“聊天页/会话页”
  /// 全屏页面也可以传（或不传，用默认 push）
  final FriendSelectCallback? onSelect;

  const FriendsListView({
    super.key,
    this.embedded = false, //
    this.onSelect,
  });

  @override
  State<FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  bool _loading = true;
  Object? _error;
  List<Friend> _friends = const [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await ApiClient().fetchFriends(); // 这里假设返回 List<Friend>
      setState(() {
        _friends = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _handleTap(Friend f) {
    if (widget.onSelect != null) {
      widget.onSelect!(f);
      return;
    }

    // 如果你确实希望“全屏 FriendsPage 默认 push 到聊天页面”，
    // 可以在 FriendsPage 外层传 onSelect 实现 push。
    // 这里默认不做任何事，避免手机嵌入时误触跳出手机。
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("加载失败：$_error", style: TextStyle(color: Colors.black.withValues(alpha: 0.65) )),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadFriends,
                child: const Text("重试"),
              ),
            ],
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Text("暂无好友", style: TextStyle(color: Colors.black.withValues(alpha: 0.65))),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _friends.length,
        itemBuilder: (context, i) {
          final f = _friends[i];
          return _FriendTile(
            friend: f,
            onTap: () => _handleTap(f),
          );
        },
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            _Avatar(url: friend.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.88),
                    ),
                  ),
                  /*const SizedBox(height: 3),
                  Text(
                    (friend.signature ?? '').trim().isEmpty ? " " : (friend.signature ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                  ),*/
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    // url 可能是相对路径，也可能是完整 URL
    final uri = Uri.tryParse(url);
    final isHttp = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        color: Colors.black.withValues(alpha: 0.05),
        child: isHttp
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: Colors.black.withValues(alpha: 0.35)),
              )
            : Image.asset(
                // 如果你以后想支持本地 assets 头像，也可以走这里
                // 目前你返回的是 "avatar/ai_001.png"，一般是服务器静态资源，不是 assets
                // 所以更建议 ApiClient 中统一补全为 http(s) URL
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: Colors.black.withValues(alpha: 0.35)),
              ),
      ),
    );
  }
}
