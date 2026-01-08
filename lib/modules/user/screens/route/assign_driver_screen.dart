import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Driver {
  final String name;
  final String phone;
  final String vehicle;
  final String status;
  final Color statusColor;

  Driver({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.status,
    required this.statusColor,
  });
}

class AssignDriverScreen extends StatefulWidget {
  final String? current;

  const AssignDriverScreen({super.key, this.current});

  @override
  State<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends State<AssignDriverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? selected;

  final List<Driver> allDrivers = [
    Driver(name: 'John Smith', phone: '+1 (555) 0123', vehicle: 'Truck #001', status: 'Available', statusColor: Colors.green),
    Driver(name: 'Sarah Johnson', phone: '+1 (555) 0124', vehicle: 'Van #003', status: 'Available', statusColor: Colors.green),
    Driver(name: 'Mike Davis', phone: '+1 (555) 0125', vehicle: 'Truck #002', status: 'On Route', statusColor: Colors.amber),
    Driver(name: 'Lisa Wilson', phone: '+1 (555) 0126', vehicle: 'Van #004', status: 'Available', statusColor: Colors.green),
    // Add more drivers as needed
  ];

  late List<Driver> filteredDrivers;

  @override
  void initState() {
    super.initState();
    selected = widget.current;
    filteredDrivers = allDrivers;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDrivers = allDrivers.where((d) => d.name.toLowerCase().contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w) * 1.5;

    // Reduced sizes for mobile
    final double iconContainerSize = AdaptiveUtils.getAvatarSize(w); // Removed *1.1 multiplier
    final double innerIconSize = AdaptiveUtils.getIconSize(w) * 0.9;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Assign to Driver",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _searchController,
                hintText: 'Search drivers',
                prefixIcon: Icons.search,
                fontSize: AdaptiveUtils.getTitleFontSize(w),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = filteredDrivers[index];
                    final isSelected = selected == driver.name;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4), // Reduced from 6
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => selected = driver.name),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hp * 0.8, vertical: hp * 0.4), // Tighter padding
                            child: Row(
                              children: [
                                Container(
                                  height: iconContainerSize,
                                  width: iconContainerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cs.primary.withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      driver.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: innerIconSize,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        driver.name,
                                        style: GoogleFonts.inter(
                                          fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2, // Smaller
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${driver.phone} • ${driver.vehicle}',
                                        style: GoogleFonts.inter(
                                          fontSize: AdaptiveUtils.getTitleFontSize(w) - 2, // Smaller
                                          color: cs.onSurface.withOpacity(0.55),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Plain colored text instead of Chip
                                      Text(
                                        driver.status,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: driver.statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected ? Icons.check_circle : CupertinoIcons.chevron_forward,
                                  size: AdaptiveUtils.getIconSize(w) * 0.8,
                                  color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected != null ? () => Navigator.pop(context, selected) : null,
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}