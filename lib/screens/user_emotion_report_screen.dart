import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/messaging_service.dart';
import '../models/message.dart';
import '../models/user.dart';

class UserEmotionReportScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserEmotionReportScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  _UserEmotionReportScreenState createState() => _UserEmotionReportScreenState();
}

class _UserEmotionReportScreenState extends State<UserEmotionReportScreen> {
  String _selectedPeriod = '30 Days';
  final List<String> _periods = ['7 Days', '30 Days', '3 Months', 'All Time'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${widget.userName}\'s Progress Report'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print report feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<MessagingService>(
        builder: (context, messagingService, child) {
          return StreamBuilder<List<Conversation>>(
            stream: messagingService.getConversationsForUser(
              widget.userId,
              UserRole.user,
            ),
            builder: (context, conversationSnapshot) {
              if (conversationSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final conversations = conversationSnapshot.data ?? [];
              final allMessages = <Message>[];
              
              for (var conv in conversations) {
                allMessages.addAll(conv.messages.where((m) => m.senderId == widget.userId));
              }

              if (allMessages.isEmpty) {
                return _buildEmptyState();
              }

              final filteredMessages = _filterMessagesByPeriod(allMessages, _selectedPeriod);
              final progressData = _analyzeProgress(filteredMessages);
              final issuesTimeline = _categorizeIssues(filteredMessages);
              final avgUrgency = _calculateAverageUrgency(filteredMessages);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Text(
                            'Report Period:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _selectedPeriod,
                            underline: const SizedBox(),
                            items: _periods.map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Overall Health Status
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getStatusGradient(avgUrgency),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatusIcon(avgUrgency),
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Overall Mental Health Status',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStatusText(avgUrgency),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getStatusDescription(avgUrgency),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Session Summary
                    Text(
                      'Session Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Messages',
                            filteredMessages.length.toString(),
                            Icons.message,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Days Active',
                            _calculateActiveDays(filteredMessages).toString(),
                            Icons.calendar_today,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Avg Urgency',
                            '${(avgUrgency * 100).toInt()}%',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Issues Timeline
                    Text(
                      'Issues Discussed Over Time',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: issuesTimeline.entries.map((entry) {
                          return _buildIssueProgressItem(
                            entry.key,
                            entry.value['initial']!,
                            entry.value['recent']!,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Progress Graph
                    Text(
                      'Emotional Well-being Trend',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: _buildProgressGraph(progressData),
                    ),

                    const SizedBox(height: 24),

                    // Clinical Notes
                    Text(
                      'Progress Notes & Recommendations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNoteSection(
                            '✅ Positive Progress',
                            _getPositiveNotes(progressData, issuesTimeline),
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildNoteSection(
                            '⚠️ Areas of Concern',
                            _getAreasOfConcern(avgUrgency, issuesTimeline),
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildNoteSection(
                            '💡 Treatment Recommendations',
                            _getTreatmentPlan(avgUrgency, issuesTimeline),
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Message> _filterMessagesByPeriod(List<Message> messages, String period) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case '7 Days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case '30 Days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3 Months':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      default:
        return messages;
    }

    return messages.where((m) => m.timestamp.isAfter(cutoffDate)).toList();
  }

  Map<DateTime, double> _analyzeProgress(List<Message> messages) {
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    Map<DateTime, List<double>> dailyScores = {};
    
    for (var msg in messages) {
      final day = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      dailyScores.putIfAbsent(day, () => []);
      dailyScores[day]!.add(1 - msg.urgencyScore); // Invert: higher = better
    }
    
    return dailyScores.map((date, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(date, avg);
    });
  }

  Map<String, Map<String, int>> _categorizeIssues(List<Message> messages) {
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final issues = <String, Map<String, int>>{};
    final midPoint = messages.length ~/ 2;
    
    final categories = {
      'Anxiety/Stress': ['😰', '😤', '🌊'],
      'Depression/Sadness': ['😢', '😔', '💔'],
      'Social Issues': ['😔', '🫂'],
      'Emotional Support': ['💚', '🌟', '💪'],
    };
    
    for (var entry in categories.entries) {
      final initialCount = messages
          .take(midPoint)
          .where((m) => m.aiEmojis.any((e) => entry.value.contains(e)))
          .length;
      
      final recentCount = messages
          .skip(midPoint)
          .where((m) => m.aiEmojis.any((e) => entry.value.contains(e)))
          .length;
      
      if (initialCount > 0 || recentCount > 0) {
        issues[entry.key] = {'initial': initialCount, 'recent': recentCount};
      }
    }
    
    return issues;
  }

  double _calculateAverageUrgency(List<Message> messages) {
    if (messages.isEmpty) return 0.0;
    return messages.fold<double>(0.0, (sum, m) => sum + m.urgencyScore) / messages.length;
  }

  int _calculateActiveDays(List<Message> messages) {
    if (messages.isEmpty) return 0;
    final days = messages.map((m) => DateTime(
      m.timestamp.year,
      m.timestamp.month,
      m.timestamp.day,
    )).toSet();
    return days.length;
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueProgressItem(String issue, int initial, int recent) {
    final improvement = initial > 0 ? ((initial - recent) / initial * 100) : 0.0;
    final isImproved = recent < initial;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                issue,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isImproved ? Icons.trending_down : Icons.trending_up,
                    size: 16,
                    color: isImproved ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isImproved 
                        ? '${improvement.abs().toInt()}% better'
                        : '${improvement.abs().toInt()}% increase',
                    style: TextStyle(
                      fontSize: 12,
                      color: isImproved ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Initial: $initial mentions',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: initial / 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(Colors.orange.shade300),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent: $recent mentions',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: recent / 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        isImproved ? Colors.green.shade400 : Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressGraph(Map<DateTime, double> progressData) {
    if (progressData.isEmpty) {
      return const Center(child: Text('Not enough data for trend analysis'));
    }

    final sortedData = progressData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (sortedData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedData.length) return const Text('');
                final date = sortedData[value.toInt()].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green.shade600,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade200.withOpacity(0.3),
                  Colors.green.shade100.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: 1,
      ),
    );
  }

  Widget _buildNoteSection(String title, List<String> notes, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...notes.map((note) => Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: TextStyle(color: color, fontSize: 16)),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.userName} hasn\'t sent any messages yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(double urgency) {
    if (urgency >= 0.7) return [Colors.red.shade700, Colors.red.shade500];
    if (urgency >= 0.5) return [Colors.orange.shade700, Colors.orange.shade500];
    if (urgency >= 0.3) return [Colors.amber.shade700, Colors.amber.shade500];
    return [Colors.green.shade700, Colors.green.shade500];
  }

  IconData _getStatusIcon(double urgency) {
    if (urgency >= 0.7) return Icons.warning;
    if (urgency >= 0.5) return Icons.error_outline;
    if (urgency >= 0.3) return Icons.info_outline;
    return Icons.check_circle;
  }

  String _getStatusText(double urgency) {
    if (urgency >= 0.7) return 'Critical';
    if (urgency >= 0.5) return 'Needs Attention';
    if (urgency >= 0.3) return 'Stable';
    return 'Improving';
  }

  String _getStatusDescription(double urgency) {
    if (urgency >= 0.7) {
      return 'Client is experiencing high levels of distress. Immediate intervention and daily monitoring recommended.';
    } else if (urgency >= 0.5) {
      return 'Client showing moderate emotional challenges. Increase session frequency and implement coping strategies.';
    } else if (urgency >= 0.3) {
      return 'Client is managing emotions with support. Continue regular counseling and monitor progress.';
    }
    return 'Client demonstrating positive progress. Maintain current treatment plan and encourage self-care practices.';
  }

  List<String> _getPositiveNotes(Map<DateTime, double> progress, Map<String, Map<String, int>> issues) {
    final notes = <String>[];
    
    if (progress.length >= 2) {
      final first = progress.entries.first.value;
      final last = progress.entries.last.value;
      if (last > first) {
        final improvement = ((last - first) * 100).toInt();
        notes.add('Overall well-being improved by $improvement% during this period');
      }
    }
    
    issues.forEach((issue, counts) {
      if (counts['recent']! < counts['initial']!) {
        notes.add('Significant reduction in $issue mentions');
      }
    });
    
    if (notes.isEmpty) {
      notes.add('Client is actively engaging in counseling sessions');
      notes.add('Showing willingness to share and express emotions');
    }
    
    return notes;
  }

  List<String> _getAreasOfConcern(double urgency, Map<String, Map<String, int>> issues) {
    final concerns = <String>[];
    
    if (urgency >= 0.7) {
      concerns.add('High urgency levels detected - requires immediate attention');
    }
    
    issues.forEach((issue, counts) {
      if (counts['recent']! > counts['initial']!) {
        concerns.add('Increase in $issue - requires focused intervention');
      }
    });
    
    if (concerns.isEmpty) {
      concerns.add('Continue monitoring for any emerging patterns');
    }
    
    return concerns;
  }

  List<String> _getTreatmentPlan(double urgency, Map<String, Map<String, int>> issues) {
    final plan = <String>[];
    
    if (urgency >= 0.7) {
      plan.add('Schedule emergency session within 24 hours');
      plan.add('Consider crisis intervention protocols');
      plan.add('Daily check-ins for next 7 days');
    } else if (urgency >= 0.5) {
      plan.add('Increase session frequency to twice weekly');
      plan.add('Implement cognitive behavioral therapy techniques');
      plan.add('Introduce stress management exercises');
    } else {
      plan.add('Maintain weekly counseling sessions');
      plan.add('Continue building coping mechanisms');
      plan.add('Encourage journaling and self-reflection');
    }
    
    if (issues.containsKey('Anxiety/Stress')) {
      plan.add('Focus on relaxation and breathing exercises');
    }
    if (issues.containsKey('Depression/Sadness')) {
      plan.add('Explore mood-lifting activities and social connections');
    }
    
    return plan;
  }
}