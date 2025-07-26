import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/marquee/manage_marquee_message_cubit.dart';
import 'package:eClassify/data/cubits/location/fetch_paid_api_location_cubit.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/data/model/marquee_message_model.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:eClassify/ui/screens/marquee/my_marquee_message_tab_screen.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ConfirmMarqueeMessageLocationScreen extends StatefulWidget {
  final bool? isEdit;
  final File? mainImage;

  const ConfirmMarqueeMessageLocationScreen({
    Key? key,
    required this.isEdit,
    required this.mainImage,
  }) : super(key: key);

  static MaterialPageRoute route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (context) => ManageMarqueeMessageCubit(),
        child: ConfirmMarqueeMessageLocationScreen(
          isEdit: arguments?['isEdit'] ?? false,
          mainImage: arguments?['mainImage'],
        ),
      ),
    );
  }

  @override
  _ConfirmMarqueeMessageLocationScreenState createState() => _ConfirmMarqueeMessageLocationScreenState();
}

class _ConfirmMarqueeMessageLocationScreenState extends CloudState<ConfirmMarqueeMessageLocationScreen>
    with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController cityTextController = TextEditingController();
  TextEditingController countryTextController = TextEditingController();
  String currentLocation = '';
  AddressComponent? formatedAddress;
  double? latitude, longitude;
  CameraPosition? _cameraPosition;
  final Set<Marker> _markers = Set();
  late GoogleMapController _mapController;
  var markerMove;
  bool _openedAppSettings = false;

  @override
  void initState() {
    _getCurrentLocation();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    cityTextController.dispose();
    countryTextController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _openedAppSettings) {
      _openedAppSettings = false;
      _getCurrentLocation();
      setState(() {});
    }
  }

  void preFillLocationWhileEdit() async {
    if (widget.isEdit ?? false) {
      final messageData = getCloudData('edit_request');
      if (messageData == null || messageData is! MarqueeMessageModel) {
        // Handle null or invalid edit_request by falling back to default location
        HelperUtils.showSnackBarMessage(context, "failedToLoadEditData".translate(context));
        defaultLocation();
        return;
      }
      MarqueeMessageModel message = messageData as MarqueeMessageModel;
      currentLocation = [
        message.areaId != null ? "Area ID: ${message.areaId}" : null,
        message.city,
        message.state,
        message.country,
      ].where((part) => part != null && part.isNotEmpty).join(', ');
      formatedAddress = AddressComponent(
        area: message.areaId != null ? "Area ID: ${message.areaId}" : null,
        areaId: message.areaId,
        city: message.city,
        country: message.country,
        state: message.state,
      );
      latitude = message.latitude;
      longitude = message.longitude;
      _cameraPosition = CameraPosition(
        target: LatLng(message.latitude ?? double.parse(Constant.defaultLatitude), message.longitude ?? double.parse(Constant.defaultLongitude)),
        zoom: 14.4746,
        bearing: 0,
      );
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(message.latitude ?? double.parse(Constant.defaultLatitude), message.longitude ?? double.parse(Constant.defaultLongitude)),
      ));
    } else {
      currentLocation = [
        HiveUtils.getCurrentAreaName(),
        HiveUtils.getCurrentCityName(),
        HiveUtils.getCurrentStateName(),
        HiveUtils.getCurrentCountryName(),
      ].where((part) => part != null && part.isNotEmpty).join(', ');
      if (currentLocation == "") {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        );
        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.4746,
          bearing: 0,
        );
        getLocationFromLatitudeLongitude(latLng: LatLng(position.latitude, position.longitude));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
        ));
        latitude = position.latitude;
        longitude = position.longitude;
      } else {
        formatedAddress = AddressComponent(
          area: HiveUtils.getCurrentAreaName(),
          areaId: null,
          city: HiveUtils.getCurrentCityName(),
          country: HiveUtils.getCurrentCountryName(),
          state: HiveUtils.getCurrentStateName(),
        );
        latitude = HiveUtils.getCurrentLatitude();
        longitude = HiveUtils.getCurrentLongitude();
        _cameraPosition = CameraPosition(
          target: LatLng(latitude!, longitude!),
          zoom: 14.4746,
          bearing: 0,
        );
        getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(latitude!, longitude!),
        ));
      }
    }
    setState(() {});
  }

  Future<void> getLocationFromLatitudeLongitude({LatLng? latLng}) async {
    double newLatitude = latLng?.latitude ?? _cameraPosition!.target.latitude;
    double newLongitude = latLng?.longitude ?? _cameraPosition!.target.longitude;

    if (Constant.mapProvider == "free_api") {
      try {
        await setLocaleIdentifier("en_US");
        Placemark? placeMark = (await placemarkFromCoordinates(newLatitude, newLongitude)).first;
        formatedAddress = AddressComponent(
          area: placeMark.subLocality,
          areaId: null,
          city: placeMark.locality,
          country: placeMark.country,
          state: placeMark.administrativeArea,
        );
        setState(() {});
      } catch (e) {
        log(e.toString());
        formatedAddress = null;
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
            area: location.sublocality ?? '',
            areaId: null,
            city: location.locality ?? location.name,
            country: location.country ?? '',
            state: location.state ?? '',
          );
          setState(() {});
        }
      } catch (e) {
        log(e.toString());
        formatedAddress = null;
        setState(() {});
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (Platform.isAndroid) {
        _openedAppSettings = true;
        await Geolocator.openLocationSettings();
      }
      if (widget.isEdit ?? false) {
        preFillLocationWhileEdit();
      } else {
        defaultLocation();
      }
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        if (widget.isEdit ?? false) {
          preFillLocationWhileEdit();
        } else {
          defaultLocation();
        }
      } else {
        _getCurrentLocation();
      }
    } else {
      preFillLocationWhileEdit();
    }
  }

  void defaultLocation() {
    latitude = double.parse(Constant.defaultLatitude);
    longitude = double.parse(Constant.defaultLongitude);
    getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
    _cameraPosition = CameraPosition(
      target: LatLng(latitude!, longitude!),
      zoom: 14.4746,
      bearing: 0,
    );
    _markers.add(Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(latitude!, longitude!),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        Future.delayed(Duration(milliseconds: 500), () {});
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: UiUtils.buildAppBar(context, onBackPress: () {
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pop(context);
          });
        }, showBackButton: true, title: "confirmLocation".translate(context)),
        bottomNavigationBar: BlocConsumer<ManageMarqueeMessageCubit, ManageMarqueeMessageState>(
          listener: (context, state) {
            if (state is ManageMarqueeMessageInProgress) {
              Widgets.showLoader(context);
            } else if (state is ManageMarqueeMessageSuccess) {
              Widgets.hideLoder(context);
              myMarqueeMessagesCubitReference["all"]?.edit(state.model);
              Navigator.pushNamed(context, Routes.successMarqueeMessageScreen, arguments: {
                'model': state.model,
                'isEdit': widget.isEdit,
              });
            } else if (state is ManageMarqueeMessageFail) {
              HelperUtils.showSnackBarMessage(context, state.error.toString());
              Widgets.hideLoder(context);
            }
          },
          builder: (context, state) {
            return UiUtils.buildButton(
              context,
              outerPadding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
                left: 18.0,
                right: 18,
              ),
              onPressed: () async {
                if (context.read<ManageMarqueeMessageCubit>().state is ManageMarqueeMessageInProgress) {
                  return;
                }
                if (formatedAddress == null ||
                    ((formatedAddress!.city == null || formatedAddress!.city!.trim().isEmpty) &&
                        (formatedAddress!.area == null || formatedAddress!.area!.trim().isEmpty))) {
                  HelperUtils.showSnackBarMessage(context, "cityRequired".translate(context));
                  Future.delayed(Duration(seconds: 2), () {
                    dialogueBottomSheet(
                      controller: cityTextController,
                      title: "enterCity".translate(context),
                      hintText: "city".translate(context),
                      from: 1,
                    );
                  });
                } else if (formatedAddress == null || (formatedAddress!.country == null || formatedAddress!.country!.trim().isEmpty)) {
                  HelperUtils.showSnackBarMessage(context, "countryRequired".translate(context));
                  Future.delayed(Duration(seconds: 2), () {
                    dialogueBottomSheet(
                      controller: countryTextController,
                      title: "enterCountry".translate(context),
                      hintText: "country".translate(context),
                      from: 3,
                    );
                  });
                } else {
                  try {
                    Map<String, dynamic> cloudData = getCloudData("marquee_message_details") ?? {};
                    cloudData['address'] = formatedAddress?.mixed;
                    if (latitude != null) cloudData['latitude'] = latitude;
                    if (longitude != null) cloudData['longitude'] = longitude;
                    cloudData['country'] = formatedAddress!.country;
                    cloudData['city'] = (formatedAddress!.city == null || formatedAddress!.city!.trim().isEmpty)
                        ? (formatedAddress!.area == null || formatedAddress!.area!.trim().isEmpty ? null : formatedAddress!.area)
                        : formatedAddress!.city;
                    cloudData['state'] = formatedAddress!.state;
                    if (formatedAddress!.areaId != null) cloudData['area_id'] = formatedAddress!.areaId;

                    if (widget.isEdit ?? false) {
                      context.read<ManageMarqueeMessageCubit>().manage(
                        ManageMarqueeMessageType.edit,
                        cloudData,
                        widget.mainImage,
                      );
                    } else {
                      context.read<ManageMarqueeMessageCubit>().manage(
                        ManageMarqueeMessageType.add,
                        cloudData,
                        widget.mainImage,
                      );
                    }
                  } catch (e, st) {
                    log("Error submitting marquee message: $e");
                    HelperUtils.showSnackBarMessage(context, "failedToSubmit".translate(context));
                  }
                }
              },
              height: 48,
              fontSize: context.font.large,
              autoWidth: false,
              radius: 8,
              disabledColor: const Color.fromARGB(255, 104, 102, 106),
              disabled: (state is ManageMarqueeMessageInProgress ||
                  formatedAddress == null ||
                  ((formatedAddress!.city == null || formatedAddress!.city!.trim().isEmpty) &&
                      (formatedAddress!.area == null || formatedAddress!.area!.trim().isEmpty)) ||
                  (formatedAddress!.country == null || formatedAddress!.country!.trim().isEmpty)),
              width: double.maxFinite,
              buttonTitle: "postNow".translate(context),
            );
          },
        ),
        body: bodyData(),
      ),
    );
  }

  Widget bodyData() {
    return _cameraPosition != null
        ? Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: CustomText(
              "locationMessageDisplayLbl".translate(context),
              fontWeight: FontWeight.bold,
              fontSize: context.font.larger,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20, right: 15, left: 15),
            child: UiUtils.buildButton(
              context,
              height: 48,
              onPressed: () {
                Navigator.pushNamed(context, Routes.countriesScreen, arguments: {"from": "addMarqueeMessage"}).then((value) {
                  if (value != null) {
                    Map<String, dynamic> location = value as Map<String, dynamic>;
                    setState(() {
                      currentLocation = [
                        location["area"] ?? null,
                        location["city"] ?? null,
                        location["state"] ?? null,
                        location["country"] ?? null,
                      ].where((part) => part != null && part.isNotEmpty).join(', ');
                      formatedAddress = AddressComponent(
                        area: location["area"] ?? null,
                        areaId: location["area_id"] ?? null,
                        city: location["city"] ?? null,
                        country: location["country"] ?? null,
                        state: location["state"] ?? null,
                      );
                      latitude = location["latitude"] ?? null;
                      longitude = location["longitude"] ?? null;
                      _cameraPosition = CameraPosition(
                        target: LatLng(latitude!, longitude!),
                        zoom: 14.4746,
                        bearing: 0,
                      );
                      _mapController.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition!));
                      _markers.add(Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: LatLng(latitude!, longitude!),
                      ));
                    });
                  }
                });
              },
              fontSize: 14,
              buttonTitle: "somewhereElseLbl".translate(context),
              textColor: context.color.textDefaultColor,
              buttonColor: context.color.secondaryColor,
              border: BorderSide(
                color: context.color.textDefaultColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              radius: 5,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GoogleMap(
                      onCameraMove: (position) {
                        _cameraPosition = position;
                      },
                      onCameraIdle: () async {
                        if (markerMove == false) {
                          if (LatLng(latitude!, longitude!) ==
                              LatLng(_cameraPosition!.target.latitude, _cameraPosition!.target.longitude)) {
                          } else {
                            getLocationFromLatitudeLongitude();
                          }
                        }
                      },
                      initialCameraPosition: _cameraPosition!,
                      markers: _markers,
                      zoomControlsEnabled: false,
                      minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                      compassEnabled: true,
                      indoorViewEnabled: true,
                      mapToolbarEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      gestureRecognizers: getMapGestureRecognizers(),
                      onMapCreated: (GoogleMapController controller) {
                        Future.delayed(const Duration(milliseconds: 500)).then((value) {
                          _mapController = controller;
                          _mapController.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition!));
                        });
                      },
                      onTap: (latLng) {
                        setState(() {
                          _markers.clear();
                          _markers.add(Marker(
                            markerId: MarkerId('selectedLocation'),
                            position: latLng,
                          ));
                          latitude = latLng.latitude;
                          longitude = latLng.longitude;
                          getLocationFromLatitudeLongitude(latLng: latLng);
                        });
                      },
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 30,
                  bottom: 15,
                  child: InkWell(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.color.borderColor,
                          width: Constant.borderWidth,
                        ),
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location_sharp),
                    ),
                    onTap: () async {
                      Position position = await Geolocator.getCurrentPosition(
                        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
                      );
                      _cameraPosition = CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 14.4746,
                        bearing: 0,
                      );
                      getLocationFromLatitudeLongitude();
                      _mapController.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition!));
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: context.screenWidth,
            padding: const EdgeInsets.all(15.0),
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: context.color.territoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(width: Constant.borderWidth, color: context.color.borderColor),
                    ),
                    child: SizedBox(
                      width: 8.11,
                      height: 5.67,
                      child: SvgPicture.asset(
                        AppIcons.location,
                        fit: BoxFit.none,
                        colorFilter: ColorFilter.mode(context.color.territoryColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        formatedAddress == null
                            ? "____"
                            : (formatedAddress!.city == null || formatedAddress!.city!.isEmpty)
                            ? (formatedAddress!.area != null && formatedAddress!.area!.isNotEmpty
                            ? formatedAddress!.area!
                            : "____")
                            : (formatedAddress!.area != null && formatedAddress!.area!.isNotEmpty
                            ? "${formatedAddress!.area!}, ${formatedAddress!.city!}"
                            : formatedAddress!.city!),
                        fontSize: context.font.large,
                      ),
                      CustomText(
                        "${formatedAddress == null || (formatedAddress?.state == "" || formatedAddress?.state == null) ? "____" : formatedAddress?.state},${formatedAddress == null || formatedAddress!.country == "" ? "____" : formatedAddress!.country}",
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    )
        : shimmerEffect();
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
                  formatedAddress = AddressComponent.copyWithFields(formatedAddress!, newCity: controller.text);
                } else if (from == 3) {
                  formatedAddress = AddressComponent.copyWithFields(formatedAddress!, newCountry: controller.text);
                }
              } else {
                if (from == 1) {
                  formatedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: controller.text,
                    country: "",
                    state: "",
                  );
                } else if (from == 3) {
                  formatedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: "",
                    country: controller.text,
                    state: "",
                  );
                }
              }
              Navigator.pop(context);
            });
          }
        }),
      ),
    );
  }

  Widget dialogueWidget(String title, TextEditingController controller, String hintText) {
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
                  top: 18,
                ),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor.withValues(alpha: 0.5),
                  ),
                  controller: controller,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val, context: context);
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    fillColor: context.color.textLightColor.withValues(alpha: 0.15),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                    ),
                    focusColor: context.color.territoryColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withValues(alpha: 0.35)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.color.textLightColor.withValues(alpha: 0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.color.territoryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> getMapGestureRecognizers() {
    return <Factory<OneSequenceGestureRecognizer>>{
      Factory<PanGestureRecognizer>(() => PanGestureRecognizer()..onUpdate = (dragUpdateDetails) {}),
      Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()..onStart = (dragUpdateDetails) {}),
      Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer()
          ..onDown = (dragUpdateDetails) {
            if (markerMove == false) {
            } else {
              setState(() {
                markerMove = false;
              });
            }
          },
      ),
    };
  }

  Widget shimmerEffect() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
          highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
          child: Container(
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey),
            alignment: AlignmentDirectional.center,
            margin: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
            highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
            child: Container(
              height: 400,
              margin: EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
            highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey),
              height: 146,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ],
    );
  }
}