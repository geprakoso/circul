import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

export 'core/constants.dart';

const avatarAsset = 'assets/images/avatar_sarah.png';
const zeroWasteAsset = 'assets/images/post_zero_waste.png';
const booksAsset = 'assets/images/post_books.png';
const cleanupAsset = 'assets/images/activity_cleanup.png';

class FeedPost {
  const FeedPost({
    this.id = '',
    required this.author,
    required this.city,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.imageAsset,
    required this.likes,
    required this.comments,
    this.createdAt,
    this.topic = '',
    this.imagePaths = const [],
    this.locationEnabled = false,
    this.locationLabel,
    this.coordinateLabel,
    this.locationLatitude,
    this.locationLongitude,
    this.checkoutCompleted = false,
  });

  final String id;
  final String author;
  final String city;
  final String timeAgo;
  final String title;
  final String body;
  final String imageAsset;
  final DateTime? createdAt;
  final String topic;
  final List<String> imagePaths;
  final bool locationEnabled;
  final String? locationLabel;
  final String? coordinateLabel;
  final double? locationLatitude;
  final double? locationLongitude;
  final bool checkoutCompleted;
  final int likes;
  final int comments;

  LatLng? get locationPoint {
    final latitude = locationLatitude;
    final longitude = locationLongitude;
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }

    final coordinateParts = coordinateLabel?.split(',');
    if (coordinateParts == null || coordinateParts.length != 2) return null;

    final parsedLatitude = double.tryParse(coordinateParts.first.trim());
    final parsedLongitude = double.tryParse(coordinateParts.last.trim());
    if (parsedLatitude == null || parsedLongitude == null) return null;
    return LatLng(parsedLatitude, parsedLongitude);
  }

  FeedPost copyWith({
    String? id,
    String? author,
    String? city,
    String? timeAgo,
    String? title,
    String? body,
    String? imageAsset,
    DateTime? createdAt,
    String? topic,
    List<String>? imagePaths,
    bool? locationEnabled,
    String? locationLabel,
    String? coordinateLabel,
    double? locationLatitude,
    double? locationLongitude,
    bool? checkoutCompleted,
    int? likes,
    int? comments,
  }) {
    return FeedPost(
      id: id ?? this.id,
      author: author ?? this.author,
      city: city ?? this.city,
      timeAgo: timeAgo ?? this.timeAgo,
      title: title ?? this.title,
      body: body ?? this.body,
      imageAsset: imageAsset ?? this.imageAsset,
      createdAt: createdAt ?? this.createdAt,
      topic: topic ?? this.topic,
      imagePaths: imagePaths ?? this.imagePaths,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      locationLabel: locationLabel ?? this.locationLabel,
      coordinateLabel: coordinateLabel ?? this.coordinateLabel,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      checkoutCompleted: checkoutCompleted ?? this.checkoutCompleted,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
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

class PostComment {
  const PostComment({
    this.id = '',
    this.postId = '',
    required this.author,
    required this.timeAgo,
    required this.body,
    required this.initials,
    required this.avatarColor,
    this.likes = 0,
    this.locationEnabled = false,
    this.locationLabel,
    this.coordinateLabel,
    this.locationLatitude,
    this.locationLongitude,
  });

  final String id;
  final String postId;
  final String author;
  final String timeAgo;
  final String body;
  final String initials;
  final Color avatarColor;
  final int likes;
  final bool locationEnabled;
  final String? locationLabel;
  final String? coordinateLabel;
  final double? locationLatitude;
  final double? locationLongitude;
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
    topic: 'Zero Waste',
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
    topic: 'Edukasi Lingkungan',
    likes: 98,
    comments: 16,
  ),
];

const postComments = [
  PostComment(
    author: 'CaterineWilz',
    timeAgo: 'Baru saja',
    body: 'Wow bagus sekali, bisa belajar bersama kayak gitu.',
    initials: 'CW',
    avatarColor: Color(0xFFE98B64),
  ),
  PostComment(
    author: 'MillianJanesa',
    timeAgo: 'Baru saja',
    body: 'Pengen deh kayak gitu....',
    initials: 'MJ',
    avatarColor: Color(0xFF86A9A8),
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
