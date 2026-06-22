import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stac/stac.dart';

class StacImageParser extends StacParser<StacImage> {
  const StacImageParser();

  @override
  String get type => WidgetType.image.name;

  @override
  StacImage getModel(Map<String, dynamic> json) => StacImage.fromJson(json);

  @override
  Widget parse(BuildContext context, StacImage model) {
    // Empty/blank src (e.g. a data binding that resolved to '' — an absent
    // country flag or cover) must render NOTHING. Otherwise a network image with
    // an empty URL paints a broken/placeholder box (the stray gray-person circle
    // seen in the server-driven profile). Bound images get their resolved URL
    // before parse, so a real avatar/flag still renders.
    if (model.src.trim().isEmpty) return const SizedBox.shrink();
    switch (model.imageType) {
      case StacImageType.network:
        return _networkImage(model, context);
      case StacImageType.file:
        return _fileImage(model, context);
      case StacImageType.asset:
        return _assetImage(model, context);
      default:
        return _networkImage(model, context);
    }
  }

  Widget _networkImage(StacImage model, BuildContext context) {
    if (model.src.contains(".svg")) {
      return SvgPicture.network(
        model.src,
        alignment: model.alignment?.parse ?? Alignment.center,
        colorFilter: model.color != null
            ? ColorFilter.mode(model.color.toColor(context)!, BlendMode.srcIn)
            : null,
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: model.src,
        alignment: model.alignment?.parse ?? Alignment.center,
        color: model.color?.toColor(context),
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorWidget: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    }
  }

  Widget _fileImage(StacImage model, BuildContext context) {
    if (!model.src.contains(".svg")) {
      return Image.file(
        File(model.src),
        alignment: model.alignment?.parse ?? Alignment.center,
        color: model.color?.toColor(context),
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    } else {
      return SvgPicture.file(
        File(model.src),
        alignment: model.alignment?.parse ?? Alignment.center,
        colorFilter: model.color != null
            ? ColorFilter.mode(model.color.toColor(context)!, BlendMode.srcIn)
            : null,
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    }
  }

  Widget _assetImage(StacImage model, BuildContext context) {
    if (!model.src.endsWith(".svg")) {
      return Image.asset(
        model.src,
        alignment: model.alignment?.parse ?? Alignment.center,
        color: model.color?.toColor(context),
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    } else {
      return SvgPicture.asset(
        model.src,
        alignment: model.alignment?.parse ?? Alignment.center,
        colorFilter: model.color != null
            ? ColorFilter.mode(model.color.toColor(context)!, BlendMode.srcIn)
            : null,
        width: model.width,
        height: model.height,
        fit: model.fit?.parse ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      );
    }
  }
}
