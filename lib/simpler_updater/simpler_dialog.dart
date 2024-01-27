// import 'dart:io';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:simpler_updater/helpers/extensions/context_extensions.dart';

// /// do not forget .show()
// final class ShowDialogWidget extends StatelessWidget {
//   const ShowDialogWidget({
//     super.key,
//     required this.context,
//     required this.wrapper,
//     this.barrierColor,
//     this.paddings,
//     this.isDismissible = true,
//     this.isDialog = false,
//     this.animate = false,
//   });

//   final BuildContext context;
//   final Widget wrapper;
//   final bool isDismissible;
//   final Color? barrierColor;
//   final EdgeInsetsGeometry? paddings;
//   final bool isDialog;
//   final bool animate;

//   Future<void> show() async {
//     if (isDialog && !animate) {
//       showDialog(
//         barrierColor: barrierColor,
//         barrierDismissible: isDismissible,
//         context: context,
//         builder: (v) => Padding(
//           padding: paddings ?? v.mQuery.viewInsets,
//           child: Center(
//             child: this,
//           ),
//         ),
//       );
//     } else if (isDialog && animate) {
//       showGeneralDialog(
//         context: context,
//         barrierColor: barrierColor ?? const Color(0x80000000),
//         barrierDismissible: isDismissible,
//         barrierLabel: '',
//         pageBuilder: (context, animation, secondaryAnimation) {
//           return const Text('Page Builder');
//         },
//         transitionBuilder: (context, animation, secondaryAnimation, child) {
//           return ScaleTransition(
//             scale: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
//             child: FadeTransition(
//               opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
//               child: Center(
//                 child: Material(
//                   color: Colors.transparent,
//                   child: this,
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: wrapper,
//     );
//   }
// }

// /// ALert Wrapper
// final class MegaAlertWrapper extends StatelessWidget {
//   const MegaAlertWrapper({
//     super.key,
//     required this.buttons,
//     this.allowDismissal = true,
//     this.dialogTextWidget,
//     this.dialogTitleWidget,
//   });

//   final List<Widget> buttons;
//   final Widget? dialogTextWidget;
//   final Widget? dialogTitleWidget;
//   final bool allowDismissal;

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: allowDismissal,
//       child: Platform.isAndroid
//           ? AlertDialog(
//               title: dialogTitleWidget,
//               content: dialogTextWidget,
//               actions: buttons,
//             )
//           : CupertinoAlertDialog(
//               title: dialogTitleWidget,
//               content: dialogTextWidget,
//               actions: buttons,
//             ),
//     );
//   }
// }
