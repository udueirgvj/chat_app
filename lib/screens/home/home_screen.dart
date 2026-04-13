// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat_list_tile.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AuthService.instance.setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      AuthService.instance.setOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('المحادثات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: UserSearchDelegate(),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'logout') {
                await context.read<AuthProvider>().logout();
              } else if (v == 'profile') {
                context.push('/profile');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
              const PopupMenuItem(value: 'logout',  child: Text('تسجيل الخروج')),
            ],
          ),
        ],
      ),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ChatModel>>(
              stream: ChatService.instance.streamChats(me.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                final chats = snap.data ?? [];
                if (chats.isEmpty) {
                  return _buildEmpty();
                }
                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppTheme.dividerDark,
                    indent: 76,
                  ),
                  itemBuilder: (_, i) => ChatListTile(
                    chat: chats[i],
                    currentUserId: me.uid,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => showSearch(
          context: context,
          delegate: UserSearchDelegate(),
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: AppTheme.primary.withAlpha(80),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد محادثات بعد',
              style: TextStyle(color: Color(0xFF8797A7), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على ✏️ لبدء محادثة جديدة',
              style: TextStyle(color: Color(0xFF5D7A8A), fontSize: 13),
            ),
          ],
        ),
      );

  Widget _buildShimmer() => ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120,
                        decoration: BoxDecoration(color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 200,
                        decoration: BoxDecoration(color: AppTheme.dividerDark,
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── User Search Delegate ──────────────────────────────
class UserSearchDelegate extends SearchDelegate<UserModel?> {
  @override
  String get searchFieldLabel => 'ابحث عن مستخدم...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildUserList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildUserList(context);

  Widget _buildUserList(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text(
          'اكتب حرفين على الأقل للبحث',
          style: TextStyle(color: Color(0xFF8797A7)),
        ),
      );
    }
    return FutureBuilder<List<UserModel>>(
      future: AuthService.instance.searchUsers(query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد نتائج',
              style: TextStyle(color: Color(0xFF8797A7)),
            ),
          );
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary,
                backgroundImage: u.photoUrl.isNotEmpty
                    ? NetworkImage(u.photoUrl)
                    : null,
                child: u.photoUrl.isEmpty
                    ? Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(u.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                u.bio.isNotEmpty ? u.bio : u.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8797A7)),
              ),
              onTap: () async {
                close(context, u);
                final me = AuthService.instance.currentUser!;
                final chatId = await ChatService.instance.getOrCreateChat(
                  currentUserId: me.uid,
                  otherUserId: u.uid,
                );
                if (context.mounted) {
                  context.push('/chat/$chatId', extra: {
                    'otherUserId': u.uid,
                    'otherUserName': u.name,
                    'otherUserPhoto': u.photoUrl,
                    'isGroup': false,
                  });
                }
              },
            );
          },
        );
      },
    );
  }
}
