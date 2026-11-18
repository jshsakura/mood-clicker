import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// 캐릭터 상태. 디자이너가 만든 Rive, Lottie 애니메이션의 상태 이름과 맞춘다.
enum CharacterPose { idle, react, palmsTogether, finish }

/// 캐릭터가 들어갈 자리. 지금은 상태 이름만 보여 주는 네모다.
/// 애니메이션이 오면 이 위젯 안만 바꾼다. 부르는 쪽은 그대로 둔다.
class CharacterSlot extends StatelessWidget {
  const CharacterSlot({super.key, required this.pose, this.size = 160});

  final CharacterPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: p.line, width: 2),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Text(
        pose.name,
        style: TypeScale.label.copyWith(color: p.inkMuted),
      ),
    );
  }
}
