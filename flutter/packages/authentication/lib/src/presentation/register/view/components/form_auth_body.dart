part of 'package:authentication/src/presentation/register/view/register_page.dart';

class _FormAuthBody extends StatefulWidget {
  final String? initialEmail;

  const _FormAuthBody({this.initialEmail});

  @override
  State<_FormAuthBody> createState() => _FormAuthBodyState();
}

class _FormAuthBodyState extends State<_FormAuthBody> {
  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      context.read<RegisterBloc>().state.emailController.text =
          widget.initialEmail!;
    }
  }

  InputBorder _outlineBorder() {
    return OutlineInputBorder(
      borderRadius: 30.radius,
      borderSide: const BorderSide(
        width: 1.5,
        color: ColorManager.frostedBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (prev, curr) =>
          prev.isFormValid != curr.isFormValid ||
          prev.suffixIcon != curr.suffixIcon ||
          prev.isPassword != curr.isPassword ||
          prev.reqState != curr.reqState,
      builder: (context, state) {
        return Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              30.hBox,

              // ── Email ──
              TextInputWidget(
                context.tr(AuthStrings.email),
                fillColor: ColorManager.frostedFill,
                textColor: ColorManager.white,
                cursorColor: ColorManager.white,
                hintStyle: context.bodyLarge
                    .size(14)
                    .colorExt(ColorManager.white.withValues(alpha: 0.5)),
                border: _outlineBorder(),
                enabledBorder: _outlineBorder(),
                focusedBorder: _outlineBorder(),
                focusedErrorBorder: _outlineBorder(),
                errorBorder: _outlineBorder(),
                keyboardType: TextInputType.emailAddress,
                controller: state.emailController,
                onChanged: (_) {
                  context
                      .read<RegisterBloc>()
                      .add(const ValidEventRegister());
                },
                contentPadding: context.paddingSymmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(AuthStrings.requiredField);
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return context.tr(AuthStrings.emailValidator);
                  }
                  return null;
                },
              ),
              15.hBox,

              // ── Password ──
              TextInputWidget(
                context.tr(AuthStrings.password),
                fillColor: ColorManager.frostedFill,
                textColor: ColorManager.white,
                cursorColor: ColorManager.white,
                hintStyle: context.bodyLarge
                    .size(14)
                    .colorExt(ColorManager.white.withValues(alpha: 0.5)),
                border: _outlineBorder(),
                enabledBorder: _outlineBorder(),
                focusedBorder: _outlineBorder(),
                focusedErrorBorder: _outlineBorder(),
                errorBorder: _outlineBorder(),
                suffixColor: ColorManager.white.withValues(alpha: 0.7),
                suffixIcon: state.suffixIcon,
                isPassword: state.isPassword,
                controller: state.passwordController,
                onChanged: (_) {
                  context
                      .read<RegisterBloc>()
                      .add(const ValidEventRegister());
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(AuthStrings.requiredField);
                  }
                  if (value.length < 6) {
                    return context.tr(AuthStrings.passwordTooShort);
                  }
                  return null;
                },
                onPressed: () {
                  context.read<RegisterBloc>().add(
                        const TogglePasswordVisibilityEvent(),
                      );
                },
              ),
              20.hBox,

              // ── Submit Button ──
              ButtonWidget(
                title: context.tr(AuthStrings.next),
                height: 52.h,
                radius: 30.r,
                backgroundColors: state.isFormValid
                    ? ColorManager.pinkCtaGradient
                    : [Colors.grey.shade600, Colors.grey.shade700],
                isLoading: state.reqState.isLoading,
                onPressed: () {
                  if (state.reqState.isLoading) return;

                  if (state.formKey.currentState?.validate() == false) {
                    return;
                  }

                  context.read<RegisterBloc>().add(
                        RegisterEvent(context: context),
                      );
                },
              ),
              35.hBox,
            ],
          ),
        );
      },
    );
  }
}
