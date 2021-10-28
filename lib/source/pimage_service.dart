import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';
import 'package:paulonia_image_service/source/contants.dart';
import 'package:paulonia_image_service/source/globals.dart';

/// Image provider service for [PImage]
class PImageService {
  static bool isLoaded(String gsUrl) {
    PImageInfo? imageInfo;
    if (imageInfo == null) return false;
    return imageInfo.isLoaded;
  }

  /// Sets the configuration for the PImageService
  static void settings({
    int? maxCacheSize,
    int? maxImages,
    ImageProvider? defaultPlaceholder,
  }) {
    if (maxImages != null) {
      PImageGlobals.pImageInMemoryImages = maxImages;
    }

    if (maxCacheSize != null) {
      PImageGlobals.pImageInMemorySize = maxCacheSize;
    }

    if (defaultPlaceholder != null) {
      _defaultPlaceholder = defaultPlaceholder;
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

    PImageInfo? imageInfo = _imageProviders[id];
    imageInfo ??= _addImageProvider(gsUrl, id);

    return imageInfo.image;
  }

  static ImageProvider getPlaceholder(String? assetName) {
    if (assetName == null) {
      return _defaultPlaceholder;
    }

    ImageProvider? imageProvider = _placeholders[assetName];
    imageProvider ??= _addPlaceholder(assetName);

    return imageProvider;
  }

  /// Manually updates the image provider of [id]
  static void updateImage(String id, ImageProvider image) {
    PImageInfo? info = _imageProviders[id];
    if (info == null) return;
    info.image = image;
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

  static PImageInfo _addImageProvider(String url, String id) {
    if (_imagesExceeded() || _imagesSizeExceeded()) {
      _clearImages();
    }
    PImageInfo imageInfo = PImageInfo(image: PCacheImage(url));
    _imageProviders[id] = imageInfo;

    imageInfo.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, call) {
          imageInfo.isLoaded = true;
        },
      ),
    );
    return imageInfo;
  }

  static ImageProvider _addPlaceholder(String assetName) {
    ImageProvider image = AssetImage(assetName);
    _placeholders[assetName] = image;
    return image;
  }

  static void _clearImages() {
    _imageProviders = HashMap<String, PImageInfo>();
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

  static ImageProvider _defaultPlaceholder =
      AssetImage(PImageConstants.defaultPlaceholder);
  static HashMap<String, PImageInfo> _imageProviders =
      HashMap<String, PImageInfo>();
  static final  HashMap<String, ImageProvider> _placeholders =
      HashMap<String, ImageProvider>();
}

class PImageInfo {
  PImageInfo({required this.image, this.isLoaded = false});
  ImageProvider image;
  bool isLoaded;
}
