import 'package:flutter/material.dart';

class Eyelid extends StatelessWidget {
  const Eyelid({super.key, required this.isUpper, required this.closedAmount});

  final bool isUpper;
  final double closedAmount;

  @override
  Widget build(BuildContext context) {
    if (closedAmount <= 0) return const SizedBox.shrink();

    return Positioned(
      top: isUpper ? null : 0,
      bottom: isUpper ? 0 : null,
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxWidth * closedAmount;
          return Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: isUpper
                  ? BorderRadius.only(
                      topLeft: Radius.circular(height * 0.3),
                      topRight: Radius.circular(height * 0.3),
                    )
                  : BorderRadius.only(
                      bottomLeft: Radius.circular(height * 0.3),
                      bottomRight: Radius.circular(height * 0.3),
                    ),
            ),
          );
        },
      ),
    );
  }
}
