import 'package:flutter/material.dart';

const kCirculGreen = Color(0xFF0B8F4D);
const kSoftGreen = Color(0xFFEFF8F2);
const kInk = Color(0xFF111827);
const kMuted = Color(0xFF6B7280);
const kLine = Color(0xFFE5E7EB);

const avatarAsset = 'assets/images/avatar_sarah.png';
const zeroWasteAsset = 'assets/images/post_zero_waste.png';
const booksAsset = 'assets/images/post_books.png';
const cleanupAsset = 'assets/images/activity_cleanup.png';

class FeedPost {
  const FeedPost({
    required this.author,
    required this.city,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.imageAsset,
    required this.likes,
    required this.comments,
    this.imagePaths = const [],
  });

  final String author;
  final String city;
  final String timeAgo;
  final String title;
  final String body;
  final String imageAsset;
  final List<String> imagePaths;
  final int likes;
  final int comments;
}

class Topic {
  const Topic(this.icon, this.title, this.count);

  final String icon;
  final String title;
  final String count;
}

class Achievement {
  const Achievement(this.icon, this.title, this.caption);

  final IconData icon;
  final String title;
  final String caption;
}

class ActivityItem {
  const ActivityItem({
    required this.category,
    required this.title,
    required this.distance,
    required this.time,
    required this.icon,
  });

  final String category;
  final String title;
  final String distance;
  final String time;
  final IconData icon;
}

const feedPosts = [
  FeedPost(
    author: 'sarahmae',
    city: 'Jakarta',
    timeAgo: '2 jam',
    title: 'Tips mengurangi sampah plastik di rumah 🌿',
    body:
        'Beberapa hal kecil yang aku lakukan dan lumayan berdampak. Yuk mulai bareng-bareng!',
    imageAsset: zeroWasteAsset,
    likes: 142,
    comments: 28,
  ),
  FeedPost(
    author: 'sarahmae',
    city: 'Bandung',
    timeAgo: '5 jam',
    title: 'Buku tentang lingkungan yang mengubah cara pandangku 📖',
    body:
        'Beberapa rekomendasi buku yang bikin aku lebih sadar dan termotivasi untuk hidup berkelanjutan.',
    imageAsset: booksAsset,
    likes: 98,
    comments: 16,
  ),
];

const topics = [
  Topic('🌱', 'Gaya Hidup Berkelanjutan', '12.4K post'),
  Topic('♻️', 'Daur Ulang', '8.7K post'),
  Topic('🛍️', 'Zero Waste', '6.2K post'),
  Topic('🌿', 'Tanaman & Kebun', '5.1K post'),
  Topic('🌎', 'Krisis Iklim', '4.8K post'),
  Topic('💡', 'Edukasi Lingkungan', '3.9K post'),
  Topic('👥', 'Komunitas Lokal', '3.2K post'),
  Topic('💧', 'Konservasi Air', '2.6K post'),
  Topic('🚲', 'Transportasi Hijau', '2.3K post'),
  Topic('🍴', 'Makanan Berkelanjutan', '1.9K post'),
];

const achievements = [
  Achievement(Icons.eco_rounded, 'Eco Starter', 'Mulai langkah pertama'),
  Achievement(
    Icons.recycling_rounded,
    'Zero Waste Warrior',
    'Aktif mengurangi sampah',
  ),
  Achievement(Icons.spa_rounded, 'Green Contributor', 'Berbagi dampak positif'),
  Achievement(Icons.groups_rounded, 'Community Builder', 'Membangun komunitas'),
];

const nearbyActivities = [
  ActivityItem(
    category: 'Event',
    title: 'Aksi Bersih Sungai Pepe',
    distance: '350 m dari lokasimu',
    time: '2 jam lalu',
    icon: Icons.event_available_rounded,
  ),
  ActivityItem(
    category: 'Sampah',
    title: 'Titik pilah botol plastik',
    distance: '500 m dari lokasimu',
    time: 'Hari ini',
    icon: Icons.delete_outline_rounded,
  ),
  ActivityItem(
    category: 'Kampanye',
    title: 'Tukar kantong kain komunitas',
    distance: '1.2 km dari lokasimu',
    time: 'Besok',
    icon: Icons.campaign_rounded,
  ),
];
