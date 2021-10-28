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
  /// If [id] is null then used the [gsUrl] as id.
  /// If it's the first call using the id, then it
  /// creates a [PCacheImage] and stores it. Otherwise
  /// returns the already cached [ImageProvider].
  /// The store [ImageProvider] may be removed once a
  /// limit is reached.
  static ImageProvider getImage(String gsUrl, {String? id}) {
    id ??= gsUrl;

    ImageProvider? imageProvider = _imageProviders[id];

    imageProvider ??= _addImageProvider(gsUrl, id);

    return imageProvider;
  }

  /// Manually updates the image provider of [id]
  static void updateImage(String id, ImageProvider image) {
    _imageProviders[id] = image;
  }

  /// Preloads the [gsUrls] images and stores them
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
    log("[Paulonia Image Service] ------------------------ image providers freed");
    log("[Paulonia Image Service] ------------------------ cache cleared");
  }

  static bool _imagesExceeded() {
    final bool exceeded =
        _imageProviders.length >= PImageGlobals.pImageInMemoryImages;
    if (exceeded) {
      log("[Paulonia Image Service] ------------------------ images exceeded");
    }
    return exceeded;
  }

  static bool _imagesSizeExceeded() {
    final bool exceeded =
        PaintingBinding.instance!.imageCache!.currentSizeBytes >=
            PImageGlobals.pImageInMemorySize;
    if (exceeded) {
      log("[Paulonia Image Service] ------------------------ size exceeded");
    }
    return exceeded;
  }

  static Map<String, ImageProvider> _imageProviders = {};
}
