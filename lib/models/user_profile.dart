import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? nombre;  // Alias para fullName
  final String? phone;
  final String? role;
  final double saldo;
  final bool activo;
  final bool esAdmin;
  final DateTime? emailConfirmedAt;
  final DateTime? lastSignInAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    String? nombre,
    this.phone,
    this.role = 'user',
    this.saldo = 0.0,
    this.activo = true,
    bool? esAdmin,
    this.emailConfirmedAt,
    this.lastSignInAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : nombre = nombre ?? fullName,
        esAdmin = esAdmin ?? (role == 'admin'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      nombre: json['nombre'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] as bool? ?? true,
      esAdmin: json['es_admin'] as bool?,
      emailConfirmedAt: json['email_confirmed_at'] != null
          ? DateTime.parse(json['email_confirmed_at'] as String)
          : null,
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'saldo': saldo,
      'email_confirmed_at': emailConfirmedAt?.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    double? saldo,
    DateTime? emailConfirmedAt,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      saldo: saldo ?? this.saldo,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
