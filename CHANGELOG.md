## Installation & Update

To install or update Flr run `sudo gem install flr`

## Uninstall

To uninstall  Flr run `sudo gem uninstall flr`

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