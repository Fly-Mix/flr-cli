# Flr

Flr(Flutter-R): a CLI tool likes `AAPT`(Android Asset Packaging Tool), which can help flutter developer to auto specify assets in `pubspec.yaml` and generate  `R.dart` file after he updates the flutter project assets. Then flutter developer can apply the asset in code by referencing it's asset ID which defined in `R.dart`.

## Feature
- auto specify assets in `pubspec.yaml` and generate  `R.dart` file after scanned assets
- support for processing image assets( `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.icon`, `.bmp`, `.wbmp`, `.svg` ) 
- support for processing text assets( `.txt`, `.json`, `.yaml`, `.xml` ) 
- support for processing [image asset variants](https://flutter.dev/docs/development/ui/assets-and-images#asset-variants)
- support for processing asset which’s filename has illegal character(such as  `blank`,  `~`, `@`, `#` ) which is outside the range of  valid characters(`0-9`, `A-Z`, `a-z`, `_`,  `$`)
- support for processing asset which’s filename begins with a number or character `_`  or character`$`

## Installation & Update Flr

To install or update Flr, run `sudo gem install flr`

> If you want to use Flr tool on the Windows system, you are strongly recommended to run it on [WSL(Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) environment !!! 

## Usage

1. Run `flr init`  in your flutter project directory to generate `Flrfile.yaml` file for current flutter project:

    ```
    cd flutter_project_dir
    flr init
    ```
    
2. Open `Flrfile.yaml`, and and edit it to config the asset directories that needs to be scanned in current flutter project directory:

   ```
    assets:
    
      # config the image asset directories that need to be scanned
      # supported image assets: [".png", ".jpg", ".jpeg", ".gif", ".webp", ".icon", ".bmp", ".wbmp", ".svg"]
      # config example: - lib/assets/images
      images:
        - lib/assets/images
    
      # config the text asset directories that need to be scanned
      # supported text assets: [".txt", ".json", ".yaml", ".xml"]
      # config example: - lib/assets/texts
      texts:
        - lib/assets/jsons
        - lib/assets/yamls
   ```
4. Run `flr generate` to generate `R.dart` file for curent flutter project:

     ```
     flr generate
     ```

5. After each you updates the assets of current flutter project, just run `flr generate` again.

## R.dart

After you run `flr generate`, `flr` will scan the assets based on the configs in `Flrfile.yaml`, and then generates `R.dart` file and generate asset ID codes in `R.dart`.

`R.dart` allows you to  apply the asset in code by referencing it's asset ID. All asset IDs are defined in `R_X` class (such as `R_Image`, `R_Svg`, `R_Text`). Here are some simple examples:

```dart
import 'package:flutter_r_demo/R.dart';

var normalImageWidget = Image(
  width: 113,
  height: 128,
  image: R_Image.sameName,
);

var gifImageWidget = Image(
  image: R_Image.sameName_gif,
);

var svgImageWidget = Image(
  width: 100,
  height: 100,
  image: R_Svg.a$$test$(width: 100, height: 100),
);

var jsonString = await R_Text.a$$test$_json();

var yamlString = await R_Text.a$$test$_yaml();

```

## Example

Here is a [Flutter-R Demo](https://github.com/YK-Unit/flutter_r_demo) to show how to use `flr` tool in flutter project and show how to use `R.dart` in your code.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
