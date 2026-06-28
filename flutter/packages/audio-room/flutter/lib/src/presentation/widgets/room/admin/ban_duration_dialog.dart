import 'package:flutter/material.dart';

import 'ban_duration_dialog_body.dart';

Future<int?> showBanDurationDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => const BanDurationDialogBody(),
  );
}
