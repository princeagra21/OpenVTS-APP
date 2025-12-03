import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleUsersTab extends StatelessWidget {
  const VehicleUsersTab({super.key});

  final List<Map<String, String>> users = const [
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users.map((user) => _buildUserCard(user)).toList(),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    final String initials = _getInitials(user["name"]!);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black.withOpacity(0.7),
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["name"]!,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  user["username"]! + " • " + user["lastSeen"]!,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  user["email"]!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
                ),
                Text(
                  user["phone"]!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(user["status"]!, style: const TextStyle(fontSize: 12, color: Colors.white),),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }
}
