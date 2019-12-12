# Flr

Flr: Flutter-R, a CLI tool like AAPT(Android Asset Packaging Tool) to update pubspec.yaml and generate R.dart when developer update flutter project asserts.

## Installation & Update

To install or update Flr run `sudo gem install flr`

## Usage

1. Create `Flrfile.yaml` in your flutter project directory:
    
    ```
    cd flutter_project_dir
    flr init
    ```
 
2. Edit `Flrfile.yaml` to config the asset directories that needs to be searched in current flutter project directory:

   ```
    assets:
    
      # config the image asset directories that needs to be searched
      # supported image assets: [".png", ".jpg", ".jpeg", ".gif", ".webp", ".icon", ".bmp", ".wbmp", ".svg"]
      # config example: - lib/assets/images
      images:
        - lib/assets/images
    
      # config the text asset directories that needs to be searched
      # supported text assets: [".txt", ".json", ".yaml", ".xml"]
      # config example: - lib/assets/texts
      texts:
        - lib/assets/jsons
        - lib/assets/yamls
    ```
    
3. Generate `R.dart` for your flutter project directory:

     ```
     flr generate
     ```
     
4. After each the assets of your flutter project change, just run `flr generate` again.

## Example

Here is a [demo](https://github.com/YK-Unit/flutter_r_demo) to show how to use flr in flutter project.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
