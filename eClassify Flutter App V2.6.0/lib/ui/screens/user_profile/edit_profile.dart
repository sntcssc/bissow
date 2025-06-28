import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/auth_cubit.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/location/fetch_paid_api_location_cubit.dart';
import 'package:eClassify/data/cubits/slider_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/data/model/user_model.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/image_picker.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';

class AddressComponent {
  final String? area;
  final int? areaId;
  final String? city;
  final String? state;
  final String? country;
  final String mixed;

  AddressComponent({
    this.area,
    this.areaId,
    this.city,
    this.state,
    this.country,
  }) : mixed = _generateMixedString(area, city, state, country);

  AddressComponent.copyWithFields(
      AddressComponent original, {
        String? newArea,
        int? newAreaId,
        String? newCity,
        String? newState,
        String? newCountry,
      })  : area = newArea ?? original.area,
        areaId = newAreaId ?? original.areaId,
        city = newCity ?? original.city,
        state = newState ?? original.state,
        country = newCountry ?? original.country,
        mixed = _generateMixedString(
          newArea ?? original.area,
          newCity ?? original.city,
          newState ?? original.state,
          newCountry ?? original.country,
        );

  static String _generateMixedString(
      String? area, String? city, String? state, String? country) {
    return [area, city, state, country]
        .where((element) => element != null && element.isNotEmpty)
        .join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'areaId': areaId,
      'city': city,
      'state': state,
      'country': country,
      'mixed': mixed,
    };
  }

  factory AddressComponent.fromMap(Map<String, dynamic> map) {
    return AddressComponent(
      area: map['area'],
      areaId: map['areaId'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
    );
  }

  @override
  String toString() {
    return 'AddressComponent{area: $area, areaId: $areaId, city: $city, state: $state, country: $country, mixed: $mixed}';
  }
}

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        navigateToHome: arguments['navigateToHome'] as bool?,
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController phoneController = TextEditingController();
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityTextController = TextEditingController();
  final TextEditingController countryTextController = TextEditingController();
  dynamic size;
  AddressComponent? formatedAddress;
  double? latitude, longitude;
  String? name, email, address;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";
  final ImagePicker picker = ImagePicker();
  PickImage profileImagePicker = PickImage();
  bool isFromLogin = false;

  @override
  void initState() {
    super.initState();
    isFromLogin = widget.from == 'login';

    // Initialize user details
    final userDetails = HiveUtils.getUserDetails();
    nameController.text = userDetails.name ?? "";
    emailController.text = userDetails.email ?? "";
    addressController.text = userDetails.address ?? "";

    // Initialize location only if at least one location field is non-null and non-empty
    if (userDetails.area != null ||
        userDetails.city != null ||
        userDetails.state != null ||
        userDetails.country != null ||
        userDetails.latitude != null ||
        userDetails.longitude != null ||
        userDetails.areaId != null) {
      formatedAddress = AddressComponent(
        area: userDetails.area?.isNotEmpty == true ? userDetails.area : null,
        areaId: userDetails.areaId,
        city: userDetails.city?.isNotEmpty == true ? userDetails.city : null,
        state: userDetails.state?.isNotEmpty == true ? userDetails.state : null,
        country: userDetails.country?.isNotEmpty == true ? userDetails.country : null,
      );
      latitude = userDetails.latitude;
      longitude = userDetails.longitude;
      log('Initialized location: formatedAddress=$formatedAddress, latitude=$latitude, longitude=$longitude, areaId=${userDetails.areaId}');
    } else {
      formatedAddress = null;
      latitude = null;
      longitude = null;
      log('No location data found in user details');
    }

    if (isFromLogin) {
      isNotificationsEnabled = true;
      isPersonalDetailShow = true;
    } else {
      isNotificationsEnabled = userDetails.notification == 1 ? true : false;
      isPersonalDetailShow = userDetails.isPersonalDetailShow == 1 ? true : false;
    }

    if (HiveUtils.getCountryCode() != null) {
      countryCode = HiveUtils.getCountryCode() ?? '';
      phoneController.text = userDetails.mobile != null
          ? userDetails.mobile!.replaceFirst("+$countryCode", "")
          : "";
    } else {
      phoneController.text = userDetails.mobile ?? "";
    }

    profileImagePicker.listener((files) {
      if (files != null && files.isNotEmpty) {
        setState(() {
          fileUserimg = files.first;
        });
      }
    });
  }

  @override
  void dispose() {
    profileImagePicker.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityTextController.dispose();
    countryTextController.dispose();
    super.dispose();
  }

  Future<void> getLocationFromLatitudeLongitude({required LatLng latLng}) async {
    double newLatitude = latLng.latitude;
    double newLongitude = latLng.longitude;

    if (Constant.mapProvider == "free_api") {
      try {
        await setLocaleIdentifier("en_US");
        Placemark? placeMark =
            (await placemarkFromCoordinates(newLatitude, newLongitude)).first;

        formatedAddress = AddressComponent(
          area: placeMark.subLocality?.isNotEmpty == true ? placeMark.subLocality : null,
          areaId: null,
          city: placeMark.locality?.isNotEmpty == true ? placeMark.locality : null,
          country: placeMark.country?.isNotEmpty == true ? placeMark.country : null,
          state: placeMark.administrativeArea?.isNotEmpty == true ? placeMark.administrativeArea : null,
        );
        latitude = newLatitude;
        longitude = newLongitude;
        log('Fetched location (free_api): $formatedAddress');
        setState(() {});
      } catch (e) {
        log('Error fetching location (free_api): $e');
        formatedAddress = null;
        latitude = null;
        longitude = null;
        setState(() {});
      }
    } else {
      try {
        final paidCubit = context.read<PaidApiLocationDataCubit>();
        await paidCubit.fetchPaidApiLocations(lat: newLatitude, lng: newLongitude);

        final state = paidCubit.state;
        if (state is PaidApiLocationSuccess && state.locations.isNotEmpty) {
          final location = state.locations.first;

          formatedAddress = AddressComponent(
            area: location.sublocality?.isNotEmpty == true ? location.sublocality : null,
            areaId: null,
            city: (location.locality ?? location.name)?.isNotEmpty == true ? (location.locality ?? location.name) : null,
            country: location.country?.isNotEmpty == true ? location.country : null,
            state: location.state?.isNotEmpty == true ? location.state : null,
          );
          latitude = newLatitude;
          longitude = newLongitude;
          log('Fetched location (paid_api): $formatedAddress');
          setState(() {});
        } else {
          formatedAddress = null;
          latitude = null;
          longitude = null;
          log('No location data from paid API');
          setState(() {});
        }
      } catch (e) {
        log('Error fetching location (paid_api): $e');
        formatedAddress = null;
        latitude = null;
        longitude = null;
        setState(() {});
      }
    }
  }

  void dialogueBottomSheet({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required int from,
  }) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: dialogueWidget(title, controller, hintText),
        acceptButtonName: "add".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_formKey.currentState!.validate()) {
            setState(() {
              if (formatedAddress != null) {
                if (from == 1) {
                  formatedAddress = AddressComponent.copyWithFields(
                    formatedAddress!,
                    newCity: controller.text.isNotEmpty ? controller.text : null,
                  );
                } else if (from == 3) {
                  formatedAddress = AddressComponent.copyWithFields(
                    formatedAddress!,
                    newCountry: controller.text.isNotEmpty ? controller.text : null,
                  );
                }
              } else {
                if (from == 1) {
                  formatedAddress = AddressComponent(
                    area: null,
                    areaId: null,
                    city: controller.text.isNotEmpty ? controller.text : null,
                    country: null,
                    state: null,
                  );
                } else if (from == 3) {
                  formatedAddress = AddressComponent(
                    area: null,
                    areaId: null,
                    city: null,
                    country: controller.text.isNotEmpty ? controller.text : null,
                    state: null,
                  );
                }
              }
              log('Updated formatedAddress from dialog: $formatedAddress');
              Navigator.pop(context);
            });
          }
        }),
      ),
    );
  }

  Widget dialogueWidget(
      String title, TextEditingController controller, String hintText) {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                fontSize: context.font.larger,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.bold,
              ),
              Divider(
                thickness: 1,
                color: context.color.textLightColor.withValues(alpha: 0.2),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                    bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                    start: 20,
                    end: 20,
                    top: 18),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.color.textDefaultColor
                          .withValues(alpha: 0.5)),
                  controller: controller,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val, context: context);
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    fillColor:
                    context.color.textLightColor.withValues(alpha: 0.15),
                    filled: true,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    hintText: hintText,
                    hintStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.color.textDefaultColor
                            .withValues(alpha: 0.5)),
                    focusColor: context.color.territoryColor,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.color.textLightColor
                                .withValues(alpha: 0.35))),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.color.textLightColor
                                .withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: context.color.territoryColor)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    log('Building UserProfileScreen, isFromLogin: $isFromLogin, formatedAddress: $formatedAddress');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: safeAreaCondition(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: isFromLogin
              ? null
              : UiUtils.buildAppBar(context,
              showBackButton: true,
              title: "editprofile".translate(context)),
          body: Stack(
            children: [
              ScrollConfiguration(
                behavior: RemoveGlow(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          alignment: AlignmentDirectional.center,
                          child: buildProfilePicture(),
                        ),
                        buildTextField(
                          context,
                          title: "fullName",
                          controller: nameController,
                          validator: CustomTextFieldValidator.nullCheck,
                        ),
                        buildTextField(
                          context,
                          readOnly: [
                            AuthenticationType.email.name,
                            AuthenticationType.google.name,
                            AuthenticationType.apple.name
                          ].contains(HiveUtils.getUserDetails().type),
                          title: "emailAddress",
                          controller: emailController,
                          validator: CustomTextFieldValidator.email,
                        ),
                        phoneWidget(),
                        buildTextField(
                          context,
                          title: "addressLbl",
                          controller: addressController,
                          maxline: 5,
                          textInputAction: TextInputAction.newline,
                        ),
                        buildLocationWidget(),
                        CustomText(
                          "notification".translate(context),
                        ),
                        buildEnableDisableSwitch(isNotificationsEnabled,
                                (cgvalue) {
                              isNotificationsEnabled = cgvalue;
                              setState(() {});
                            }),
                        CustomText(
                          "showContactInfo".translate(context),
                        ),
                        buildEnableDisableSwitch(isPersonalDetailShow,
                                (cgvalue) {
                              isPersonalDetailShow = cgvalue;
                              setState(() {});
                            }),
                        updateProfileBtnWidget(),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading != null && isLoading!)
                Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
              if (isFromLogin)
                Positioned(
                  left: 10,
                  top: 10,
                  child: BackButton(),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLocationWidget() {
    log('Rendering buildLocationWidget, formatedAddress: $formatedAddress');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.color.textLightColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
        color: context.color.secondaryColor.withOpacity(0.1),
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "selectYourLocation".translate(context),
            color: context.color.textDefaultColor,
            fontSize: context.font.larger,
            fontWeight: FontWeight.bold,
          ),
          Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      width: Constant.borderWidth,
                      color: context.color.borderColor),
                ),
                child: SizedBox(
                  width: 8.11,
                  height: 5.67,
                  child: SvgPicture.asset(
                    AppIcons.location,
                    fit: BoxFit.none,
                    colorFilter: ColorFilter.mode(
                        context.color.territoryColor, BlendMode.srcIn),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      formatedAddress == null ||
                          (formatedAddress!.city == null &&
                              formatedAddress!.area == null)
                          ? "selectLocation".translate(context)
                          : (formatedAddress!.city == null ||
                          formatedAddress!.city!.isEmpty)
                          ? (formatedAddress!.area != null &&
                          formatedAddress!.area!.isNotEmpty
                          ? formatedAddress!.area!
                          : "selectLocation".translate(context))
                          : (formatedAddress!.area != null &&
                          formatedAddress!.area!.isNotEmpty
                          ? "${formatedAddress!.area!}, ${formatedAddress!.city!}"
                          : formatedAddress!.city!),
                      fontSize: context.font.large,
                      color: context.color.textDefaultColor,
                    ),
                    CustomText(
                      formatedAddress == null ||
                          (formatedAddress!.state == null &&
                              formatedAddress!.country == null)
                          ? "____, ____"
                          : "${formatedAddress!.state?.isNotEmpty == true ? formatedAddress!.state : "____"}, ${formatedAddress!.country?.isNotEmpty == true ? formatedAddress!.country : "____"}",
                      color: context.color.textLightColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  height: 48,
                  onPressed: () {
                    log('Navigating to countriesScreen');
                    Navigator.pushNamed(context, Routes.countriesScreen,
                        arguments: {"from": "profile"}).then((value) {
                      if (value != null) {
                        Map<String, dynamic> location =
                        value as Map<String, dynamic>;
                        setState(() {
                          formatedAddress = AddressComponent(
                            area: location["area"]?.isNotEmpty == true
                                ? location["area"]
                                : null,
                            areaId: location["area_id"],
                            city: location["city"]?.isNotEmpty == true
                                ? location["city"]
                                : null,
                            country: location["country"]?.isNotEmpty == true
                                ? location["country"]
                                : null,
                            state: location["state"]?.isNotEmpty == true
                                ? location["state"]
                                : null,
                          );
                          latitude = location["latitude"];
                          longitude = location["longitude"];
                          log('Updated formatedAddress from countriesScreen: $formatedAddress');
                        });
                      }
                    });
                  },
                  fontSize: 14,
                  buttonTitle: "changeLocation".translate(context),
                  textColor: context.color.textDefaultColor,
                  buttonColor: context.color.secondaryColor,
                  border: BorderSide(
                      color: context.color.textDefaultColor.withValues(alpha: 0.3),
                      width: 1.5),
                  radius: 5,
                ),
              ),
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  height: 48,
                  onPressed: () async {
                    log('Requesting current location');
                    LocationPermission permission =
                    await Geolocator.checkPermission();
                    if (permission == LocationPermission.deniedForever) {
                      log('Location permission denied forever');
                      await Geolocator.openLocationSettings();
                    } else if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission != LocationPermission.whileInUse &&
                          permission != LocationPermission.always) {
                        log('Location permission denied');
                        return;
                      }
                    }
                    try {
                      Position position = await Geolocator.getCurrentPosition(
                          locationSettings:
                          LocationSettings(accuracy: LocationAccuracy.high));
                      latitude = position.latitude;
                      longitude = position.longitude;
                      log('Current position: ($latitude, $longitude)');
                      await getLocationFromLatitudeLongitude(
                          latLng: LatLng(latitude!, longitude!));
                    } catch (e) {
                      log('Error getting current location: $e');
                      HelperUtils.showSnackBarMessage(
                          context, "locationError".translate(context));
                    }
                  },
                  fontSize: 14,
                  buttonTitle: "useCurrentLocation".translate(context),
                  textColor: context.color.textDefaultColor,
                  buttonColor: context.color.onTertiary,
                  border: BorderSide(
                      color: context.color.textDefaultColor.withValues(alpha: 0.3),
                      width: 1.5),
                  radius: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget phoneWidget() {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "phoneNumber".translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: phoneController,
          validator: CustomTextFieldValidator.phoneNumber,
          keyboard: TextInputType.phone,
          isReadOnly:
          HiveUtils.getUserDetails().type == AuthenticationType.phone.name,
          fillColor: context.color.secondaryColor,
          onChange: (value) {
            setState(() {});
          },
          isMobileRequired: false,
          fixedPrefix: GestureDetector(
            onTap: () {
              if (HiveUtils.getUserDetails().type !=
                  AuthenticationType.phone.name) {
                showCountryCode();
              }
            },
            child: Container(
              width: 55,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              alignment: Alignment.center,
              child: CustomText(
                formatCountryCode(countryCode!),
                fontSize: context.font.large,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          hintText: "phoneNumber".translate(context),
        ),
      ],
    );
  }

  String formatCountryCode(String countryCode) {
    if (countryCode.startsWith('+')) {
      return countryCode;
    } else {
      return '+$countryCode';
    }
  }

  Widget safeAreaCondition({required Widget child}) {
    if (isFromLogin) {
      return SafeArea(child: child);
    }
    return child;
  }

  Widget buildEnableDisableSwitch(bool value, Function(bool) onChangeFunction) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.color.textLightColor.withValues(alpha: 0.23),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: context.color.secondaryColor,
      ),
      height: 60,
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            (value ? "enabled" : "disabled").translate(context),
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          CupertinoSwitch(
            activeTrackColor: context.color.territoryColor,
            value: value,
            onChanged: onChangeFunction,
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
      BuildContext context, {
        required String title,
        required TextEditingController controller,
        CustomTextFieldValidator? validator,
        bool? readOnly,
        int? maxline,
        TextInputAction? textInputAction,
      }) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          fillColor: context.color.secondaryColor,
          action: textInputAction,
          maxLine: maxline,
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(
        fileUserimg!,
        fit: BoxFit.cover,
      );
    } else {
      if (isFromLogin) {
        if (HiveUtils.getUserDetails().profile != null &&
            HiveUtils.getUserDetails().profile!.trim().isNotEmpty) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else if ((HiveUtils.getUserDetails().profile ?? "").trim().isEmpty) {
        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        return UiUtils.getImage(
          HiveUtils.getUserDetails().profile!,
          fit: BoxFit.cover,
        );
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.color.territoryColor, width: 2),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
              height: 37,
              width: 37,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                border:
                Border.all(color: context.color.buttonColor, width: 1.5),
                shape: BoxShape.circle,
                color: context.color.territoryColor,
              ),
              child: SizedBox(
                width: 15,
                height: 15,
                child: UiUtils.getSvg(AppIcons.edit),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (formatedAddress == null ||
          ((formatedAddress!.city == null ||
              formatedAddress!.city!.trim().isEmpty) &&
              (formatedAddress!.area == null ||
                  formatedAddress!.area!.trim().isEmpty))) {
        HelperUtils.showSnackBarMessage(
            context, "cityRequired".translate(context));
        dialogueBottomSheet(
          controller: cityTextController,
          title: "enterCity".translate(context),
          hintText: "city".translate(context),
          from: 1,
        );
        return;
      } else if (formatedAddress == null ||
          (formatedAddress!.country == null ||
              formatedAddress!.country!.trim().isEmpty)) {
        HelperUtils.showSnackBarMessage(
            context, "countryRequired".translate(context));
        dialogueBottomSheet(
          controller: countryTextController,
          title: "enterCountry".translate(context),
          hintText: "country".translate(context),
          from: 3,
        );
        return;
      }
      if (isFromLogin) {
        HiveUtils.setUserIsAuthenticated(true);
      }
      profileUpdateProcess();
    }
  }

  void profileUpdateProcess() async {
    setState(() {
      isLoading = true;
    });
    try {
      var response = await context.read<AuthCubit>().updateuserdata(
        context,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        fileUserimg: fileUserimg,
        address: addressController.text,
        mobile: phoneController.text,
        notification: isNotificationsEnabled ? "1" : "0",
        countryCode: countryCode ?? '',
        personalDetail: isPersonalDetailShow ? 1 : 0,
        area: formatedAddress?.area,
        city: formatedAddress?.city,
        state: formatedAddress?.state,
        country: formatedAddress?.country,
        latitude: latitude,
        longitude: longitude,
        areaId: formatedAddress?.areaId,
      );

      log('Profile update response: $response');
      Future.delayed(
        Duration.zero,
            () {
          context
              .read<UserDetailsCubit>()
              .copy(UserModel.fromJson(response['data']));

          setState(() {
            isLoading = false;
          });
          HelperUtils.showSnackBarMessage(
            context,
            response['message'],
          );
          if (!isFromLogin) {
            Navigator.pop(context);
          }
        },
      );

      if (isFromLogin) {
        Future.delayed(
          Duration.zero,
              () {
            if (widget.popToCurrent ?? false) {
              Navigator.of(context)
                ..pop()
                ..pop();
            } else if (HiveUtils.getCityName() != null &&
                HiveUtils.getCityName()!.trim().isNotEmpty) {
              HelperUtils.killPreviousPages(
                  context, Routes.main, {"from": widget.from});
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.locationPermissionScreen, (route) => false);
            }
          },
        );
      }
    } catch (e) {
      log('Error updating profile: $e');
      Future.delayed(Duration.zero, () {
        setState(() {
          isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString());
      });
    }
  }

  void showPicker() {
    UiUtils.imagePickerBottomSheet(
      context,
      isRemovalWidget: fileUserimg != null && isFromLogin,
      callback: (bool isRemoved, ImageSource? source) async {
        if (isRemoved) {
          setState(() {
            fileUserimg = null;
          });
        } else if (source != null) {
          await profileImagePicker.pick(
              context: context, source: source, pickMultiple: false);
        }
      },
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
      CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget updateProfileBtnWidget() {
    return UiUtils.buildButton(
      context,
      outerPadding: const EdgeInsetsDirectional.only(top: 15),
      onPressed: () {
        if (!isFromLogin && formatedAddress != null) {
          HiveUtils.setCurrentLocation(
            city: formatedAddress!.city ?? '',
            state: formatedAddress!.state ?? '',
            country: formatedAddress!.country ?? '',
            latitude: latitude,
            longitude: longitude,
          );
          context.read<SliderCubit>().fetchSlider(context);
        } else if (!isFromLogin) {
          HiveUtils.clearLocation();
          context.read<SliderCubit>().fetchSlider(context);
        }
        validateData();
      },
      height: 48,
      buttonTitle: "updateProfile".translate(context),
    );
  }
}