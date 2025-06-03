import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vchat/views/login_page.dart';
import '../controller/chat_controller.dart';
import '../controller/user_controller.dart';
import '../models/message.dart';
import '../models/user_model.dart';
import '../views/full_screen_image.dart';
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await userController.fetchUserData();
    await chatController.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ) ?? false;

                if (!shouldLogout) return;

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Perform logout directly with Supabase
                  final supabase = Supabase.instance.client;
                  await supabase.auth.signOut();

                  // Clear navigation stack and go to login
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                          (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Dismiss loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ]      ),
      body: Obx(() {
        if (chatController.users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading users...")
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chatController.users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = chatController.users[index];
            return UserListItem(user: user);
          },
        );
      }),
    );
  }
}


class UserListItem extends StatelessWidget {
  final UserModel user;

  const UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade300,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chat_bubble_outline),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            receiverId: user.id,
            receiverName: user.name,
          ),
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailScreen({
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController chatController = Get.find<ChatController>();
  final UserController userController = Get.find<UserController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    chatController.receiverId.value = widget.receiverId;
    chatController.receiverName.value = widget.receiverName;
    chatController.senderId.value = userController.getUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade300,
              radius: 16,
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.receiverName),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: _MessageList(scrollController: _scrollController),
          ),
          _ChatInput(),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;

  const _MessageList({required this.scrollController});
  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return StreamBuilder<List<Message>>(
      stream: chatController.getMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return MessageWidget(message: snapshot.data![index]);
          },
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final isSender = message.senderId == chatController.senderId.value;
    final formattedTime = DateFormat('h:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[
            CircleAvatar(
              backgroundColor: Colors.blue.shade300,
              radius: 16,
              child: Text(
                chatController.receiverName.value.isNotEmpty
                    ? chatController.receiverName.value[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSender ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
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

  Widget _buildMessageContent(BuildContext context) {
    if (message.type == 'image' && message.photoUrl != null) {
      // Use the photoUrl directly without replacing anything
      String imageUrl = message.photoUrl!;

      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenChatImage(photoUrl: imageUrl),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade300,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('Image error: $error for URL: $imageUrl');
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Image failed to load',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      imageUrl,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    return Text(message.content ?? '');
  }
}
class _ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          PopupMenuButton<ImageSource>(
            icon: const Icon(Icons.camera_alt, color: Colors.blue),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ImageSource.gallery,
                child: Text('Choose from gallery'),
              ),
              const PopupMenuItem(
                value: ImageSource.camera,
                child: Text('Take a photo'),
              ),
            ],
            onSelected: (source) => chatController.pickImage(source),
          ),
          Expanded(
            child: TextField(
              controller: chatController.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => chatController.isSending.value
              ? Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const CircularProgressIndicator(),
          )
              : Material(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: chatController.onMessageSend,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}