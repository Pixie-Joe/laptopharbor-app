class User {
  String name;
  String email;
  String? profileImage;

  User({
    required this.name,
    required this.email,
    this.profileImage,
  });
}
