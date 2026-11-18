import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_theme.dart';

/// The line icons of the approved screens. Each one is a file in assets/icons that draws with
/// `currentColor`, so [LineIcon] only picks the color.
enum LineIcons {
  back('back'),
  backHeavy('back_heavy'),
  map('map'),
  calendar('calendar'),
  settings('settings'),
  chevronLeft('chevron_left'),
  chevronRight('chevron_right'),
  chevronRightHeavy('chevron_right_heavy'),
  check('check');

  const LineIcons(this.file);

  final String file;

  String get asset => 'assets/icons/$file.svg';
}

/// One line icon at [size], in [color] or the ink color of the theme.
class LineIcon extends StatelessWidget {
  const LineIcon(this.icon, {super.key, this.size = 22, this.color});

  final LineIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? context.palette.ink,
        BlendMode.srcIn,
      ),
    );
  }
}
