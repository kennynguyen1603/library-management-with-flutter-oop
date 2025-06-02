abstract class Person {
  final String id;
  String name;
  String email;
  String phoneNumber;

  Person({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  // Abstract method that must be implemented by subclasses
  String getRole();

  // Common method for all persons
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'phoneNumber': phoneNumber};
  }
}
