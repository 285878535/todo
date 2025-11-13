class Record {
  final String taskId;
  final String taskName;
  final int seconds;
  final DateTime at;
  Record({required this.taskId, required this.taskName, required this.seconds, required this.at});

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'taskName': taskName,
        'seconds': seconds,
        'at': at.millisecondsSinceEpoch,
      };
  factory Record.fromMap(Map<String, dynamic> map) => Record(
        taskId: map['taskId'] as String,
        taskName: map['taskName'] as String,
        seconds: map['seconds'] as int,
        at: DateTime.fromMillisecondsSinceEpoch(map['at'] as int),
      );
}
