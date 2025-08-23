class User {
  final int? id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final List<String> roles;
  final bool active;
  bool hasRole(String role) {
    return roles.any((r) => r.toUpperCase() == role.toUpperCase() || r.toUpperCase() == 'ROLE_${role.toUpperCase()}');
  }

  User({
    this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.roles,
    this.active = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',  // Valeur par défaut si null
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      roles: List<String>.from(json['roles'] ?? []),
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'roles': roles,
      'active': active,
    };
  }
}
