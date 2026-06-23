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

  InputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: 16.radius,
        borderSide:
            BorderSide(color: c ?? ColorManager.frostedBorder, width: 1.2),
      );

  /// Frosted pill field with an inline leading icon — matches the login screen
  /// so the two auth forms read as a pair.
  Widget _field(
    BuildContext context, {
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    dynamic suffixIcon,
    VoidCallback? onSuffix,
    String? Function(String?)? validator,
  }) {
    return TextInputWidget(
      hint,
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      isPassword: isPassword,
      textColor: ColorManager.white,
      cursorColor: ColorManager.white,
      fillColor: ColorManager.frostedFill,
      prefixIcon: Icon(icon, color: ColorManager.lumiaAccentLight, size: 20.sp),
      suffixIcon: suffixIcon,
      suffixColor: ColorManager.white.withValues(alpha: 0.7),
      onPressed: onSuffix,
      hintStyle: context.bodyLarge
          .size(14)
          .colorExt(ColorManager.white.withValues(alpha: 0.5)),
      contentPadding: context.paddingSymmetric(horizontal: 8, vertical: 16),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(ColorManager.lumiaAccentLight),
      errorBorder: _border(ColorManager.error),
      focusedErrorBorder: _border(ColorManager.error),
      onChanged: (_) =>
          context.read<RegisterBloc>().add(const ValidEventRegister()),
      validator: validator,
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
          // Plain scroll (no IntrinsicHeight/Spacer) so the screen NEVER overflows
          // on short devices and the hero always stays at the top.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                24.hBox,
                // ── Hero: logo badge + heading + subtitle ──
                Center(
                  child: AppLogoBadge(
                    size: 84,
                    fallback: Image.asset(
                      AssetManager.logo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                22.hBox,
                TextWidget(
                  context.tr(AuthStrings.createAccount),
                  textAlign: TextAlign.center,
                  style: context.bodyLarge
                      .size(28)
                      .w700
                      .colorExt(ColorManager.white),
                ),
                8.hBox,
                TextWidget(
                  context.tr(AuthStrings.registerSubtitle),
                  textAlign: TextAlign.center,
                  style: context.bodyLarge.size(15).colorExt(
                        ColorManager.white.withValues(alpha: 0.7),
                      ),
                ),
                32.hBox,

                // ── Email ──
                _field(
                  context,
                  hint: context.tr(AuthStrings.email),
                  icon: Icons.alternate_email_rounded,
                  controller: state.emailController,
                  keyboardType: TextInputType.emailAddress,
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
                16.hBox,

                // ── Password ──
                _field(
                  context,
                  hint: context.tr(AuthStrings.password),
                  icon: Icons.lock_outline_rounded,
                  controller: state.passwordController,
                  isPassword: state.isPassword,
                  suffixIcon: state.suffixIcon,
                  onSuffix: () => context
                      .read<RegisterBloc>()
                      .add(const TogglePasswordVisibilityEvent()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr(AuthStrings.requiredField);
                    }
                    if (value.length < 6) {
                      return context.tr(AuthStrings.passwordTooShort);
                    }
                    return null;
                  },
                ),
                28.hBox,

                // ── Submit (muted pink until the form is valid) ──
                ButtonWidget(
                  title: context.tr(AuthStrings.next),
                  height: 54.h,
                  width: ScreenUtil().screenWidth,
                  radius: 30.r,
                  backgroundColors: state.isFormValid
                      ? ColorManager.pinkCtaGradient
                      : ColorManager.pinkCtaGradientMuted,
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
                22.hBox,
                // ── Already have an account → sign in ──
                Center(
                  child: InkWell(
                    onTap: () => context.push(AuthRoutes.login),
                    child: Text.rich(
                      TextSpan(
                        text: '${context.tr(AuthStrings.alreadyHaveAccount)} ',
                        style: context.bodyLarge.size(14).colorExt(
                              ColorManager.white.withValues(alpha: 0.7),
                            ),
                        children: [
                          TextSpan(
                            text: context.tr(AuthStrings.login),
                            style: context.bodyLarge
                                .size(14)
                                .w700
                                .colorExt(ColorManager.lumiaAccentLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                24.hBox,
              ],
            ),
          ),
        );
      },
    );
  }
}
