import 'package:flutter/material.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

import '../../../screens/edit_profile_form.dart';

/// Custom Stac widget `core.editProfileForm`: renders the signed-in user's RICH
/// native edit-profile form (tap-to-change avatar + upload, name, bio, multi
/// cover management, save) — the parts Stac primitives can't express.
///
/// It is declared in the core manifest's `edit_profile` screen so UTD Studio
/// composes the screen server-side while this one node renders natively for a
/// pixel-match with the standalone form. Same pattern as [SelfProfileCardParser].
///
/// [EditProfileForm] is self-contained (seeds from the session + fetches its own
/// covers), so it needs no props/bindings from the node.
class EditProfileFormParser extends StacParser<Map<String, dynamic>> {
  const EditProfileFormParser();

  @override
  String get type => 'core.editProfileForm';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  Widget parse(BuildContext context, Map<String, dynamic> model) {
    return const EditProfileForm();
  }
}
