import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';
import 'package:paulonia_image_service/source/globals.dart';

/// Image provider service for [PImage]
class PImageService {
  static bool isLoaded(String gsUrl) {
    ImageProvider? imageProvider = _imageProviders[gsUrl];
    return imageProvider != null;
  }

  /// Sets the configuration for the PImageService
  static void settings({int? maxCacheSize, int? maxImages}) {
    if (maxImages != null) {
      PImageGlobals.pImageInMemoryImages = maxImages;
    }

    if (maxCacheSize != null) {
      PImageGlobals.pImageInMemorySize = maxCacheSize;
    }
  }

  /// Gets the [ImageProvider] of the provided gsUrl
  ///
  /// If it's the first call using the [gsUrl], then it
  /// creates a [PCacheImage] and stores it. Otherwise
  /// returns the already cached [ImageProvider].
  /// The store [ImageProvider] may be removed once a
  /// limit is reached.
  static ImageProvider getImage(String gsUrl, {String? id}) {
    ImageProvider? imageProvider = _imageProviders[gsUrl];

    id ??= gsUrl;

    imageProvider ??= _addImageProvider(gsUrl, id);

    return imageProvider;
  }

  static void updateImage(String id, ImageProvider image) {
    _imageProviders[id] = image;
  }

  static void preloadImages(
    List<String> gsUrls,
    BuildContext context, {
    Function? onFinish,
  }) {
    int counter = 0;
    for (var gsUrl in gsUrls) {
      precacheImage(PCacheImage(gsUrl), context).then((value) {
        getImage(gsUrl);
        counter++;
        if (counter == gsUrls.length && onFinish != null) {
          onFinish();
        }
      });
    }
  }

  static ImageProvider _addImageProvider(String url, String id) {
    if (_imagesExceeded() || _imagesSizeExceeded()) {
      _clearImages();
      _imageProviders = {};
    }
    ImageProvider imageProvider = PCacheImage(url);
    _imageProviders[id] = imageProvider;
    return imageProvider;
  }

  static void _clearImages() {
    _imageProviders = {};
    PaintingBinding.instance!.imageCache!.clear();
    PaintingBinding.instance!.imageCache!.clearLiveImages();
    log("[Paulonia Image Service] ------------ Images cleared");
  }

  static bool _imagesExceeded() {
    return _imageProviders.length >= PImageGlobals.pImageInMemoryImages;
  }

  static bool _imagesSizeExceeded() {
    return PaintingBinding.instance!.imageCache!.currentSizeBytes >=
        PImageGlobals.pImageInMemorySize;
  }

  static Map<String, ImageProvider> _imageProviders = {};
}
