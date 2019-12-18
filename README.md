# Flr

Flr(Flutter-R): a CLI tool likes `AAPT`(Android Asset Packaging Tool), which can help flutter developer to auto specify assets in `pubspec.yaml` and generate `R.dart` file after he changes the flutter project assets. Then flutter developer can apply the asset in code by referencing it's asset ID which defined in `R.dart`.

## Feature
- Support for two way(once way and monitor way) to auto specify assets in `pubspec.yaml` and generate  `R.dart` file
- Support for monitoring the asset changes
- Support for processing image assets( `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.icon`, `.bmp`, `.wbmp`, `.svg` ) 
- Support for processing text assets( `.txt`, `.json`, `.yaml`, `.xml` ) 
- Support for processing [image asset variants](https://flutter.dev/docs/development/ui/assets-and-images#asset-variants)
- Support for processing asset which’s filename is bad:
   - filename has illegal character(such as  `blank`,  `~`, `@`, `#` ) which is outside the range of  valid characters(`0-9`, `A-Z`, `a-z`, `_`,  `$`)
   - filename begins with a number or character `_`  or character`$`

## Installation & Update Flr

To install or update Flr, run `sudo gem install flr`

> If you want to use Flr tool on the Windows system, you are strongly recommended to run it on [WSL(Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) environment !!! 

## Usage

1. Init your flutter project:

    ```
    cd flutter_project_dir
    flr init
    ```
    
    > The `flr init` command generates `Flrfile.yaml` file for project.
    
2. Open `Flrfile.yaml`, and edit it to config the asset directories that need to be scanned in your flutter project directory:

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

3. Specify assets and generate `R.dart` for your flutter project, here provides two way for you:

     - Once Way：

       ```
       flr generate
       ```

       > The `flr generate`  command once specifies assets in `pubspec.yaml` and generates  `R.dart` file for your flutter project.

     - Monitor Way：
       
     	```
     	flr monitor
     	```
     	
     	> The `flr monitor` command runs a monitor service to keep monitoring the asset changes, and then specifies assets in `pubspec.yaml` and generates `R.dart` file for your flutter project, until you manually press Ctrl-C.

4. If you choose the once way to specify assets and generate `R.dart`  , then after each you updates the assets of your flutter project, just run `flr generate` again.

**Attention:**  all commands should be runned in your flutter project root directory.

## R.dart

After you run `flr generate` or `flr monitor`, `flr` will scan the assets based on the configs in `Flrfile.yaml`, and then generates `R.dart` file and generates asset ID codes in `R.dart`.

`R.dart` allows you to  apply the asset in code by referencing it's asset ID. All asset IDs are defined in `R_X` class (such as `R_Image`, `R_Svg`, `R_Text`). Here are some simple examples:

```dart
import 'package:flutter_r_demo/R.dart';

// sameName.png
var normalImageWidget = Image(
  width: 113,
  height: 128,
  image: R_Image.sameName,
);

// sameName.gif
var gifImageWidget = Image(
  image: R_Image.sameName_gif,
);

// $$test$.svg
var svgImageWidget = Image(
  width: 100,
  height: 100,
  image: R_Svg.a$$test$(width: 100, height: 100),
);

// $%^&test.json
var jsonString = await R_Text.a$___test_json();

// ~!@*test.yaml
var yamlString = await R_Text.a____test_yaml();

```

## Example

Here is a [Flutter-R Demo](https://github.com/YK-Unit/flutter_r_demo) to show how to use `flr` tool in flutter project and show how to use `R.dart` in your code.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
