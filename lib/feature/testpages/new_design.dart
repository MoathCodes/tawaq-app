// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:forui/forui.dart';
// import 'package:hasanat/core/utils/gradient_background.dart';

// class BrandBadge extends StatelessWidget {
//   const BrandBadge({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 36,
//       height: 36,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF2DD4BF), Color(0xFFA7F3D0)],
//         ),
//       ),
//       child: const Center(
//         child: Text(
//           'TQ',
//           style: TextStyle(
//             color: Color(0xFF0B0F10),
//             fontWeight: FontWeight.w800,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class GlassyCard extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets? padding;
//   final double? height;
//   final String? backgroundImage;

//   const GlassyCard({
//     super.key,
//     required this.child,
//     this.padding,
//     this.height,
//     this.backgroundImage,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: height,
//       decoration: BoxDecoration(
//         color: TawaqTheme.panel,
//         border: Border.all(color: const Color(0xFF22222B)),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           const BoxShadow(
//             color: Colors.black38,
//             blurRadius: 30,
//             offset: Offset(0, 8),
//           ),
//         ],
//         image: backgroundImage != null
//             ? DecorationImage(
//                 image: NetworkImage(backgroundImage!),
//                 fit: BoxFit.cover,
//                 colorFilter: const ColorFilter.mode(
//                   Colors.black12,
//                   BlendMode.darken,
//                 ),
//               )
//             : null,
//       ),
//       child: Container(
//         padding: padding ?? const EdgeInsets.all(18),
//         decoration: backgroundImage != null
//             ? BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     const Color(0xFF0C0E12).withOpacity(0.75),
//                     const Color(0xFF0C0E12).withOpacity(0.2),
//                   ],
//                 ),
//               )
//             : null,
//         child: child,
//       ),
//     );
//   }
// }

// class NextPrayerCard extends StatelessWidget {
//   const NextPrayerCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GlassyCard(
//       height: 240,
//       backgroundImage:
//           "https://images.unsplash.com/photo-1547891654-e66ed7ebb968?q=80&w=1600&auto=format&fit=crop",
//       child: Row(
//         children: [
//           Expanded(
//             flex: 11,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Dhuhr',
//                   style: TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.bold,
//                     color: TawaqTheme.textColor,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: TawaqTheme.primary.withOpacity(0.15),
//                         border: Border.all(
//                           color: TawaqTheme.primary.withOpacity(0.4),
//                         ),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: const Text(
//                         'Next prayer in',
//                         style: TextStyle(
//                           color: TawaqTheme.primary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     const Text(
//                       '01:59:22',
//                       style: TextStyle(
//                         fontSize: 36,
//                         fontWeight: FontWeight.w800,
//                         color: TawaqTheme.textColor,
//                         letterSpacing: 1,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 const Text(
//                   'Prepare yourself for the prayer. May Allah accept from us.',
//                   style: TextStyle(
//                     color: TawaqTheme.muted,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             flex: 10,
//             child: GridView.count(
//               crossAxisCount: 2,
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//               childAspectRatio: 1.2,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               children: const [
//                 TimeChip(label: 'Adhan', value: '12:29 PM'),
//                 TimeChip(label: 'Iqamah', value: '12:49 PM'),
//                 TimeChip(label: 'Current time', value: '10:30 AM'),
//                 TimeChip(label: 'Timezone', value: 'GMT+3'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class Prayer {
//   final String name;
//   final String adhanTime;
//   final String iqamahTime;
//   final PrayerStatus status;

//   const Prayer(this.name, this.adhanTime, this.iqamahTime, this.status);
// }

// class PrayerRow extends StatelessWidget {
//   final Prayer prayer;

//   const PrayerRow({super.key, required this.prayer});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: prayer.status == PrayerStatus.current
//             ? const Color(0xFF1B1B23)
//             : TawaqTheme.panel2,
//         border: Border.all(
//           color: prayer.status == PrayerStatus.current
//               ? TawaqTheme.primary.withOpacity(0.25)
//               : const Color(0xFF22222B),
//           width: prayer.status == PrayerStatus.current ? 2 : 1,
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 13,
//             child: Row(
//               children: [
//                 Text(_getPrayerEmoji(prayer.name),
//                     style: const TextStyle(fontSize: 16)),
//                 const SizedBox(width: 10),
//                 Text(
//                   prayer.name,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: TawaqTheme.textColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 9,
//             child: Text(
//               prayer.adhanTime,
//               style: const TextStyle(color: TawaqTheme.textColor),
//             ),
//           ),
//           Expanded(
//             flex: 9,
//             child: Text(
//               prayer.iqamahTime,
//               style: const TextStyle(color: TawaqTheme.textColor),
//             ),
//           ),
//           FButton(
//             // style:(p0) => p0.copyWith(
//             //   decoration: p0.,
//             //   backgroundColor: TawaqTheme.primary,
//             //   foregroundColor: const Color(0xFF0F0F12),
//             // ),
//             onPress: () {},
//             child: const Text('✓'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getPrayerEmoji(String prayerName) {
//     switch (prayerName.toLowerCase()) {
//       case 'fajr':
//         return '🌅';
//       case 'dhuhr':
//         return '🏙️';
//       case 'asr':
//         return '🌤️';
//       case 'maghrib':
//         return '🌇';
//       case 'isha':
//         return '🌌';
//       default:
//         return '🕌';
//     }
//   }
// }

// class PrayerScheduleCard extends StatelessWidget {
//   final List<Prayer> prayers = const [
//     Prayer('Fajr', '04:35 AM', '05:00 AM', PrayerStatus.completed),
//     Prayer('Dhuhr', '12:29 PM', '12:49 PM', PrayerStatus.current),
//     Prayer('Asr', '03:49 PM', '04:09 PM', PrayerStatus.upcoming),
//     Prayer('Maghrib', '07:01 PM', '07:11 PM', PrayerStatus.upcoming),
//     Prayer('Isha', '08:31 PM', '08:31 PM', PrayerStatus.upcoming),
//   ];

//   const PrayerScheduleCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GlassyCard(
//       child: Column(
//         children: [
//           // Header
//           const Padding(
//             padding: EdgeInsets.only(bottom: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Prayer Schedule',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: TawaqTheme.textColor,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   'Today',
//                   style: TextStyle(
//                     color: TawaqTheme.muted,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             height: 1,
//             color: const Color(0xFF22222B),
//             margin: const EdgeInsets.only(bottom: 16),
//           ),
//           // Table Header
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                     flex: 13,
//                     child: Text('Prayer',
//                         style:
//                             TextStyle(color: TawaqTheme.muted, fontSize: 12))),
//                 Expanded(
//                     flex: 9,
//                     child: Text('Adhan',
//                         style:
//                             TextStyle(color: TawaqTheme.muted, fontSize: 12))),
//                 Expanded(
//                     flex: 9,
//                     child: Text('Iqamah',
//                         style:
//                             TextStyle(color: TawaqTheme.muted, fontSize: 12))),
//                 SizedBox(width: 40),
//               ],
//             ),
//           ),
//           // Prayer Rows
//           ...prayers.map((prayer) => PrayerRow(prayer: prayer)),
//         ],
//       ),
//     );
//   }
// }

// enum PrayerStatus { completed, current, upcoming, missed }

// class PrayerTimesScreen extends StatelessWidget {
//   const PrayerTimesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GradientBackground(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           if (constraints.maxWidth > 1024) {
//             return _buildDesktopLayout();
//           } else {
//             return _buildMobileLayout();
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildAnalyticsCard() {
//     return GlassyCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   const Text(
//                     'Prayer Analytics',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: TawaqTheme.textColor,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: TawaqTheme.panel2,
//                       border: Border.all(color: const Color(0xFF22222B)),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding: const EdgeInsets.all(4),
//                     child: Row(
//                       children: [
//                         _buildTab('Weekly', true),
//                         _buildTab('Monthly', false),
//                         _buildTab('Yearly', false),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const Text(
//                 'On-time in last 7 days',
//                 style: TextStyle(
//                   color: TawaqTheme.muted,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             height: 10,
//             decoration: BoxDecoration(
//               color: const Color(0xFF22242C),
//               borderRadius: BorderRadius.circular(999),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: 0.4,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [TawaqTheme.accent, Color(0xFF22C55E)],
//                   ),
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             crossAxisCount: 5,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             childAspectRatio: 1.2,
//             mainAxisSpacing: 10,
//             crossAxisSpacing: 10,
//             children: [
//               _buildKPI('Current Streak', '0 days'),
//               _buildKPI('Best Streak', '1 day'),
//               _buildKPI('Jamaah Rate', '40%'),
//               _buildKPI('Late Rate', '0%'),
//               _buildKPI('Missed Rate', '60%'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopLayout() {
//     return FScaffold(
//       sidebar: _buildSidebar(),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _buildTopBar(),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Expanded(
//                     flex: 12,
//                     child: Column(
//                       children: [
//                         NextPrayerCard(),
//                         SizedBox(height: 16),
//                         Expanded(child: PrayerScheduleCard()),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     flex: 10,
//                     child: Column(
//                       children: [
//                         _buildAnalyticsCard(),
//                         const SizedBox(height: 16),
//                         _buildTrackerCard(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKPI(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: TawaqTheme.panel2,
//         border: Border.all(color: const Color(0xFF22222B)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: TawaqTheme.muted,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: const TextStyle(
//               color: TawaqTheme.textColor,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMobileLayout() {
//     return FScaffold(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTopBar(),
//             const SizedBox(height: 16),
//             const NextPrayerCard(),
//             const SizedBox(height: 16),
//             const PrayerScheduleCard(),
//             const SizedBox(height: 16),
//             _buildAnalyticsCard(),
//             const SizedBox(height: 16),
//             _buildTrackerCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSidebar() {
//     return FSidebar(
//       width: 260,
//       header: const Padding(
//         padding: EdgeInsets.all(16),
//         child: Row(
//           children: [
//             BrandBadge(),
//             SizedBox(width: 12),
//             Text(
//               'Tawaq',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.4,
//               ),
//             ),
//           ],
//         ),
//       ),
//       footer: const Padding(
//         padding: EdgeInsets.all(16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             VersionChip(),
//             ThemeToggleButton(),
//           ],
//         ),
//       ),
//       children: [
//         FSidebarGroup(
//           children: [
//             FSidebarItem(
//               icon: const Text('🕰️'),
//               label: const Text('Prayer Times'),
//               selected: true,
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('📖'),
//               label: const Text('Holy Quran'),
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('🛡️'),
//               label: const Text('Muslim Fortress'),
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('🔔'),
//               label: const Text('Remembrance'),
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('📜'),
//               label: const Text('Hadith'),
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('⚙️'),
//               label: const Text('Settings'),
//               onPress: () {},
//             ),
//             FSidebarItem(
//               icon: const Text('ℹ️'),
//               label: const Text('About'),
//               onPress: () {},
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatChip(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: TawaqTheme.panel,
//         border: Border.all(color: const Color(0xFF22222B)),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.35),
//             blurRadius: 30,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: RichText(
//         text: TextSpan(
//           style: const TextStyle(color: TawaqTheme.muted, fontSize: 12),
//           children: [
//             TextSpan(text: label),
//             TextSpan(
//               text: ' $value',
//               style: const TextStyle(
//                 color: TawaqTheme.textColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTab(String text, bool isActive) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF101318) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//         border: isActive
//             ? Border.all(color: TawaqTheme.primary.withOpacity(0.25), width: 2)
//             : null,
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: isActive ? TawaqTheme.textColor : TawaqTheme.muted,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   Widget _buildTopBar() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Location selector
//         GlassyCard(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('📍'),
//               const SizedBox(width: 10),
//               Material(
//                 child: DropdownButton<String>(
//                   value: 'Riyadh, Saudi Arabia',
//                   underline: const SizedBox(),
//                   dropdownColor: TawaqTheme.panel,
//                   style: const TextStyle(color: TawaqTheme.textColor),
//                   items: const [
//                     DropdownMenuItem(
//                       value: 'Riyadh, Saudi Arabia',
//                       child: Text('Riyadh, Saudi Arabia'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'Jeddah, Saudi Arabia',
//                       child: Text('Jeddah, Saudi Arabia'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'Mecca, Saudi Arabia',
//                       child: Text('Mecca, Saudi Arabia'),
//                     ),
//                   ],
//                   onChanged: (value) {},
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Stats chips
//         Wrap(
//           spacing: 10,
//           children: [
//             _buildStatChip('On-time rate:', '40%'),
//             _buildStatChip('Current streak:', '0 days'),
//             _buildStatChip('Best streak:', '1 day'),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTrackerCard() {
//     return GlassyCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Prayer Tracker',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: TawaqTheme.textColor,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 'Click a prayer to mark it as completed',
//                 style: TextStyle(
//                   color: TawaqTheme.muted,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             crossAxisCount: 3,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             childAspectRatio: 1.1,
//             mainAxisSpacing: 12,
//             crossAxisSpacing: 12,
//             children: [
//               _buildTrackerItem(
//                   'Fajr', '04:35 AM', '5 hours ago', PrayerStatus.completed),
//               _buildTrackerItem(
//                   'Dhuhr', '12:29 PM', '1 hour left', PrayerStatus.current),
//               _buildTrackerItem(
//                   'Asr', '03:49 PM', '5 hours left', PrayerStatus.upcoming),
//               _buildTrackerItem(
//                   'Maghrib', '07:01 PM', '8 hours left', PrayerStatus.upcoming),
//               _buildTrackerItem(
//                   'Isha', '08:31 PM', '10 hours left', PrayerStatus.missed),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTrackerItem(
//       String name, String time, String timeLeft, PrayerStatus status) {
//     Color statusColor;
//     String statusText;

//     switch (status) {
//       case PrayerStatus.completed:
//         statusColor = TawaqTheme.ok;
//         statusText = 'OK';
//         break;
//       case PrayerStatus.current:
//         statusColor = TawaqTheme.warn;
//         statusText = 'LATE';
//         break;
//       case PrayerStatus.missed:
//         statusColor = TawaqTheme.danger;
//         statusText = 'MISSED';
//         break;
//       case PrayerStatus.upcoming:
//         statusColor = TawaqTheme.ok;
//         statusText = 'OK';
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: TawaqTheme.panel2,
//         border: Border.all(color: const Color(0xFF22222B)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: TawaqTheme.textColor,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.15),
//                   border: Border.all(color: statusColor.withOpacity(0.4)),
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Text(
//                   statusText,
//                   style: TextStyle(
//                     color: statusColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Adhan',
//             style: TextStyle(
//               color: TawaqTheme.muted,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             time,
//             style: const TextStyle(
//               color: TawaqTheme.textColor,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             'Time left',
//             style: TextStyle(
//               color: TawaqTheme.muted,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             timeLeft,
//             style: const TextStyle(
//               color: TawaqTheme.textColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TawaqApp extends StatelessWidget {
//   const TawaqApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Tawaq - Prayer Companion',
//       theme: ThemeData.dark(),
//       builder: (context, child) => FTheme(
//         data: TawaqTheme.darkTheme,
//         child: child!,
//       ),
//       home: const PrayerTimesScreen(),
//     );
//   }
// }

// class TawaqTheme {
//   static const Color bg = Color(0xFF0F0F12);
//   static const Color panel = Color(0xFF17171C);
//   static const Color panel2 = Color(0xFF1D1D23);
//   static const Color muted = Color(0xFF9AA0A6);
//   static const Color textColor = Color(0xFFF1F5F9);
//   static const Color primary = Color(0xFFFFD166);
//   static const Color primary700 = Color(0xFFD9B150);
//   static const Color accent = Color(0xFF6EE7B7);
//   static const Color danger = Color(0xFFF87171);
//   static const Color ok = Color(0xFF34D399);
//   static const Color warn = Color(0xFFFBBF24);

//   static FThemeData get darkTheme => FThemeData(
//         colors: const FColors(
//           brightness: Brightness.dark,
//           background: bg,
//           foreground: textColor,
//           primary: primary,
//           primaryForeground: Color(0xFF0F0F12),
//           secondary: panel,
//           secondaryForeground: textColor,
//           muted: panel2,
//           mutedForeground: muted,
//           destructive: danger,
//           destructiveForeground: textColor,
//           border: Color(0xFF22222B),
//           // Missing required properties:
//           systemOverlayStyle: SystemUiOverlayStyle(),
//           barrier: Colors.black54,
//           error: danger,
//           errorForeground: textColor,
//         ),
//         cardStyle: FCardStyle(
//           decoration: BoxDecoration(
//             color: panel,
//             border: Border.all(color: const Color(0xFF22222B)),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.35),
//                 blurRadius: 30,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           contentStyle: const FCardContentStyle(
//             titleTextStyle: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//             subtitleTextStyle: TextStyle(
//               fontSize: 14,
//               color: muted,
//             ),
//           ),
//         ),
//       );
// }

// class ThemeToggleButton extends StatelessWidget {
//   const ThemeToggleButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF1F2937),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: FButton(
//         onPress: () {
//           // Theme toggle logic would go here
//         },
//         child: const Text('🌗'),
//       ),
//     );
//   }
// }

// class TimeChip extends StatelessWidget {
//   final String label;
//   final String value;

//   const TimeChip({super.key, required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: const Color(0xFF121318).withOpacity(0.77),
//         border: Border.all(color: const Color(0xFF2A2A33)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: TawaqTheme.muted,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               color: TawaqTheme.textColor,
//               fontWeight: FontWeight.w700,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VersionChip extends StatelessWidget {
//   const VersionChip({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1F2937),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: const Text(
//         'v2.0 Prototype',
//         style: TextStyle(
//           color: TawaqTheme.muted,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }
