part of 'package:authentication/src/presentation/add_information/view/add_information_page.dart';

class _FormAddInfoBody extends StatelessWidget {
  const _FormAddInfoBody({required this.state});

  final AddInformationState state;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state.formKey,
      child: Padding(
        padding: context.paddingSymmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            5.hBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  context.tr(AuthStrings.uploadPicture),
                  textAlign: TextAlign.center,
                  style: context.bodySmall.w500
                      .colorExt(ColorManager.lightGray2)
                      .size(14),
                ),
                _PickImageBody(state: state),
              ],
            ),
            10.hBox,
            TextInputWidget(
              context.tr(AuthStrings.fullName),
              label: TextWidget(
                context.tr(AuthStrings.fullName),
                style: context.bodyLarge.colorExt(
                  ColorManager.blackColor.withValues(alpha: 0.45),
                ),
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: ColorManager.transparent),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              errorBorder: InputBorder.none,
              controller: state.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr(AuthStrings.requiredField);
                }
                return null;
              },
            ),
            20.hBox,
            // Birthday picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null && context.mounted) {
                  context.read<AddInformationBloc>().add(
                    SelectedBirthdayEvent(dateTime: picked),
                  );
                }
              },
              child: AbsorbPointer(
                child: TextInputWidget(
                  context.tr(AuthStrings.selectBirthday),
                  controller: state.birthday,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorManager.transparent),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            30.hBox,
            TextWidget(
              context.tr(AuthStrings.gender),
              style: context.bodySmall.w500
                  .colorExt(ColorManager.lightGray2)
                  .size(14),
            ),
            10.hBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Male button
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<AddInformationBloc>().add(
                      SelectedGenderEvent(gender: context.tr(AuthStrings.male)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: 10.radius,
                        gradient:
                            state.gender.text == context.tr(AuthStrings.male)
                            ? const LinearGradient(
                                colors: ColorManager.maleContainer,
                              )
                            : null,
                        color: state.gender.text != context.tr(AuthStrings.male)
                            ? ColorManager.inactiveColor
                            : null,
                      ),
                      padding: context.paddingSymmetric(
                        vertical: 12,
                        horizontal: 13,
                      ),
                      child: Row(
                        children: [
                          ImageWidget(
                            height: 20.h,
                            width: 20.w,
                            image: AssetManager.man,
                          ),
                          5.wBox,
                          TextWidget(
                            context.tr(AuthStrings.male),
                            style: context.bodyMedium
                                .size(15)
                                .copyWith(color: ColorManager.white),
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 17.r,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              height: 30.h,
                              width: 30.w,
                              AssetManager.manInfo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                10.wBox,
                // Female button
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<AddInformationBloc>().add(
                      SelectedGenderEvent(
                        gender: context.tr(AuthStrings.female),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: 10.radius,
                        gradient:
                            state.gender.text == context.tr(AuthStrings.female)
                            ? const LinearGradient(
                                colors: ColorManager.femaleContainer,
                              )
                            : null,
                        color:
                            state.gender.text != context.tr(AuthStrings.female)
                            ? ColorManager.inactiveColor
                            : null,
                      ),
                      padding: context.paddingSymmetric(
                        vertical: 12,
                        horizontal: 13,
                      ),
                      child: Row(
                        children: [
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                            child: ImageWidget(
                              height: 20.h,
                              width: 20.w,
                              image: AssetManager.femaleIconInfo,
                            ),
                          ),
                          5.wBox,
                          TextWidget(
                            context.tr(AuthStrings.female),
                            style: context.bodyMedium
                                .size(15)
                                .copyWith(color: ColorManager.white),
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 17.r,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              height: 30.h,
                              width: 30.w,
                              AssetManager.women,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            70.hBox,
            Align(
              alignment: Alignment.center,
              child: ButtonWidget(
                title: context.tr(AuthStrings.submit),
                height: 55.h,
                width: 200.w,
                elevation: 0,
                backgroundColor: ColorManager.primary,
                isLoading: state.requestState.isLoading,
                onPressed: () {
                  if (state.image == null) {
                    ToastManager.showToast(
                      context,
                      message: context.tr(AuthStrings.pickImage),
                      isError: true,
                    );
                  } else if (state.name.text.isEmpty) {
                    ToastManager.showToast(
                      context,
                      message: context.tr(AuthStrings.username),
                      isError: true,
                    );
                  } else if (state.gender.text.isEmpty) {
                    ToastManager.showToast(
                      context,
                      message: context.tr(AuthStrings.selectGender),
                      isError: true,
                    );
                  } else if (state.birthday.text.isEmpty) {
                    ToastManager.showToast(
                      context,
                      message: context.tr(AuthStrings.selectBirthday),
                      isError: true,
                    );
                  } else {
                    context.read<AddInformationBloc>().add(
                      AddInformationEvent(context: context),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
