import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../state/app_state.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 统计'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📅 周统计'),
            Tab(text: '📈 月统计'),
            Tab(text: '🎉 年统计'),
          ],
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF1FF), Color(0xFFFDF7F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _WeeklyStatsView(state: state),
            _MonthlyStatsView(state: state),
            _YearlyStatsView(state: state),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatsView extends StatelessWidget {
  final AppState state;
  const _WeeklyStatsView({required this.state});

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totals = state.weeklyTotals;
    final max = (totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b)).toDouble();
    final c = Theme.of(context).colorScheme;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(context),
        const SizedBox(height: 20),
        _buildWeeklyChart(context, totals, max, c),
        const SizedBox(height: 20),
        _buildWeeklyHeatmap(context),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: '今日累计', value: _format(state.todayTotalSeconds), icon: '⏰')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '今日目标', value: _format(state.dailyGoalSeconds), icon: '🎯')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(title: '完成次数', value: '${state.todayCompletions} 次', icon: '✅')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '完成率', value: _getCompletionRate(), icon: '📈')),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<int> totals, double max, ColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊 本周趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('总计 ${_format(totals.fold(0, (a, b) => a + b))}', 
                  style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: max > 0 ? max * 1.2 : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => c.primary.withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _format(rod.toY.toInt()),
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['一', '二', '三', '四', '五', '六', '日'];
                        return Text(days[value.toInt()], style: TextStyle(color: c.outline, fontSize: 12));
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: max > 0 ? max / 4 : 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: c.outline.withValues(alpha: 0.1), strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(totals.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: totals[i].toDouble(),
                        gradient: LinearGradient(
                          colors: [c.primary, c.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHeatmap(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥 本周热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '平均 ${_format((state.weeklyTotals.reduce((a, b) => a + b) / 7).round())}',
                  style: TextStyle(color: c.secondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Week day labels
          Row(
            children: weekDays.map((day) => 
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 8),
          // Heatmap grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: List.generate(7, (i) {
              final intensity = state.weeklyTotals[i] / (state.weeklyTotals.reduce((a, b) => a > b ? a : b) + 1);
              final isToday = i == (now.weekday - 1);
              
              return Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Color.lerp(c.primary.withValues(alpha: 0.1), c.primary, intensity),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday 
                    ? Border.all(color: c.primary.withValues(alpha: 0.5), width: 2)
                    : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${state.weeklyTotals[i]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: intensity > 0.5 ? Colors.white : c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state.weeklyTotals[i] > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        width: 16,
                        decoration: BoxDecoration(
                          color: intensity > 0.7 ? Colors.white : c.secondary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              Text(
                '少',
                style: TextStyle(fontSize: 10, color: c.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 4),
              ...List.generate(4, (i) {
                final alpha = 0.1 + (i * 0.2);
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: alpha),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                '多',
                style: TextStyle(fontSize: 10, color: c.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCompletionRate() {
    if (state.dailyGoalSeconds == 0) return '0%';
    final rate = (state.todayTotalSeconds / state.dailyGoalSeconds * 100).clamp(0, 100);
    return '${rate.toStringAsFixed(0)}%';
  }
}

class _MonthlyStatsView extends StatelessWidget {
  final AppState state;
  const _MonthlyStatsView({required this.state});

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final monthlyData = _generateMonthlyData();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthlySummary(context, monthlyData),
        const SizedBox(height: 20),
        _buildMonthlyLineChart(context, monthlyData, c),
        const SizedBox(height: 20),
        _buildMonthlyHeatmap(context, monthlyData, c),
      ],
    );
  }

  Widget _buildMonthlySummary(BuildContext context, List<MonthlyData> data) {
    final totalSeconds = data.fold(0, (sum, d) => sum + d.totalSeconds);
    final totalCompletions = data.fold(0, (sum, d) => sum + d.completions);
    final avgDaily = data.isEmpty ? 0 : totalSeconds ~/ data.length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: '本月累计', value: _format(totalSeconds), icon: '📊')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '本月完成', value: '$totalCompletions 次', icon: '🎉')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(title: '日均时长', value: _format(avgDaily), icon: '⏱️')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '活跃天数', value: '${data.where((d) => d.totalSeconds > 0).length} 天', icon: '🔥')),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyLineChart(BuildContext context, List<MonthlyData> data, ColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈 本月趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('峰值 ${_format(data.map((d) => d.totalSeconds).fold(0, (a, b) => a > b ? a : b))}', 
                  style: TextStyle(color: c.secondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxValue(data) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: c.outline.withValues(alpha: 0.1), strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                          return Text('${value.toInt()}', style: TextStyle(color: c.outline, fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.map((d) => FlSpot(d.day.toDouble(), d.totalSeconds.toDouble())).toList(),
                    isCurved: true,
                    gradient: LinearGradient(colors: [c.primary, c.secondary]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: c.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [c.primary.withValues(alpha: 0.3), c.secondary.withValues(alpha: 0.1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: _getMaxValue(data) * 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHeatmap(BuildContext context, List<MonthlyData> data, ColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗓️ 月度热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              _buildHeatmapLegend(c),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: List.generate(30, (i) {
              final dayData = i < data.length ? data[i] : MonthlyData(i + 1, 0, 0);
              final intensity = dayData.totalSeconds / (_getMaxValue(data) + 1);
              return Tooltip(
                message: '${dayData.day}日: ${_format(dayData.totalSeconds)}',
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color.lerp(c.primary.withValues(alpha: 0.1), c.primary, intensity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      '${dayData.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: intensity > 0.5 ? Colors.white : c.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(ColorScheme c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('少', style: TextStyle(fontSize: 10, color: c.outline)),
        const SizedBox(width: 4),
        for (int i = 0; i < 5; i++) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color.lerp(c.primary.withValues(alpha: 0.1), c.primary, i / 4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 2),
        ],
        const SizedBox(width: 4),
        Text('多', style: TextStyle(fontSize: 10, color: c.outline)),
      ],
    );
  }

  List<MonthlyData> _generateMonthlyData() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List.generate(daysInMonth, (i) {
      final day = i + 1;
      final date = DateTime(now.year, now.month, day);
      final records = state.records.where((r) {
        final recordDate = r.at;
        return recordDate.year == date.year && 
               recordDate.month == date.month && 
               recordDate.day == date.day;
      }).toList();
      
      final totalSeconds = records.fold(0, (sum, r) => sum + r.seconds);
      return MonthlyData(day, totalSeconds, records.length);
    });
  }

  double _getMaxValue(List<MonthlyData> data) {
    return data.isEmpty ? 100 : data.map((d) => d.totalSeconds).fold(0, (a, b) => a > b ? a : b).toDouble();
  }
}

class _YearlyStatsView extends StatelessWidget {
  final AppState state;
  const _YearlyStatsView({required this.state});

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final yearlyData = _generateYearlyData();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildYearlySummary(context, yearlyData),
        const SizedBox(height: 20),
        _buildYearlyChart(context, yearlyData, c),
        const SizedBox(height: 20),
        _buildAchievements(context, yearlyData, c),
      ],
    );
  }

  Widget _buildYearlySummary(BuildContext context, List<YearlyData> data) {
    final totalSeconds = data.fold(0, (sum, d) => sum + d.totalSeconds);
    final totalCompletions = data.fold(0, (sum, d) => sum + d.completions);
    final avgMonthly = data.isEmpty ? 0 : totalSeconds ~/ data.length;
    final activeMonths = data.where((d) => d.totalSeconds > 0).length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: '年度累计', value: _format(totalSeconds), icon: '🏆')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '年度完成', value: '$totalCompletions 次', icon: '✨')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(title: '月均时长', value: _format(avgMonthly), icon: '📊')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(title: '活跃月份', value: '$activeMonths 个月', icon: '🎊')),
          ],
        ),
      ],
    );
  }

  Widget _buildYearlyChart(BuildContext context, List<YearlyData> data, ColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊 年度趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('最佳月份 ${_format(data.map((d) => d.totalSeconds).fold(0, (a, b) => a > b ? a : b))}', 
                  style: TextStyle(color: c.tertiary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue(data) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => c.tertiary.withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${data[group.x].month}月\n${_format(rod.toY.toInt())}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text('${value.toInt() + 1}月', style: TextStyle(color: c.outline, fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxValue(data) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: c.outline.withValues(alpha: 0.1), strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].totalSeconds.toDouble(),
                        gradient: LinearGradient(
                          colors: [c.primary, c.tertiary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List<YearlyData> data, ColorScheme c) {
    final achievements = _calculateAchievements(data);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆 年度成就', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (achievements.where((a) => a.unlocked).isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: SvgPicture.asset(
                'assets/illustrations/achievement.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: achievements.map((achievement) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: achievement.unlocked 
                      ? [c.primary.withValues(alpha: 0.1), c.secondary.withValues(alpha: 0.05)]
                      : [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: achievement.unlocked ? c.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(achievement.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(achievement.name, 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: achievement.unlocked ? c.primary : Colors.grey,
                      )),
                    const SizedBox(height: 2),
                    Text(achievement.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: achievement.unlocked ? c.outline : Colors.grey.withValues(alpha: 0.7),
                      )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<YearlyData> _generateYearlyData() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = i + 1;
      
      final monthRecords = state.records.where((r) {
        final recordDate = r.at;
        return recordDate.year == now.year && recordDate.month == month;
      }).toList();
      
      final totalSeconds = monthRecords.fold(0, (sum, r) => sum + r.seconds);
      return YearlyData(month, totalSeconds, monthRecords.length);
    });
  }

  double _getMaxValue(List<YearlyData> data) {
    return data.isEmpty ? 100 : data.map((d) => d.totalSeconds).fold(0, (a, b) => a > b ? a : b).toDouble();
  }

  List<Achievement> _calculateAchievements(List<YearlyData> data) {
    final totalSeconds = data.fold(0, (sum, d) => sum + d.totalSeconds);
    final totalCompletions = data.fold(0, (sum, d) => sum + d.completions);
    final activeMonths = data.where((d) => d.totalSeconds > 0).length;
    final maxMonthly = data.map((d) => d.totalSeconds).fold(0, (a, b) => a > b ? a : b);
    
    return [
      Achievement('🌟', '新手入门', '完成第一个任务', totalCompletions >= 1),
      Achievement('🔥', '连续活跃', '活跃超过3个月', activeMonths >= 3),
      Achievement('⚡', '高效达人', '单月完成超过10小时', maxMonthly >= 36000),
      Achievement('🏆', '年度之星', '年度累计超过50小时', totalSeconds >= 180000),
      Achievement('💎', '完美坚持', '全年12个月都活跃', activeMonths >= 12),
      Achievement('🚀', '超级成就', '年度完成超过100次', totalCompletions >= 100),
    ];
  }
}

class MonthlyData {
  final int day;
  final int totalSeconds;
  final int completions;
  
  MonthlyData(this.day, this.totalSeconds, this.completions);
}

class YearlyData {
  final int month;
  final int totalSeconds;
  final int completions;
  
  YearlyData(this.month, this.totalSeconds, this.completions);
}

class Achievement {
  final String emoji;
  final String name;
  final String description;
  final bool unlocked;
  
  Achievement(this.emoji, this.name, this.description, this.unlocked);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? icon;
  const _StatCard({required this.title, required this.value, this.icon});
  
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
          ],
          Text(title, style: TextStyle(color: c.onSurface.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
