part of 'package:authentication/src/presentation/login/view/login_page.dart';

class _FormAuthBody extends StatelessWidget {
  const _FormAuthBody();

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
        return Form(
          key: state.formKey,
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.860,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  10.hBox,
                  Image.asset(
                    fit: BoxFit.contain,
                    AssetManager.logo,
                    width: MediaQuery.of(context).size.width * 0.230,
                  ),
                  10.hBox,
                  TextWidget(
                    context.tr(AuthStrings.hiTemp),
                    style: context.bodyLarge.size(25).w600,
                  ),
                  5.hBox,
                  TextWidget(
                    context.tr(AuthStrings.loginTel),
                    style: context.bodyLarge
                        .size(16)
                        .colorExt(ColorManager.blackColor),
                  ),
                  40.hBox,
                  // Email input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TextWidget(
                            context.tr(AuthStrings.email),
                            style: context.bodyLarge
                                .size(13)
                                .colorExt(
                                  ColorManager.blackColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                          ),
                          TextWidget(
                            " * ",
                            style: context.bodyLarge
                                .size(10)
                                .colorExt(ColorManager.bColor),
                          ),
                        ],
                      ),
                      TextInputWidget(
                        context.tr(AuthStrings.pleaseEnterYourEmail),
                        contentPadding: EdgeInsets.zero,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          context.read<LoginBloc>().add(
                            const UpdateFormValidationEvent(),
                          );
                        },
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        controller: state.emailController,
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
                    ],
                  ),
                  20.hBox,
                  // Password field
                  Column(
                    children: [
                      Row(
                        children: [
                          TextWidget(
                            context.tr(AuthStrings.password),
                            style: context.bodyLarge
                                .size(13)
                                .colorExt(
                                  ColorManager.blackColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                          ),
                          TextWidget(
                            " * ",
                            style: context.bodyLarge
                                .size(10)
                                .colorExt(ColorManager.bColor),
                          ),
                        ],
                      ),
                      TextInputWidget(
                        context.tr(AuthStrings.password),
                        controller: state.passwordController,
                        suffixIcon: state.suffixIcon,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 20,
                          maxWidth: 20,
                          minHeight: 20,
                          maxHeight: 20,
                        ),
                        suffixColor: ColorManager.grey,
                        isPassword: state.isPassword,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          context.read<LoginBloc>().add(
                            const UpdateFormValidationEvent(),
                          );
                        },
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: ColorManager.transparent,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr(AuthStrings.requiredField);
                          }
                          return null;
                        },
                        onPressed: () => context.read<LoginBloc>().add(
                          const TogglePasswordEvent(),
                        ),
                      ),
                    ],
                  ),
                  TextButtonWidget(
                    onTap: () => context.push(AuthRoutes.recoverPassword),
                    content: TextWidget(
                      context.tr(AuthStrings.recoverPassword),
                      style: context.bodyLarge
                          .colorExt(ColorManager.bgLevel)
                          .size(15)
                          .w500,
                    ),
                  ),
                  50.hBox,
                  // Login button
                  Align(
                    alignment: Alignment.center,
                    child: ButtonWidget(
                      title: context.tr(AuthStrings.login),
                      height: 40.h,
                      width: 200.w,
                      padding: EdgeInsets.zero,
                      paddingButton: EdgeInsets.zero,
                      radius: 30.r,
                      backgroundColor: state.isFormValid ?? false
                          ? ColorManager.primary
                          : Colors.grey.shade400,
                      isLoading: state.requestState.isLoading,
                      onPressed: () {
                        if (state.isFormValid == true) {
                          context.read<LoginBloc>().add(
                            LoginWithEmailEvent(context: context),
                          );
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  // Terms footer
                  Align(
                    child: InkWell(
                      onTap: () => context.push(AuthRoutes.privacy),
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          text: context.tr(AuthStrings.agreeLogin),
                          style: context.bodyLarge
                              .size(13)
                              .colorExt(ColorManager.greyTextColor),
                          children: [
                            TextSpan(
                              text: context.tr(AuthStrings.userAgreementLogin),
                              style: context.bodyLarge
                                  .size(13)
                                  .colorExt(ColorManager.primary)
                                  .w600,
                            ),
                            TextSpan(
                              text: context.tr(AuthStrings.andLogin),
                              style: context.bodyLarge
                                  .size(13)
                                  .colorExt(ColorManager.greyTextColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  10.hBox,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
