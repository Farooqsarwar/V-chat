class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String type;
  final String? content;
  final DateTime createdAt;
  final String? photoUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.content,
    required this.createdAt,
    this.photoUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      type: json['type'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      photoUrl: json['photo_url'],
    );
  }
}