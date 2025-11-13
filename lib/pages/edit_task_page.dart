import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../utils/recurring_task_manager.dart';

class EditTaskPage extends StatefulWidget {
  final Task? task;
  const EditTaskPage({super.key, this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _targetSecondsController;
  TimerMode _mode = TimerMode.countdown;
  Priority _priority = Priority.medium;
  List<Tag> _tags = [];
  DateTime? _dueDate;
  bool _isRecurring = false;
  String? _recurringPattern;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _noteController = TextEditingController(text: widget.task?.note ?? '');
    _targetSecondsController = TextEditingController(
      text: widget.task?.targetSeconds.toString() ?? '1500',
    );
    _mode = widget.task?.mode ?? TimerMode.countdown;
    _priority = widget.task?.priority ?? Priority.medium;
    _tags = widget.task?.tags ?? [];
    _dueDate = widget.task?.dueDate;
    _isRecurring = widget.task?.isRecurring ?? false;
    _recurringPattern = widget.task?.recurringPattern;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _targetSecondsController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final name = _nameController.text.trim();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final target = _mode == TimerMode.countdown
        ? int.parse(_targetSecondsController.text.trim())
        : 0;
    if (widget.task != null) {
      final updated = widget.task!.copyWith(
        name: name,
        note: note,
        mode: _mode,
        targetSeconds: target,
        priority: _priority,
        tags: _tags,
        dueDate: _dueDate,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
      );
      await state.updateTask(updated);
    } else {
      await state.addTask(
        name: name,
        note: note,
        mode: _mode,
        targetSeconds: target,
        priority: _priority,
        tags: _tags,
        dueDate: _dueDate,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
      );
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑任务' : '新建任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTask,
            tooltip: '保存',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TimerMode>(
              segments: const [
                ButtonSegment(value: TimerMode.countdown, label: Text('倒计时')),
                ButtonSegment(value: TimerMode.stopwatch, label: Text('计时')),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 16),
            const Text(
              '优先级',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(value: Priority.low, label: Text('低')),
                ButtonSegment(value: Priority.medium, label: Text('中')),
                ButtonSegment(value: Priority.high, label: Text('高')),
                ButtonSegment(value: Priority.urgent, label: Text('紧急')),
              ],
              selected: {_priority},
              onSelectionChanged: (selection) =>
                  setState(() => _priority = selection.first),
            ),
            const SizedBox(height: 16),
            const Text(
              '标签',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Tag.values.map((tag) {
                final isSelected = _tags.contains(tag);
                return FilterChip(
                  label: Text(
                    Task(
                      id: '',
                      name: '',
                      mode: TimerMode.countdown,
                      tags: [tag],
                    ).getTagLabel(tag),
                  ),
                  avatar: Icon(
                    Task(
                      id: '',
                      name: '',
                      mode: TimerMode.countdown,
                      tags: [tag],
                    ).getTagIcon(tag),
                    size: 16,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('截止日期'),
              subtitle: Text(
                _dueDate == null
                    ? '未设置'
                    : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dueDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('循环任务'),
              subtitle: const Text('任务完成后自动生成下一个周期的任务'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  if (!value) {
                    _recurringPattern = null;
                  }
                });
              },
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '循环模式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RecurringTaskManager.getAvailablePatterns().map((
                    pattern,
                  ) {
                    final isSelected = _recurringPattern == pattern;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(RecurringTaskManager.getPatternIcon(pattern)),
                          const SizedBox(width: 4),
                          Text(
                            RecurringTaskManager.getPatternDescription(pattern),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _recurringPattern = selected ? pattern : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_mode == TimerMode.countdown)
              TextFormField(
                controller: _targetSecondsController,
                decoration: const InputDecoration(
                  labelText: '目标时间',
                  suffixText: '秒',
                  helperText: '建议: 25分钟=1500秒, 45分钟=2700秒',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '0') ?? 0;
                  return n > 0 ? null : '请输入有效秒数';
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
