import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/media/image_type.dart';

/// Pure-Dart tests for ImageTypeResolver.resolve — the extension/path/url based
/// image type detection. Covers every branch: svg, svga, the standard-extension
/// set, http vs asset paths, query strings, missing/dangling extensions, and the
/// guards (slash-in-ext, overly-long suffix).
void main() {
  group('ImageType enum', () {
    test('has the expected members', () {
      expect(ImageType.values, <ImageType>[
        ImageType.standard,
        ImageType.svg,
        ImageType.svga,
        ImageType.unknown,
      ]);
    });
  });

  group('ImageTypeResolver.resolve — svg', () {
    test('asset .svg', () {
      expect(ImageTypeResolver.resolve('assets/icons/logo.svg'), ImageType.svg);
    });

    test('http .svg', () {
      expect(ImageTypeResolver.resolve('https://cdn.example.com/a/logo.svg'),
          ImageType.svg);
    });

    test('uppercase extension is normalised', () {
      expect(ImageTypeResolver.resolve('logo.SVG'), ImageType.svg);
      expect(ImageTypeResolver.resolve('logo.Svg'), ImageType.svg);
    });
  });

  group('ImageTypeResolver.resolve — svga', () {
    test('asset .svga', () {
      expect(ImageTypeResolver.resolve('assets/gifts/box.svga'), ImageType.svga);
    });

    test('http .svga with query string', () {
      expect(
        ImageTypeResolver.resolve('https://cdn.example.com/box.svga?v=3&t=x'),
        ImageType.svga,
      );
    });
  });

  group('ImageTypeResolver.resolve — standard raster types', () {
    const standards = {
      'png': 'a.png',
      'jpg': 'a.jpg',
      'jpeg': 'a.jpeg',
      'webp': 'a.webp',
      'gif': 'a.gif',
      'bmp': 'a.bmp',
      'tiff': 'a.tiff',
      'ico': 'a.ico',
    };

    standards.forEach((ext, source) {
      test('$ext -> standard', () {
        expect(ImageTypeResolver.resolve(source), ImageType.standard);
      });
    });

    test('uppercase JPG -> standard', () {
      expect(ImageTypeResolver.resolve('PHOTO.JPG'), ImageType.standard);
    });

    test('http url with standard ext + query', () {
      expect(
        ImageTypeResolver.resolve('https://s3.test/u/42/avatar.png?w=200'),
        ImageType.standard,
      );
    });
  });

  group('ImageTypeResolver.resolve — unknown / non-image', () {
    test('mp4 video is unknown (not in the supported set)', () {
      // The resolver only knows svg/svga + raster; .mp4 falls through.
      expect(ImageTypeResolver.resolve('clip.mp4'), ImageType.unknown);
    });

    test('unknown extension', () {
      expect(ImageTypeResolver.resolve('file.xyz'), ImageType.unknown);
    });

    test('empty string', () {
      expect(ImageTypeResolver.resolve(''), ImageType.unknown);
    });

    test('no extension at all', () {
      expect(ImageTypeResolver.resolve('justaname'), ImageType.unknown);
    });

    test('trailing dot (dangling extension)', () {
      expect(ImageTypeResolver.resolve('image.'), ImageType.unknown);
    });

    test('hidden dotfile with no real ext is unknown', () {
      // 'gitignore' is not a known image extension.
      expect(ImageTypeResolver.resolve('.gitignore'), ImageType.unknown);
    });
  });

  group('ImageTypeResolver.resolve — guard branches', () {
    test('extension longer than 10 chars is rejected -> unknown', () {
      expect(ImageTypeResolver.resolve('file.superlongextension'),
          ImageType.unknown);
    });

    test('dot in directory but file has no extension -> unknown', () {
      // lastDot is in the directory segment; substring after it contains a '/'
      // so the slash-guard returns null -> unknown.
      expect(ImageTypeResolver.resolve('v1.2/assets/file'), ImageType.unknown);
    });

    test('url whose last dot is a directory + extensionless file -> unknown', () {
      expect(
        ImageTypeResolver.resolve('https://example.com/v1.2/avatar'),
        ImageType.unknown,
      );
    });

    test('http url path takes precedence over host dots', () {
      // host "cdn.example.com" has dots, but uri.path is used for the ext.
      expect(
        ImageTypeResolver.resolve('https://cdn.example.com/folder/pic.png'),
        ImageType.standard,
      );
    });

    test('multiple dots — last one wins', () {
      expect(ImageTypeResolver.resolve('archive.tar.gz'), ImageType.unknown);
      expect(ImageTypeResolver.resolve('my.photo.final.png'), ImageType.standard);
    });
  });
}
