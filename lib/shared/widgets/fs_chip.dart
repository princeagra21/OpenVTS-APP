import 'package:flutter/material.dart';
class FSChip extends StatelessWidget { const FSChip({required this.label, this.onDeleted, super.key}); final String label; final VoidCallback? onDeleted; @override Widget build(BuildContext context) => Chip(label: Text(label), onDeleted: onDeleted); }
