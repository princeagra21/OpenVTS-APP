import 'package:flutter/material.dart';
class FSBadge extends StatelessWidget { const FSBadge({required this.label, this.color, super.key}); final String label; final Color? color; @override Widget build(BuildContext context) => Chip(label: Text(label), backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(.12)); }
