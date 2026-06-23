part of 'package:authentication/src/presentation/login/view/login_page.dart';

class _FormAuthBody extends StatelessWidget {
  const _FormAuthBody();

  InputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: 16.radius,
        borderSide: BorderSide(color: c ?? ColorManager.frostedBorder, width: 1.2),
      );

  /// Frosted pill field with an inline leading icon (mockup style).
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
          context.read<LoginBloc>().add(const UpdateFormValidationEvent()),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.showRegisterDialog) {
          showDialog(
            context: context,
            builder: (_) => RegisterAnimatedDialog(
              email: state.emailController.text.trim(),
            ),
          ).then((_) {
            if (!context.mounted) return;
            context.read<LoginBloc>().add(const ResetLoginStateEvent());
          });
        }
      },
      builder: (context, state) {
        final valid = state.isFormValid ?? false;
        return Form(
          key: state.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      40.hBox,
                      // Logo as a clean circular badge
                      Center(
                        child: AppLogoBadge(
                          size: 88,
                          fallback: Image.asset(
                            AssetManager.logo,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      24.hBox,
                      TextWidget(
                        context.tr(AuthStrings.hiTemp),
                        textAlign: TextAlign.center,
                        style: context.bodyLarge
                            .size(30)
                            .w700
                            .colorExt(ColorManager.white),
                      ),
                      8.hBox,
                      TextWidget(
                        context.tr(AuthStrings.loginTel),
                        textAlign: TextAlign.center,
                        style: context.bodyLarge.size(15).colorExt(
                              ColorManager.white.withValues(alpha: 0.7),
                            ),
                      ),
                      36.hBox,
                      _field(
                        context,
                        hint: context.tr(AuthStrings.pleaseEnterYourEmail),
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
                      _field(
                        context,
                        hint: context.tr(AuthStrings.password),
                        icon: Icons.lock_outline_rounded,
                        controller: state.passwordController,
                        isPassword: state.isPassword,
                        suffixIcon: state.suffixIcon,
                        onSuffix: () => context
                            .read<LoginBloc>()
                            .add(const TogglePasswordEvent()),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr(AuthStrings.requiredField);
                          }
                          return null;
                        },
                      ),
                      10.hBox,
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButtonWidget(
                          onTap: () => context.push(AuthRoutes.recoverPassword),
                          content: TextWidget(
                            context.tr(AuthStrings.recoverPassword),
                            style: context.bodyLarge
                                .size(14)
                                .w500
                                .colorExt(ColorManager.lumiaAccentLight),
                          ),
                        ),
                      ),
                      28.hBox,
                      // Login button (full-width pink gradient)
                      ButtonWidget(
                        title: context.tr(AuthStrings.login),
                        height: 54.h,
                        width: ScreenUtil().screenWidth,
                        radius: 30.r,
                        backgroundColors: valid
                            ? ColorManager.pinkCtaGradient
                            : ColorManager.pinkCtaGradientMuted,
                        isLoading: state.requestState.isLoading,
                        onPressed: () {
                          if (valid) {
                            context.read<LoginBloc>().add(
                                  LoginWithEmailEvent(context: context),
                                );
                          }
                        },
                      ),
                      20.hBox,
                      // Register link
                      Center(
                        child: InkWell(
                          onTap: () => context.push(AuthRoutes.register),
                          child: Text.rich(
                            TextSpan(
                              text:
                                  '${context.tr(AuthStrings.notRegisteredYet)} ',
                              style: context.bodyLarge.size(14).colorExt(
                                    ColorManager.white.withValues(alpha: 0.7),
                                  ),
                              children: [
                                TextSpan(
                                  text: context.tr(AuthStrings.registerNow),
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
                      const Spacer(),
                      // Terms footer
                      Center(
                        child: InkWell(
                          onTap: () => context.push(AuthRoutes.privacy),
                          child: Text.rich(
                            textAlign: TextAlign.center,
                            TextSpan(
                              text: context.tr(AuthStrings.agreeLogin),
                              style: context.bodyLarge.size(12).colorExt(
                                    ColorManager.white.withValues(alpha: 0.55),
                                  ),
                              children: [
                                TextSpan(
                                  text:
                                      context.tr(AuthStrings.userAgreementLogin),
                                  style: context.bodyLarge
                                      .size(12)
                                      .w600
                                      .colorExt(ColorManager.lumiaAccentLight),
                                ),
                                TextSpan(
                                  text: context.tr(AuthStrings.andLogin),
                                  style: context.bodyLarge.size(12).colorExt(
                                        ColorManager.white.withValues(alpha: 0.55),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      16.hBox,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
