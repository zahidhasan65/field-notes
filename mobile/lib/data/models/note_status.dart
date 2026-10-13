import 'package:flutter/material.dart';
import '../../core/core.dart';

/// Values match the backend enum (PENDING / IN_PROGRESS / COMPLETED).
enum NoteStatus { pending, inProgress, completed }

extension NoteStatusX on NoteStatus {
  String get apiValue => switch (this) {
        NoteStatus.pending => 'PENDING',
        NoteStatus.inProgress => 'IN_PROGRESS',
        NoteStatus.completed => 'COMPLETED',
      };

  String get label => switch (this) {
        NoteStatus.pending => 'Pending',
        NoteStatus.inProgress => 'In Progress',
        NoteStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        NoteStatus.pending => AppColors.orange,
        NoteStatus.inProgress => AppColors.primary,
        NoteStatus.completed => AppColors.green,
      };

  static NoteStatus fromApi(String? value) => switch (value) {
        'IN_PROGRESS' => NoteStatus.inProgress,
        'COMPLETED' => NoteStatus.completed,
        _ => NoteStatus.pending,
      };
}
