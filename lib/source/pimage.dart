import 'package:flutter/material.dart';
import 'package:paulonia_image_service/source/pimage_service.dart';

/// Image with placeholder for gs urls
///
/// Can be created using a gsUrl. Works with the [IProvider]
/// image provider manager.
// ignore: must_be_immutable
class PImage extends StatelessWidget {
  PImage({
    Key? key,
    required this.gsUrl,
    this.id,
    this.assetName,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover,
    this.circularRadius,
  }) : super(key: key);

  PImage.avatar({
    Key? key,
    required this.gsUrl,
    this.assetName,
    this.id,
    this.radius = 20,
    this.fit = BoxFit.cover,
  }) : super(key: key) {
    width = radius! * 2;
    height = radius! * 2;
  }

  final String gsUrl;
  ImageProvider? imageProvider;

  /// asset path for the placeholder
  final String? assetName;
  final String? id;
  final BoxFit fit;
  double? width;
  double? height;

  double? circularRadius;

  /// Radius for the avatar
  ///
  /// Used to calculate the width and height
  double? radius;

  @override
  Widget build(BuildContext context) {
    Widget _imageWidget;
    if (PImageService.isLoaded(gsUrl)) {
      _imageWidget = Image(
        image: PImageService.getImage(
          gsUrl,
          id: id,
        ),
        fit: fit,
      );
    } else {
      _imageWidget = FadeInImage(
        placeholder: PImageService.getPlaceholder(assetName),
        image: PImageService.getImage(
          gsUrl,
          id: id,
        ),
        fit: fit,
      );
    }

    if (radius != null) {
      return ClipOval(
        child: _imageWidget,
      );
    }

    if (circularRadius != null) {
      _imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(circularRadius!),
        child: _imageWidget,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: _imageWidget,
    );
  }
}
