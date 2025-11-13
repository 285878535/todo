


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/nlp_parser.dart';
import '../state/app_state.dart';
import '../models/task.dart';

class NlpTaskDialog extends StatefulWidget {
  const NlpTaskDialog({super.key});

  @override
  State<NlpTaskDialog> createState() => _NlpTaskDialogState();
}

class _NlpTaskDialogState extends State<NlpTaskDialog> {
  final _controller = TextEditingController();
  TaskParseResult? _parseResult;
  bool _isParsing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseInput() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    // Simulate parsing delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _parseResult = NlpParser.parse(input);
          _isParsing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [c.primary.withValues(alpha: 0.05), c.secondary.withValues(alpha: 0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology, color: c.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '智能任务创建',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        '用自然语言描述你的任务',
                        style: TextStyle(
                          fontSize: 14,
                          color: c.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '例如: 明天下午3点开会30分钟 高优先级',
                hintStyle: TextStyle(color: c.outline.withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              minLines: 2,
              onChanged: (_) {
                if (_controller.text.trim().length > 2) {
                  _parseInput();
                } else {
                  setState(() {
                    _parseResult = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isParsing) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      '正在解析中...',
                      style: TextStyle(color: c.outline),
                    ),
                  ],
                ),
              ),
            ] else if (_parseResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: c.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '解析结果 (置信度: ${(_parseResult!.confidence * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildResultRow('任务名称', _parseResult!.name, Icons.title, c),
                    _buildResultRow('计时模式', 
                      _parseResult!.mode == TimerMode.countdown ? '倒计时' : '计时器', 
                      _parseResult!.mode == TimerMode.countdown ? Icons.timer : Icons.schedule, c),
                    if (_parseResult!.targetSeconds > 0)
                      _buildResultRow('目标时间', 
                        _formatTime(_parseResult!.targetSeconds), Icons.access_time, c),
                    _buildResultRow('优先级', 
                      _getPriorityLabel(_parseResult!.priority), Icons.flag, c),
                    if (_parseResult!.tags.isNotEmpty)
                      _buildResultRow('标签', 
                        _parseResult!.tags.map((t) => _getTagLabel(t)).join(', '), 
                        Icons.label, c),
                    if (_parseResult!.dueDate != null)
                      _buildResultRow('截止日期', 
                        _formatDueDate(_parseResult!.dueDate!), 
                        Icons.event, c),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _parseResult == null || _controller.text.trim().isEmpty
                      ? null
                      : () => _createTask(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('创建任务'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, ColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.outline,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: c.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createTask() {
    if (_parseResult == null) return;

    final appState = context.read<AppState>();
    appState.addTask(
      name: _parseResult!.name,
      mode: _parseResult!.mode,
      targetSeconds: _parseResult!.targetSeconds,
      priority: _parseResult!.priority,
      tags: _parseResult!.tags,
      dueDate: _parseResult!.dueDate,
    );

    Navigator.pop(context);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('任务 "${_parseResult!.name}" 创建成功!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  String _getPriorityLabel(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return '紧急';
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }

  String _getTagLabel(Tag tag) {
    final task = Task(id: '', name: '', mode: TimerMode.countdown, tags: [tag]);
    return task.getTagLabel(tag);
  }

  String _formatDueDate(DateTime date) {
    final hasTime = date.hour != 0 || date.minute != 0;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    if (hasTime) {
      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '$dateStr $timeStr';
    }
    
    return dateStr;
  }
}