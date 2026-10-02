import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';

class CustomerReviewsScreen extends StatefulWidget {
  const CustomerReviewsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerReviewsScreen> createState() => _CustomerReviewsScreenState();
}

class _CustomerReviewsScreenState extends State<CustomerReviewsScreen> {
  bool isLoading = false;

  // Review data with fallback defaults
  final Map<String, dynamic> reviewData = {
    "overallRating": 4.5,
    "totalReviews": 0,
    "ratingDistribution": {
      "excellent": 0.65,
      "good": 0.20,
      "average": 0.10,
      "poor": 0.05
    },
    "reviews": <Map<String, dynamic>>[]
  };

  @override
  void initState() {
    super.initState();
    _fetchRatingsReviews();
  }

  Future<void> _fetchRatingsReviews() async {
    final userDataStr = Preferences.getUserDetails();
    if (userDataStr == null) return;
    String? providerId;
    try {
      final user = json.decode(userDataStr);
      providerId = (user['user_id'] ?? user['id'])?.toString();
    } catch (_) {}
    if (providerId == null || providerId.isEmpty) return;

    if (!await UtilClass.checkInternet()) return;

    setState(() => isLoading = true);
    try {
      final response = await Repository.postApiService(
        EndPoints.providerRatingsReviews,
        {"provider_id": providerId},
      );
      final dynamic parsed =
          response is String ? json.decode(response) : response;
      if (parsed is Map<String, dynamic> &&
          (parsed["status"] == "valid" || parsed["status"] == true)) {
        final dynamic rawReviews = parsed["reviews"] ?? parsed["data"] ?? [];
        final dynamic overall =
            parsed["overall_rating"] ?? parsed["rating"] ?? parsed["average_rating"];
        final dynamic total =
            parsed["total_reviews"] ?? parsed["count"];

        if (mounted) {
          setState(() {
            if (overall != null) {
              reviewData["overallRating"] =
                  double.tryParse(overall.toString()) ?? 4.5;
            }
            if (rawReviews is List) {
              reviewData["totalReviews"] =
                  int.tryParse(total?.toString() ?? "") ?? rawReviews.length;
              if (rawReviews.isNotEmpty) {
                reviewData["reviews"] = rawReviews.map((r) {
                  return {
                    "id": r["id"] ?? 0,
                    "userName": r["user_name"] ??
                        r["customer_name"] ??
                        r["name"] ??
                        "Customer",
                    "userImage": r["profile"] ??
                        r["user_image"] ??
                        "https://via.placeholder.com/50",
                    "rating":
                        double.tryParse(r["rating"]?.toString() ?? "5.0") ?? 5.0,
                    "timeAgo": r["date"] ??
                        r["created_at"] ??
                        r["time_ago"] ??
                        "",
                    "comment": r["review"] ??
                        r["comment"] ??
                        r["feedback"] ??
                        "",
                  };
                }).toList();
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallRatingSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),
              _buildRatingDistribution(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.04),
              _buildCustomerReviewsSection(screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7CB342), Color(0xFF8BC34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: const Text(
        'Customers Ratings & Reviews',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildOverallRatingSection(double screenWidth, double screenHeight) {
    final overallRating = reviewData['overallRating'].toDouble();

    return Center(
      child: Column(
        children: [
          const Text(
            'Over All Rating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            overallRating.toString(),
            style: TextStyle(
              fontSize: screenWidth * 0.25,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
              height: 1.0,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          _buildStarRating(overallRating, size: 28),
          SizedBox(height: screenHeight * 0.01),
          const Text(
            'Based on all reviews',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(double screenWidth, double screenHeight) {
    final distribution = reviewData['ratingDistribution'] as Map<String, dynamic>;

    return Column(
      children: [
        _buildRatingBar('Excellent', distribution['excellent'], screenWidth),
        SizedBox(height: screenHeight * 0.015),
        _buildRatingBar('Good', distribution['good'], screenWidth),
        SizedBox(height: screenHeight * 0.015),
        _buildRatingBar('Average', distribution['average'], screenWidth),
        SizedBox(height: screenHeight * 0.015),
        _buildRatingBar('Poor', distribution['poor'], screenWidth),
      ],
    );
  }

  Widget _buildRatingBar(String label, double percentage, double screenWidth) {
    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.18,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerReviewsSection(double screenWidth, double screenHeight) {
    final reviews = reviewData['reviews'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customers Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
          )
        else if (reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No reviews available yet.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: screenHeight * 0.025),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(review, screenWidth, screenHeight);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildUserAvatar(review['userName'], screenWidth),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        _buildStarRating(review['rating'].toDouble(), size: 16),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          '(${review['rating']})',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: const Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                review['timeAgo'],
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              color: const Color(0xFF7F8C8D),
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String userName, double screenWidth) {
    final initials = userName.split(' ').map((name) => name[0]).join().toUpperCase();
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFF00BCD4),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
    ];
    final colorIndex = userName.hashCode % colors.length;

    return Container(
      width: screenWidth * 0.12,
      height: screenWidth * 0.12,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: const Color(0xFFFFC107), size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: const Color(0xFFFFC107), size: size);
        } else {
          return Icon(Icons.star_border, color: const Color(0xFFE0E0E0), size: size);
        }
      }),
    );
  }
}

// Usage Example:
// To use this screen in your app:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CustomerReviewsScreen(),
  ),
);
*/