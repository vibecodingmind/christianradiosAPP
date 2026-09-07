class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final String? subscriptionTier;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.subscriptionTier,
    required this.createdAt,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isOwner => role == 'OWNER';
  bool get isListener => role == 'LISTENER';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? 'LISTENER',
    avatarUrl: json['avatarUrl'] as String?,
    subscriptionTier: json['subscriptionTier'] as String?,
    createdAt: json['createdAt'] as String? ?? '',
  );
}
