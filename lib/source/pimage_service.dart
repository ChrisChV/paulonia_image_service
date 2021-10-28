import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';

class PImageService {
  static bool isLoaded(String gsUrl) {
    ImageProvider? imageProvider = _imageProviders[gsUrl];
    return imageProvider != null;
  }

  /// Gets the [ImageProvider] of the provided gsUrl
  ///
  /// If it's the first call using the [gsUrl], then it
  /// creates a [PCacheImage] and stores it. Otherwise
  /// returns the already cached [ImageProvider].
  /// The store [ImageProvider] may be removed once a
  /// limit is reached.
  static ImageProvider getImage(String gsUrl) {
    ImageProvider? imageProvider = _imageProviders[gsUrl];

    if (imageProvider == null) {
      imageProvider = _addImageProvider(gsUrl);
    }

    return imageProvider;
  }

  static void preloadImages(
    List<String> gsUrls,
    BuildContext context, {
    Function? onFinish,
  }) {
    int counter = 0;
    gsUrls.forEach((gsUrl) {
      precacheImage(PCacheImage(gsUrl), context).then((value) {
        getImage(gsUrl);
        counter++;
        if (counter == gsUrls.length && onFinish != null) {
          onFinish();
        }
      });
    });
  }

  static ImageProvider _addImageProvider(String gsUrl) {
    if (_imageProviders.length >= _maxCachedProviders) {
      _clearImages();
      _imageProviders = {};
    }
    ImageProvider imageProvider = PCacheImage(gsUrl);
    _imageProviders[gsUrl] = imageProvider;
    return imageProvider;
  }

  static void _clearImages() {
    _imageProviders = {};
    PaintingBinding.instance!.imageCache!.clear();
    PaintingBinding.instance!.imageCache!.clearLiveImages();
    log("[FeedUiController] Images cleared");
  }

  static Map<String, ImageProvider> _imageProviders = {};
  static int _maxCachedProviders = 50;

  // TODO remove image providers in order of usage
  // List<String> _gsUrlsOrder = [];
}
