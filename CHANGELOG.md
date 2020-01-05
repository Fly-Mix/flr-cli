## Installation & Update

To install or update Flr run `sudo gem install flr`

## Uninstall

To uninstall  Flr run `sudo gem uninstall flr`

## 0.2.0 - BREAKING CHANGES

- modify the way the Flr configuration is stored: discard the flrfile.yaml file and write the configuration to the pubspec.yaml file
- `flr generate` and `flr monitor` are combined into `flr run [--auto]`
- generate `r.g.dart` instead of `R.dart`
- new `R` class: 
	- discards `R_X` code struct, and uses `R.x` code  struct
	- unifies the access way of all types asset resources: using the asset resource ID function, such as `R.image.test()`, `R.svg.test(width: 100, height: 100)`, `R.text.test_json()`
	- provides `AssetResource` class  to acces the asset metadata, such as `assetName`, `packageName`, `fileBasename`
- increase the range of legal character sets : `0-9`, `A-Z`, `a-z`, `_`, `+`, `-`, `.`, `·`,  `!`,  `@`,  `&`, `$`, `￥`
- colored terminal output 

## 0.1.13

- `flr generate` supports checking and outputtting assets with bad filename
- Fix bug

## 0.1.12

- Support auto service that automatically specify assets in `pubspec.yaml` and generate  `R.dart` file,  which can be triggered manually or by monitoring asset changes
- Support for processing image assets ( `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.icon`, `.bmp`, `.wbmp`, `.svg` ) 
- Support for processing text assets ( `.txt`, `.json`, `.yaml`, `.xml` ) 
- Support for processing [image asset variants](https://flutter.dev/docs/development/ui/assets-and-images#asset-variants)
- Support for processing asset which’s filename is bad:
   - filename has illegal character (such as  `blank`,  `~`, `@`, `#` ) which is outside the range of  valid characters (`0-9`, `A-Z`, `a-z`, `_`,  `$`)
   - filename begins with a number or character `_`  or character`$`