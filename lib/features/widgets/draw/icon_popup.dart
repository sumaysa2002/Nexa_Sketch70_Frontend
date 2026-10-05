import 'package:flutter/material.dart';
import 'arrowpainter.dart';

class Icon_Popup extends StatelessWidget {

  final Offset iconPosition;
  final Size iconSize;
  final List<String> iconPaths;
  final List<String>? iconLabels;

  const Icon_Popup({
    super.key,
    required this.iconPosition,
    required this.iconSize,
    required this.iconPaths,
    this.iconLabels,
  });

  @override
  Widget build(BuildContext context) {

    final double popupWidth = 280;
    final double popupHeight = 240;
    final double arrowWidth = 20;
    final double arrowHeight = 10;

    final double popupLeft =
        iconPosition.dx + iconSize.width / 2 - popupWidth / 2;

    final double popupTop =
        iconPosition.dy - popupHeight - arrowHeight - 8;

    final double arrowLeft =
        iconPosition.dx + iconSize.width / 2 - 15;

    final double arrowTop =
        popupTop + popupHeight;

    return Stack(
      children: [
        Positioned(
            top: popupTop,
            left: popupLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popupWidth,
                height: popupHeight,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 20,
                          color: Colors.black26
                      )
                    ]
                ),

                child: GridView.builder(
                    itemCount: iconPaths.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final icon = iconPaths[index];
                      final String? label = (iconLabels != null &&
                          index < iconLabels!.length &&
                          iconLabels![index].trim().isNotEmpty)
                          ? iconLabels![index]
                          : null;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: (){
                          Navigator.pop(context, icon);
                        },

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    icon,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            if (label != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'NotoSansThai',
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],

                          ],
                        ),
                      );
                    }
                ),
              ),
            )
        ),

        Positioned(
            top: arrowTop,
            left: arrowLeft,
            child: CustomPaint(
              size: Size(20, 10),
              painter: ArrowPainter(),
            )
        )
      ],
    );
  }
}