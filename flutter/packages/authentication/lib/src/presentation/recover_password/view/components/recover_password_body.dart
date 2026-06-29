part of 'package:authentication/src/presentation/recover_password/view/recover_password_page.dart';

class _RecoverPasswordBody extends StatelessWidget {
  const _RecoverPasswordBody();

  InputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: 16.radius,
        borderSide:
            BorderSide(color: c ?? ColorManager.frostedBorder, width: 1.2),
      );

  /// Frosted pill field with an inline leading icon (matches the login screen).
  Widget _field(
    BuildContext context, {
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    dynamic suffixIcon,
    VoidCallback? onSuffix,
    String? Function(String?)? validator,
  }) {
    return TextInputWidget(
      hint,
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      isPassword: isPassword,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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
      onChanged: (_) => context
          .read<RecoverPasswordBloc>()
          .add(const RecoverUpdateValidationEvent()),
      validator: validator,
    );
  }

  Widget _title(BuildContext context, String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextWidget(
            title,
            textAlign: TextAlign.center,
            style:
                context.bodyLarge.size(26).w700.colorExt(ColorManager.white),
          ),
          8.hBox,
          TextWidget(
            subtitle,
            textAlign: TextAlign.center,
            style: context.bodyLarge
                .size(14)
                .colorExt(ColorManager.white.withValues(alpha: 0.7)),
          ),
        ],
      );

  Widget _cta(
    BuildContext context, {
    required String title,
    required bool valid,
    required bool isLoading,
    required VoidCallback onTap,
  }) =>
      ButtonWidget(
        title: title,
        height: 54.h,
        width: ScreenUtil().screenWidth,
        radius: 30.r,
        backgroundColors: valid
            ? ColorManager.pinkCtaGradient
            : [Colors.grey.shade600, Colors.grey.shade700],
        isLoading: isLoading,
        onPressed: valid ? onTap : () {},
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecoverPasswordBloc, RecoverPasswordState>(
      builder: (context, state) {
        final valid = state.isStepValid ?? false;
        final loading = state.requestState.isLoading;
        final bloc = context.read<RecoverPasswordBloc>();

        return Form(
          key: state.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                60.hBox,
                Center(
                  child: Container(
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorManager.frostedFill,
                      border: Border.all(color: ColorManager.frostedBorder),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: ColorManager.lumiaAccentLight,
                      size: 44.sp,
                    ),
                  ),
                ),
                28.hBox,
                if (state.step == RecoverStep.enterEmail)
                  ..._emailStep(context, state, valid, loading, bloc)
                else if (state.step == RecoverStep.enterCode)
                  ..._codeStep(context, state, valid, loading, bloc)
                else
                  ..._passwordStep(context, state, valid, loading, bloc),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Step 1: email ─────────────────────────────────────────
  List<Widget> _emailStep(
    BuildContext context,
    RecoverPasswordState state,
    bool valid,
    bool loading,
    RecoverPasswordBloc bloc,
  ) =>
      [
        _title(
          context,
          context.tr(AuthStrings.recoverPassword),
          context.tr(AuthStrings.recoverEmailSubtitle),
        ),
        28.hBox,
        _field(
          context,
          hint: context.tr(AuthStrings.pleaseEnterYourEmail),
          icon: Icons.alternate_email_rounded,
          controller: state.emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return context.tr(AuthStrings.requiredField);
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
              return context.tr(AuthStrings.emailValidator);
            }
            return null;
          },
        ),
        28.hBox,
        _cta(
          context,
          title: context.tr(AuthStrings.sendCode),
          valid: valid,
          isLoading: loading,
          onTap: () => bloc.add(RecoverSendOtpEvent(context: context)),
        ),
      ];

  // ── Step 2: code ──────────────────────────────────────────
  List<Widget> _codeStep(
    BuildContext context,
    RecoverPasswordState state,
    bool valid,
    bool loading,
    RecoverPasswordBloc bloc,
  ) =>
      [
        _title(
          context,
          context.tr(AuthStrings.enterCodeTitle),
          '${context.tr(AuthStrings.codeSentTo)} ${state.emailController.text.trim()}',
        ),
        28.hBox,
        _field(
          context,
          hint: context.tr(AuthStrings.verificationCode),
          icon: Icons.sms_outlined,
          controller: state.codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => (v == null || v.trim().length < 4)
              ? context.tr(AuthStrings.codeValidator)
              : null,
        ),
        4.hBox,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: state.resendSeconds > 0
              ? TextWidget(
                  '${context.tr(AuthStrings.resendIn)} ${state.resendSeconds}${context.tr(AuthStrings.secondsShort)}',
                  style: context.bodyLarge.size(13).colorExt(
                        ColorManager.white.withValues(alpha: 0.6),
                      ),
                )
              : TextButtonWidget(
                  onTap: () => bloc.add(RecoverResendOtpEvent(context: context)),
                  content: TextWidget(
                    context.tr(AuthStrings.resendCode),
                    style: context.bodyLarge
                        .size(13)
                        .w500
                        .colorExt(ColorManager.lumiaAccentLight),
                  ),
                ),
        ),
        20.hBox,
        _cta(
          context,
          title: context.tr(AuthStrings.verify),
          valid: valid,
          isLoading: loading,
          onTap: () => bloc.add(RecoverVerifyOtpEvent(context: context)),
        ),
      ];

  // ── Step 3: new password ──────────────────────────────────
  List<Widget> _passwordStep(
    BuildContext context,
    RecoverPasswordState state,
    bool valid,
    bool loading,
    RecoverPasswordBloc bloc,
  ) =>
      [
        _title(
          context,
          context.tr(AuthStrings.setNewPasswordTitle),
          context.tr(AuthStrings.setNewPasswordSubtitle),
        ),
        28.hBox,
        _field(
          context,
          hint: context.tr(AuthStrings.newPassword),
          icon: Icons.lock_outline_rounded,
          controller: state.passwordController,
          isPassword: state.isPassword,
          suffixIcon: state.passwordSuffix,
          onSuffix: () => bloc.add(const RecoverTogglePasswordEvent()),
          validator: (v) => (v == null || v.length < 6)
              ? context.tr(AuthStrings.passwordTooShort)
              : null,
        ),
        16.hBox,
        _field(
          context,
          hint: context.tr(AuthStrings.confirmPassword),
          icon: Icons.lock_outline_rounded,
          controller: state.confirmController,
          isPassword: state.isConfirmPassword,
          suffixIcon: state.confirmSuffix,
          onSuffix: () => bloc.add(const RecoverToggleConfirmEvent()),
          validator: (v) => (v != state.passwordController.text)
              ? context.tr(AuthStrings.passwordsDoNotMatch)
              : null,
        ),
        28.hBox,
        _cta(
          context,
          title: context.tr(AuthStrings.saveNewPassword),
          valid: valid,
          isLoading: loading,
          onTap: () => bloc.add(RecoverResetPasswordEvent(context: context)),
        ),
      ];
}
