import 'package:flutter/material.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class StudentMotivationalCard extends StatelessWidget {
  const StudentMotivationalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: StudentColors.motivationalGradient,
        ),
        border: Border.all(color: StudentColors.forestTint),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: StudentColors.forest.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: StudentColors.amberPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“Small progress every single day creates extraordinary results.”',
                  style: TextStyle(
                    color: StudentColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Keep learning with curiosity and dedication.',
                  style: TextStyle(
                    color: StudentColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
