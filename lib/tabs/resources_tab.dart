import 'package:flutter/material.dart';
import 'dart:math';

class ResourcesTab extends StatefulWidget {
  @override
  _ResourcesTabState createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  String _selectedCategory = 'All';
  final _random = Random();

  final Map<String, CategoryData> _categories = {
    'Resilience & Strength': CategoryData(
      icon: Icons.favorite,
      gradientColors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)], // Candy Apple Red
      quotes: [
        "Sometimes the bravest thing you can do is rest.",
        "Healing is not linear, it's a spiral.",
        "Your scars are proof that you fought back.",
        "Resilience is built in the moments you thought you couldn't go on, but did anyway.",
        "The cracks in your life don't mean you're broken; they mean you're human.",
        "Strength isn't never falling, it's rising every single time.",
        "You don't have to be fearless, you just have to keep moving.",
        "Tough times don't define you, they reveal you.",
        "Resilience is silent, but its echoes last a lifetime.",
        "Bending is not the same as breaking.",
        "Every mountain climbed once looked impossible.",
        "What you endure becomes your armor.",
        "Hard days build hidden strength.",
        "You have survived 100% of your worst days.",
        "Your strength grows in the shadows, not in the spotlight.",
      ],
    ),
    'Self-Compassion': CategoryData(
      icon: Icons.self_improvement,
      gradientColors: [Color(0xFFFFB5C5), Color(0xFFFFD4E0)], // Powder Pink
      quotes: [
        "Speak to yourself as you would to someone you love. – Brené Brown",
        "Rest is not idleness, it's self-respect.",
        "Be kind to yourself, you're still learning.",
        "You are not behind; you are at your own pace.",
        "Give yourself the grace you give to others.",
        "Self-compassion is not selfishness, it's survival.",
        "Gentleness with yourself is strength.",
        "You are enough, without proving it.",
        "Even your mistakes deserve kindness.",
        "Don't punish yourself for being human.",
        "You can't hate yourself into healing.",
        "Compassion begins with the person in the mirror.",
        "Be patient with your own unfolding.",
        "Healing blooms faster in kindness.",
        "Self-love is a revolution against despair.",
      ],
    ),
    'Perspective & Growth': CategoryData(
      icon: Icons.trending_up,
      gradientColors: [Color(0xFFFFE66D), Color(0xFFF9DB6D)], // Butter Yellow
      quotes: [
        "Your current chapter is not your whole story.",
        "Change is painful, but nothing is as painful as staying stuck. – Mandy Hale",
        "You are not starting over, you are starting wiser.",
        "Every ending is also a beginning.",
        "The wound is the place the light enters you. – Rumi",
        "Life grows in seasons, not straight lines.",
        "Your struggles are teachers in disguise.",
        "What feels like falling apart can be the start of becoming whole.",
        "Pain reshapes us into people we didn't know we could be.",
        "Growth often hides inside discomfort.",
        "Every scar carries wisdom.",
        "Change is proof you are alive.",
        "Broken ground is where new roots grow.",
        "Your lowest points prepare you for higher ones.",
        "The hardest battles grow the deepest wisdom.",
      ],
    ),
    'Hope & Encouragement': CategoryData(
      icon: Icons.wb_sunny,
      gradientColors: [Color(0xFF87CEEB), Color(0xFF9ED8E8)], // Sky Blue
      quotes: [
        "Even the darkest night will end, and the sun will rise. – Victor Hugo",
        "You've survived so much already—don't stop here.",
        "Keep breathing. That's all you need to start again.",
        "Hope is the quiet whisper that tomorrow can be different.",
        "Your story isn't finished yet.",
        "One tiny step forward is still movement.",
        "The fact that you are here means there is still possibility.",
        "Hope doesn't always shout, sometimes it just stays.",
        "You are allowed to imagine a softer future.",
        "Your survival is proof of your strength.",
        "Even in the ashes, something can grow.",
        "Every sunrise is an invitation to begin again.",
        "Hope is stronger than fear.",
        "Your existence itself is a reason for hope.",
        "The light always remembers its way back.",
      ],
    ),
    'Mindset & Mental Clarity': CategoryData(
      icon: Icons.psychology,
      gradientColors: [Color(0xFFFF7F50), Color(0xFFFF9F80)], // Sunset Coral
      quotes: [
        "Don't believe everything you think.",
        "You don't have to control your thoughts, only how you respond. – Dan Millman",
        "Peace begins when you stop wrestling with your mind.",
        "Thoughts are visitors, you don't need to serve them tea.",
        "Where focus goes, energy flows. – Tony Robbins",
        "Your mind will believe what you feed it.",
        "Clarity comes in the quiet.",
        "What consumes your mind, controls your life.",
        "Stillness is strength, not weakness.",
        "You are not your thoughts, you are the observer of them.",
        "Peace is choosing not to argue with reality.",
        "The storm in your head is not the truth of who you are.",
        "Let your thoughts pass like clouds, not anchors.",
        "The calmer the mind, the clearer the path.",
        "Freedom begins in the mind.",
      ],
    ),
  };

  List<QuoteItem> _getFilteredQuotes() {
    List<QuoteItem> allQuotes = [];
    
    if (_selectedCategory == 'All') {
      _categories.forEach((category, data) {
        for (var quote in data.quotes) {
          allQuotes.add(QuoteItem(
            quote: quote,
            category: category,
            gradientColors: data.gradientColors,
            icon: data.icon,
          ));
        }
      });
      allQuotes.shuffle(_random);
    } else {
      final data = _categories[_selectedCategory]!;
      for (var quote in data.quotes) {
        allQuotes.add(QuoteItem(
          quote: quote,
          category: _selectedCategory,
          gradientColors: data.gradientColors,
          icon: data.icon,
        ));
      }
    }
    
    return allQuotes;
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _getFilteredQuotes();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Resources'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Choose Your Focus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _buildCategoryChip('All', Icons.all_inclusive, [Colors.purple.shade400, Colors.purple.shade600]),
                      ..._categories.entries.map((entry) {
                        return _buildCategoryChip(
                          entry.key,
                          entry.value.icon,
                          entry.value.gradientColors,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quote Count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Icon(Icons.format_quote, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  '${quotes.length} ${quotes.length == 1 ? 'quote' : 'quotes'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Quotes Grid
          Expanded(
            child: quotes.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.3 : 1.5,
                    ),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      return _buildQuoteCard(quotes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, List<Color> colors) {
    final isSelected = _selectedCategory == label;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors[0],
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors[0],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: colors[0].withOpacity(0.1),
        selectedColor: colors[0],
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? colors[0] : colors[0].withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildQuoteCard(QuoteItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.gradientColors[0].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showQuoteDialog(item);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.format_quote,
                      size: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      item.quote,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuoteDialog(QuoteItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                item.quote,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Quote saved to your favorites!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: item.gradientColors[0],
                        ),
                      );
                    },
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    label: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sharing feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: item.gradientColors[0],
                        ),
                      );
                    },
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text('Share', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No quotes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryData {
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> quotes;

  CategoryData({
    required this.icon,
    required this.gradientColors,
    required this.quotes,
  });
}

class QuoteItem {
  final String quote;
  final String category;
  final List<Color> gradientColors;
  final IconData icon;

  QuoteItem({
    required this.quote,
    required this.category,
    required this.gradientColors,
    required this.icon,
  });
}