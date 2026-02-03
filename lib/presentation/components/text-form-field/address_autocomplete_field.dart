import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/model/location/prediction.dart';
import 'package:ovorideuser/data/repo/location/location_search_repo.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';

/// Address Autocomplete Field with Google Places integration
/// Provides auto-suggestions and current location detection
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final Function(Map<String, String> addressComponents)? onAddressSelected;
  final bool showCurrentLocationButton;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.focusNode,
    this.nextFocus,
    this.onAddressSelected,
    this.showCurrentLocationButton = true,
    this.validator,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final LocationSearchRepo _locationSearchRepo = Get.find<LocationSearchRepo>();
  Timer? _debounceTimer;
  
  List<Prediction> _predictions = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    _removeOverlay();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus == false) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    if (widget.controller.text.isEmpty) {
      _removeOverlay();
      return;
    }

    if (widget.controller.text.length < 3) return;

    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(widget.controller.text);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty || query.length < 3) return;

    setState(() => _isSearching = true);

    try {
      final response = await _locationSearchRepo.searchAddressByLocationName(text: query);
      
      if (response.statusCode == 200) {
        final data = response.responseJson;
        if (data['predictions'] != null) {
          _predictions = (data['predictions'] as List)
              .map((json) => Prediction.fromJson(json))
              .toList();
          
          if (_predictions.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Address search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: context.width - (Dimensions.space20 * 2),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: MyColor.getCardBgColor(),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                border: Border.all(color: MyColor.borderColor),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: MyColor.borderColor,
                ),
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: CustomSvgPicture(
                      image: MyIcons.location,
                      color: MyColor.getPrimaryColor(),
                      height: 20,
                      width: 20,
                    ),
                    title: Text(
                      prediction.description ?? '',
                      style: regularDefault.copyWith(
                        fontSize: Dimensions.fontDefault,
                      ),
                    ),
                    onTap: () => _onPredictionSelected(prediction),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onPredictionSelected(Prediction prediction) async {
    _removeOverlay();
    
    // Clear predictions to prevent reopening
    setState(() {
      _predictions.clear();
    });
    
    // Unfocus the field to prevent onTap from showing overlay
    widget.focusNode?.unfocus();
    
    widget.controller.text = prediction.description ?? '';
    
    try {
      final response = await _locationSearchRepo.getPlaceDetailsFromPlaceId(prediction);
      
      if (response.statusCode == 200) {
        final data = response.responseJson;
        final result = data['result'];
        
        if (result != null) {
          final addressComponents = result['address_components'] as List?;
          final geometry = result['geometry'];
          
          // Extract address components
          Map<String, String> components = {
            'full_address': result['formatted_address'] ?? '',
            'city': '',
            'state': '',
            'country': '',
            'postal_code': '',
            'latitude': geometry?['location']?['lat']?.toString() ?? '',
            'longitude': geometry?['location']?['lng']?.toString() ?? '',
          };

          if (addressComponents != null) {
            for (var component in addressComponents) {
              final types = component['types'] as List;
              final longName = component['long_name'] ?? '';

              if (types.contains('locality')) {
                components['city'] = longName;
              } else if (types.contains('administrative_area_level_1')) {
                components['state'] = longName;
              } else if (types.contains('country')) {
                components['country'] = longName;
              } else if (types.contains('postal_code')) {
                components['postal_code'] = longName;
              }
            }
          }

          debugPrint('✅ Address selected: ${components['full_address']}');
          debugPrint('📍 City: ${components['city']}, State: ${components['state']}, Zip: ${components['postal_code']}');

          widget.onAddressSelected?.call(components);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching place details: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Disabled',
          'Please enable location services',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      
      // Reverse geocode to get address
      final address = await _locationSearchRepo.getActualAddress(
        position.latitude,
        position.longitude,
      );

      if (address != null) {
        // Clear predictions to prevent dropdown from showing
        _removeOverlay();
        setState(() {
          _predictions.clear();
        });
        
        widget.controller.text = address;
        
        // Unfocus to prevent any dropdown trigger
        widget.focusNode?.unfocus();
        
        // Get detailed components
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          Map<String, String> components = {
            'full_address': address,
            'city': placemark.locality ?? '',
            'state': placemark.administrativeArea ?? '',
            'country': placemark.country ?? '',
            'postal_code': placemark.postalCode ?? '',
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
          };

          debugPrint('📍 Current location: $address');
          widget.onAddressSelected?.call(components);
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      Get.snackbar(
        'Error',
        'Failed to get current location',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Close overlay when scrolling
        _removeOverlay();
        return false;
      },
      child: GestureDetector(
        onTap: () {
          // Keep focus on field when tapping it
          widget.focusNode?.requestFocus();
        },
        child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (widget.showCurrentLocationButton && !_isSearching)
                    IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: MyColor.getPrimaryColor(),
                      ),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Use current location',
                    ),
                ],
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyColor.getTextFieldDisableBorder(),
                ),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyColor.getPrimaryColor(),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyColor.colorRed,
                ),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyColor.colorRed,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              filled: true,
              fillColor: MyColor.transparentColor,
            ),
            validator: widget.validator,
            onFieldSubmitted: (value) {
              if (widget.nextFocus != null) {
                FocusScope.of(context).requestFocus(widget.nextFocus);
              }
            },
            onTap: () {
              // Don't show overlay on tap - let the text change trigger it
            },
          ),
        ],
      ),
        ),
      ),
    );
  }
}
