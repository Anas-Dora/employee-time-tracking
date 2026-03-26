import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../AppColors.dart';
import 'day_overview.dart';

class DayEditDialog extends StatelessWidget {
  final DayType selectedType;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final TextEditingController breakController;

  final String Function(DayType) dayTypeLabel;
  final String Function(TimeOfDay?) formatTime;

  final ValueChanged<DayType?> onTypeChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  final VoidCallback onCancel;
  final VoidCallback onSave;

  const DayEditDialog({
    super.key,
    required this.selectedType,
    required this.start,
    required this.end,
    required this.breakController,
    required this.dayTypeLabel,
    required this.formatTime,
    required this.onTypeChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Tag bearbeiten',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<DayType>(
              initialValue: selectedType,
              decoration: InputDecoration(
                labelText: 'Tagestyp',
                labelStyle: TextStyle(color: AppColors.primary),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              items: DayType.values
                  .map(
                    (type) => DropdownMenuItem<DayType>(
                      value: type,
                      child: Text(
                        dayTypeLabel(type),
                        style: TextStyle(
                          color: selectedType == type
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onTypeChanged,
              dropdownColor: Colors.blue.shade200,
              focusColor: Colors.red,
            ),

            const SizedBox(height: 16),

            // Workday UI
            if (selectedType == DayType.workday) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPickStart,
                      child: Text(
                        'Start: ${formatTime(start)}',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPickEnd,
                      child: Text(
                        'Ende: ${formatTime(end)}',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: breakController,
                cursorColor: Color(0xFF002863),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pause (Minuten)',
                  labelStyle: TextStyle(color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ] else
              Text(
                'Bei diesem Tagestyp werden keine Zeiten gespeichert.',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) {
                return const Color(0xFF002863).withOpacity(0.2);
              }
              return null;
            }),
          ),
          child: const Text(
            'Abbrechen',
            style: TextStyle(color: Color(0xFF002863)),
          ),
        ),

        ElevatedButton(
          onPressed: onSave,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: const Color(0xFF002863),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(MaterialState.pressed)) {
                    return const Color(0xFF002863).withOpacity(0.2);
                  }
                  return null;
                }),
              ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
