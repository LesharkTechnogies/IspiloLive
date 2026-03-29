import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';
import '../../widgets/profile_avatar.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      _users = await UserRepository.getUserSuggestions(page: 0, size: 30);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(3.w),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.9),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final u = _users[index];
                return Card(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/profile', arguments: {'userId': u.id}),
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfileAvatar(
                            imageUrl: u.avatar,
                            size: 72,
                            isOnline: false,
                          ),
                          SizedBox(height: 1.h),
                          Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          TextButton(
                            onPressed: () async {
                              try {
                                await UserRepository.followUser(u.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Following ${u.name}')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to follow: $e')),
                                );
                              }
                            },
                            child: const Text('Follow'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
