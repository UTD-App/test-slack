part of 'package:authentication/src/presentation/add_information/view/add_information_page.dart';

class _FormAddInfoBody extends StatelessWidget {
  const _FormAddInfoBody({required this.state});

  final AddInformationState state;

  /// Derives the user's age from the stored birthday (`yyyy-MM-dd`), or null
  /// when no birthday has been chosen yet.
  int? _ageFromBirthday(String text) {
    final birth = DateTime.tryParse(text);
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// Opens the mockup age wheel; the picked age is converted back to a birthday
  /// so the backend contract (birthday `yyyy-MM-dd`) is unchanged.
  Future<void> _pickAge(BuildContext context) async {
    final current = _ageFromBirthday(state.birthday) ?? 18;
    final age = await showAgePickerSheet(
      context,
      title: context.tr(AuthStrings.yourAge),
      doneLabel: context.tr(AuthStrings.done),
      initial: current,
      min: 18,
      max: 80,
    );
    if (age == null || !context.mounted) return;
    final now = DateTime.now();
    final birthday = DateTime(now.year - age, now.month, now.day);
    context.read<AddInformationBloc>().add(
      SelectedBirthdayEvent(dateTime: birthday),
    );
  }

  Widget _label(BuildContext context, String key) => TextWidget(
    context.tr(key),
    style: context.bodySmall.w500
        .colorExt(ColorManager.lumiaTextSecondary)
        .size(14),
  );

  Widget _darkField(
    BuildContext context, {
    required String hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: 14.radius,
      borderSide: const BorderSide(color: ColorManager.frostedBorder),
    );
    final focused = OutlineInputBorder(
      borderRadius: 14.radius,
      borderSide: const BorderSide(color: ColorManager.lumiaAccentLight),
    );
    return TextInputWidget(
      hint,
      controller: controller,
      validator: validator,
      textColor: ColorManager.white,
      cursorColor: ColorManager.white,
      fillColor: ColorManager.frostedFill,
      hintStyle: context.bodyLarge
          .colorExt(ColorManager.lumiaTextSecondary)
          .size(14),
      contentPadding: context.paddingSymmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: focused,
      errorBorder: border,
      focusedErrorBorder: focused,
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = _ageFromBirthday(state.birthday);
    return Form(
      key: state.formKey,
      child: Padding(
        padding: context.paddingSymmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar upload
            GradientCard(
              frosted: true,
              padding: context.paddingSymmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    context.tr(AuthStrings.uploadPicture),
                    style: context.bodySmall.w500
                        .colorExt(ColorManager.lumiaTextSecondary)
                        .size(14),
                  ),
                  _PickImageBody(state: state),
                ],
              ),
            ),
            18.hBox,
            // Full name
            _label(context, AuthStrings.fullName),
            8.hBox,
            _darkField(
              context,
              hint: context.tr(AuthStrings.fullName),
              controller: state.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr(AuthStrings.requiredField);
                }
                return null;
              },
            ),
            22.hBox,
            // Gender
            _label(context, AuthStrings.yourGender),
            10.hBox,
            GenderSelector(
              maleLabel: context.tr(AuthStrings.male),
              femaleLabel: context.tr(AuthStrings.female),
              selected: state.gender,
              onSelect: (label) => context.read<AddInformationBloc>().add(
                SelectedGenderEvent(gender: label),
              ),
              maleIcon: AssetManager.man,
              maleAvatar: AssetManager.manInfo,
              femaleIcon: AssetManager.femaleIconInfo,
              femaleAvatar: AssetManager.women,
            ),
            22.hBox,
            // Age (wheel picker)
            _label(context, AuthStrings.yourAge),
            10.hBox,
            GradientCard(
              frosted: true,
              onTap: () => _pickAge(context),
              padding: context.paddingSymmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    age != null
                        ? '$age'
                        : context.tr(AuthStrings.selectAge),
                    style: context.bodyMedium.size(15).colorExt(
                      age != null
                          ? ColorManager.white
                          : ColorManager.lumiaTextSecondary,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: ColorManager.lumiaTextSecondary,
                  ),
                ],
              ),
            ),
            40.hBox,
            ButtonWidget(
              title: context.tr(AuthStrings.submit),
              height: 55.h,
              radius: 30,
              backgroundColors: ColorManager.pinkCtaGradient,
              isLoading: state.requestState.isLoading,
              onPressed: () {
                // Tell the user EXACTLY what's still missing, all at once.
                // The profile photo is OPTIONAL (the backend doesn't require it),
                // so it's not part of the completion gate — only name/gender/age.
                final missing = <String>[];
                if (state.name.text.trim().isEmpty) {
                  missing.add(context.tr(AuthStrings.fullName));
                }
                if (state.gender.isEmpty) {
                  missing.add(context.tr(AuthStrings.gender));
                }
                if (state.birthday.isEmpty) {
                  missing.add(context.tr(AuthStrings.yourAge));
                }
                if (missing.isNotEmpty) {
                  ToastManager.showToast(
                    context,
                    message:
                        '${context.tr(AuthStrings.completeMissing)} '
                        '${missing.join(context.tr(AuthStrings.listSeparator))}',
                    isError: true,
                  );
                  return;
                }
                context.read<AddInformationBloc>().add(
                  AddInformationEvent(context: context),
                );
              },
            ),
            20.hBox,
          ],
        ),
      ),
    );
  }
}
