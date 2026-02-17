import 'package:fleet_stack/core/models/vehicle_user_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleUsersTab extends StatefulWidget {
  final List<VehicleUserItem>? users;

  const VehicleUsersTab({super.key, this.users});

  @override
  State<VehicleUsersTab> createState() => _VehicleUsersTabState();
}

class _VehicleUsersTabState extends State<VehicleUsersTab> {
  final List<Map<String, String>> _fallbackUsers = const [
    {
      "name": "Akash Kumar",
      "username": "@akash.k",
      "lastSeen": "47d ago",
      "email": "akash.kumar@example.com",
      "phone": "+91 9810012345",
      "status": "Login",
    },
    {
      "name": "Vinod Singh",
      "username": "@vinod.s",
      "lastSeen": "48d ago",
      "email": "vinod.singh@example.com",
      "phone": "+91 9899011122",
      "status": "Login",
    },
    {
      "name": "Priya Mehta",
      "username": "@priya.m",
      "lastSeen": "49d ago",
      "email": "priya.mehta@example.com",
      "phone": "+91 9876543210",
      "status": "Login",
    },
    {
      "name": "Rahul Verma",
      "username": "@rahul.v",
      "lastSeen": "47d ago",
      "email": "rahul.verma@example.com",
      "phone": "+91 9988776655",
      "status": "Login",
    },
    {
      "name": "Sanya Kapoor",
      "username": "@sanya.k",
      "lastSeen": "50d ago",
      "email": "sanya.kapoor@example.com",
      "phone": "+91 9123456780",
      "status": "Login",
    },
    {
      "name": "Arjun Iyer",
      "username": "@arjun.i",
      "lastSeen": "54d ago",
      "email": "arjun.iyer@example.com",
      "phone": "+91 9000012345",
      "status": "Login",
    },
  ];

  late List<Map<String, String>> _users;

  @override
  void initState() {
    super.initState();
    _users = _resolvedUsers(widget.users);
  }

  @override
  void didUpdateWidget(covariant VehicleUsersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      setState(() {
        _users = _resolvedUsers(widget.users);
      });
    }
  }

  List<Map<String, String>> _resolvedUsers(List<VehicleUserItem>? users) {
    final mapped = (users ?? const <VehicleUserItem>[])
        .map(
          (u) => <String, String>{
            "name": u.name.isNotEmpty ? u.name : "—",
            "username": u.username.isNotEmpty ? "@${u.username}" : "",
            "lastSeen": u.lastSeen.isNotEmpty ? u.lastSeen : "—",
            "email": u.email,
            "phone": u.phone,
            "status": "Login",
          },
        )
        .toList();
    return mapped.isEmpty
        ? List<Map<String, String>>.from(_fallbackUsers)
        : mapped;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: _users.map((user) => _buildUserCard(user, cs)).toList(),
    );
  }

  Widget _buildUserCard(Map<String, String> user, ColorScheme cs) {
    final String initials = _getInitials(user["name"]!);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        user["name"]!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user["username"]!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user["email"]!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  user["phone"]!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Last: ${user["lastSeen"]}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        user["status"]!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }
}
