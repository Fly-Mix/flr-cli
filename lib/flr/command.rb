require 'yaml'
require 'find'
require 'listen'
require 'flr/version'

# 专有名词解释：
# PS：以下有部分定义（file_dirname、file_basename、file_basename_no_extension、file_extname）参考自 Visual Studio Code
#
# asset：flutter工程的资源，其定义是“packages/#{package_name}/#{asset_name}”，例如“packages/flutter_demo/assets/images/hot_foot_N.png”
# package_name：flutter工程的包名，例如“flutter_demo”
# asset_name：资源名称，其定义是“#{file_dirname}/#{file_basename}”，例如“assets/images/hot_foot_N.png”
# file_dirname：资源的目录路径名称，例如“assets/images”
# file_basename：资源的文件名，其定义是“#{file_basename_no_extension}#{file_extname}”，例如“hot_foot_N.png”
# file_basename_no_extension：资源的不带扩展名的文件名，例如“hot_foot_N”
# file_extname：资源的扩展名，例如“.png”
#
# asset_id：资源ID，其值一般为 file_basename_no_extension

module Flr
  class Command

    # Listen Class Instance
    @@listener = nil

    # show the version of flr
    def self.version
      version_desc = "flr version #{Flr::VERSION}"
      puts(version_desc)
    end

    # create a `Flrfile.yaml` file for the current directory if none currently exists,
    # and automatically specify package `r_dart_library`(https://github.com/YK-Unit/r_dart_library) in `pubspec.yaml`.
    def self.init
      flutter_project_root_dir = "#{Pathname.pwd}"

      flrfile_path = flutter_project_root_dir + "/Flrfile.yaml"
      pubspec_path = flutter_project_root_dir + "/pubspec.yaml"

      # 检测当前目录是否存在 pubspec.yaml；
      # 若不存在，说明当前目录不是一个flutter工程目录，这时直接终止初始化，并打印错误提示；
      unless File.exist?(pubspec_path)
        message = <<-MESSAGE
[x]: #{pubspec_path} not found
[*]: please make sure current directory is a flutter project directory
        MESSAGE
        abort(message)
      end

      puts("init #{flutter_project_root_dir} now...")

      # 若不存在 Flrfile，则创建一个 Flrfile
      if File.exist?(flrfile_path) == false
        flrfile_file = File.open(flrfile_path, "w")

        flrfile_content = <<-CODE
# Flrfile.yaml is used to config the asset directories that needs to be scanned in current flutter project directory.

assets:

  # config the image asset directories that need to be scanned
  # supported image assets: [".png", ".jpg", ".jpeg", ".gif", ".webp", ".icon", ".bmp", ".wbmp", ".svg"]
  # config example: - lib/assets/images
  images:
    #- lib/assets/images

  # config the text asset directories that need to be scanned
  # supported text assets: [".txt", ".json", ".yaml", ".xml"]
  # config example: - lib/assets/texts
  texts:
    #- lib/assets/texts

        CODE

        flrfile_file.puts(flrfile_content)
        flrfile_file.close

        puts("create Flrfile.yaml done !!!")
      end

      # 更新 pubspec.yaml，添加和获取依赖包 `r_dart_library`(https://github.com/YK-Unit/r_dart_library)
      pubspec_file = File.open(pubspec_path, 'r')
      pubspec_yaml = YAML.load(pubspec_file)
      pubspec_file.close
      dependencies = pubspec_yaml["dependencies"]

      r_dart_library = Hash["git" => Hash["url"  => "https://github.com/YK-Unit/r_dart_library.git"]]
      dependencies["r_dart_library"] = r_dart_library

      pubspec_yaml["dependencies"] = dependencies

      pubspec_file = File.open(pubspec_path, 'w')
      pubspec_file.write(pubspec_yaml.to_yaml)
      pubspec_file.close

      puts("add dependency `r_dart_library`(https://github.com/YK-Unit/r_dart_library) into pubspec.yaml done!")

      puts "get dependency `r_dart_library` via execute `flutter pub get` now ..."

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts "get dependency `r_dart_library` done !!!"

      puts("[√]: init done !!!")
    end

    # scan assets,
    # then automatically specify scanned assets in `pubspec.yaml`,
    # and generate `r.g.dart` file.
    def self.generate
      flutter_project_root_dir = "#{Pathname.pwd}"

      # 读取 Flrfile，获取要搜索的资源目录
      flrfile_path = "#{flutter_project_root_dir}/Flrfile.yaml"

      # 检测当前目录是否存在 Flrfile.yaml；
      # 若不存在，说明当前工程目录还没有执行 `Flr init`，这时候直接终止创建，并打印错误提示
      unless File.exist?(flrfile_path)
        message = <<-MESSAGE
[x]: #{flrfile_path} not found
[*]: please run `flr init` to fix it
        MESSAGE
        abort(message)
      end

      flrfile_file = File.open(flrfile_path, "r")
      flrfile_yaml = YAML.load(flrfile_file)
      flrfile_file.close

      image_asset_dir_paths = flrfile_yaml["assets"]["images"]
      text_asset_dir_paths = flrfile_yaml["assets"]["texts"]
      all_asset_dir_paths = []

      if image_asset_dir_paths.is_a?(Array)
        all_asset_dir_paths = all_asset_dir_paths + image_asset_dir_paths
      end

      if text_asset_dir_paths.is_a?(Array)
        all_asset_dir_paths = all_asset_dir_paths + text_asset_dir_paths
      end

      all_asset_dir_paths = all_asset_dir_paths.uniq

      # 需要过滤的资源类型
      # .DS_Store 是 macOS 下文件夹里默认自带的的隐藏文件
      ignored_asset_types = [".DS_Store"]

      # 添加资源声明到 `pubspec.yaml`
      puts("add the asset declarations into `pubspec.yaml` now ...")

      pubspec_path = "#{flutter_project_root_dir}/pubspec.yaml"
      pubspec_file = File.open(pubspec_path, 'r')
      pubspec_yaml = YAML.load(pubspec_file)
      pubspec_file.close

      package_name = pubspec_yaml["name"]
      flutter_assets = []
      all_asset_dir_paths.each do |asset_dir_path|
        specified_assets = FlutterAssetTool.get_assets_in_dir(asset_dir_path, ignored_asset_types, package_name)
        flutter_assets = flutter_assets + specified_assets
      end

      uniq_flutter_assets = flutter_assets.uniq
      pubspec_yaml["flutter"]["assets"] = uniq_flutter_assets

      pubspec_file = File.open(pubspec_path, 'w')
      pubspec_file.write(pubspec_yaml.to_yaml)
      pubspec_file.close

      puts("add the asset declarations into `pubspec.yaml` done !!!")

      # 创建生成 `r.g.dart`

      puts("generate r.g.dart now ...")

      r_dart_path = "#{flutter_project_root_dir}/lib/r.g.dart"
      r_dart_file = File.open(r_dart_path,"w")

      # ----- R Begin -----

      # 生成 `class R` 的代码
      r_code = <<-CODE
// GENERATED CODE - DO NOT MODIFY BY HAND
// Flr CLI: https://github.com/Fly-Mix/flr-cli

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:r_dart_library/asset_svg.dart';

/// This `R` class is generated and contains references to static asset resources.
class R {
  /// package name: #{package_name}
  static const package = "#{package_name}";

  /// This `R.image` struct is generated, and contains static references to static non-svg type image asset resources.
  static const image = _R_Image();

  /// This `R.svg` struct is generated, and contains static references to static svg type image asset resources.
  static const svg = _R_Svg();

  /// This `R.text` struct is generated, and contains static references to static text asset resources.
  static const text = _R_Text();
}

/// Asset resource’s metadata class.
/// For example, here is the metadata of `packages/flutter_demo/assets/images/example.png` asset:
/// - packageName：flutter_demo
/// - assetName：assets/images/example.png
/// - fileDirname：assets/images
/// - fileBasename：example.png
/// - fileBasenameNoExtension：example
/// - fileExtname：.png
class AssetResource {
  /// Creates an object to hold the asset resource’s metadata.
  const AssetResource(this.assetName,
      {this.packageName,
      this.fileDirname,
      this.fileBasename,
      this.fileBasenameNoExtension,
      this.fileExtname})
      : assert(assetName != null);

  /// The name of the main asset from the set of asset resources to choose from.
  final String assetName;

  /// The name of the package from which the asset resource is included.
  final String packageName;

  /// The directory path name of the asset resource.
  final String fileDirname;

  /// The file basename of the asset resource.
  final String fileBasename;

  /// The no extension file basename of the asset resource.
  final String fileBasenameNoExtension;

  /// The file extension name of the asset resource.
  final String fileExtname;

  /// The name used to generate the key to obtain the asset resource. For local assets
  /// this is [assetName], and for assets from packages the [assetName] is
  /// prefixed 'packages/<package_name>/'.
  String get keyName => packageName == null ? assetName : 'packages/$packageName/$assetName';
}
      CODE
      r_dart_file.puts(r_code)

      # ----- R End -----

      supported_asset_images = %w(.png .jpg .jpeg .gif .webp .icon .bmp .wbmp)
      supported_asset_texts = %w(.txt .json .yaml .xml)

      # ----- _R_Image_AssetResource Begin -----

      # 生成 `class _R_Image_AssetResource` 的代码
      r_image_assetResource_code_header = <<-CODE
      
// ignore: camel_case_types
class _R_Image_AssetResource {
  const _R_Image_AssetResource();
      CODE
      r_dart_file.puts(r_image_assetResource_code_header)

      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless supported_asset_images.include?(file_extname)
          next
        end

        r_dart_file.puts("")

        assetResource_code = FlutterAssetTool.generate_assetResource_code(asset, package_name,".png")
        r_dart_file.puts(assetResource_code)

      end

      r_image_assetResource_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_image_assetResource_code_footer)

      # ----- _R_Image_AssetResource End -----


      # ----- _R_Svg_AssetResource Begin -----

      # 生成 `class _R_Svg_AssetResourceg` 的代码
      r_svg_assetResource_code_header = <<-CODE
      
// ignore: camel_case_types
class _R_Svg_AssetResource {
  const _R_Svg_AssetResource();
      CODE
      r_dart_file.puts(r_svg_assetResource_code_header)

      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless file_extname.eql?(".svg")
          next
        end

        r_dart_file.puts("")

        assetResource_code = FlutterAssetTool.generate_assetResource_code(asset, package_name, ".svg")
        r_dart_file.puts(assetResource_code)

      end

      r_svg_assetResource_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_svg_assetResource_code_footer)
      # ----- _R_Svg_AssetResource End -----

      # ----- _R_Text_AssetResource Begin -----

      # 生成 `class _R_Text_AssetResource` 的代码
      r_text_assetResource_code_header = <<-CODE
      
// ignore: camel_case_types
class _R_Text_AssetResource {
  const _R_Text_AssetResource();
      CODE
      r_dart_file.puts(r_text_assetResource_code_header)

      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的文本资源，则跳过
        unless supported_asset_texts.include?(file_extname)
          next
        end

        r_dart_file.puts("")

        assetResource_code = FlutterAssetTool.generate_assetResource_code(asset, package_name)
        r_dart_file.puts(assetResource_code)

      end

      r_text_assetResource_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_text_assetResource_code_footer)

      # ----- _R_Text_AssetResource End -----

      # -----  _R_Image Begin -----

      # 生成 `class _R_Image` 的代码
      r_image_code_header = <<-CODE
      
/// This `_R_Image` class is generated and contains references to static non-svg type image asset resources.
// ignore: camel_case_types
class _R_Image {
  const _R_Image();

  final asset = const _R_Image_AssetResource();
      CODE
      r_dart_file.puts(r_image_code_header)

      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless supported_asset_images.include?(file_extname)
          next
        end

        r_dart_file.puts("")

        asset_id = FlutterAssetTool.generate_asset_id(asset, ".png")
        asset_comment = FlutterAssetTool.generate_asset_comment(asset, package_name)

        assetMethod_code = <<-CODE
  /// #{asset_comment}
  // ignore: non_constant_identifier_names
  AssetImage #{asset_id}() {
    return AssetImage(asset.#{asset_id}.assetName, package: asset.#{asset_id}.packageName);
  }
        CODE

        r_dart_file.puts(assetMethod_code)

      end

      r_image_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_image_code_footer)

      # -----  _R_Image End -----

      # -----  _R_Svg Begin -----

      # 生成 `class _R_Svg` 的代码
      r_svg_code_header = <<-CODE
      
/// This `_R_Svg` class is generated and contains references to static svg type image asset resources.
// ignore: camel_case_types
class _R_Svg {
  const _R_Svg();

  final asset = const _R_Svg_AssetResource();
      CODE
      r_dart_file.puts(r_svg_code_header)


      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless file_extname.eql?(".svg")
          next
        end

        r_dart_file.puts("")

        asset_id = FlutterAssetTool.generate_asset_id(asset, ".svg")
        asset_comment = FlutterAssetTool.generate_asset_comment(asset, package_name)

        assetMethod_code = <<-CODE
  /// #{asset_comment}
  // ignore: non_constant_identifier_names
  AssetSvg #{asset_id}({@required double width, @required double height}) {
    var imageProvider = AssetSvg(asset.#{asset_id}.keyName, width: width, height: height);
    return imageProvider;
  }
        CODE

        r_dart_file.puts(assetMethod_code)

      end

      r_svg_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_svg_code_footer)

      # -----  _R_Svg End -----

      # -----  _R_Text Begin -----


      # 生成 `class _R_Text` 的代码
      r_text_code_header = <<-CODE
      
/// This `_R_Text` class is generated and contains references to static text asset resources.
// ignore: camel_case_types
class _R_Text {
  const _R_Text();

  final asset = const _R_Text_AssetResource();
      CODE
      r_dart_file.puts(r_text_code_header)

      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的文本资源，则跳过
        unless supported_asset_texts.include?(file_extname)
          next
        end

        r_dart_file.puts("")

        asset_id = FlutterAssetTool.generate_asset_id(asset, ".png")
        asset_comment = FlutterAssetTool.generate_asset_comment(asset, package_name)

        assetMethod_code = <<-CODE
  /// #{asset_comment}
  // ignore: non_constant_identifier_names
  Future<String> #{asset_id}() {
    var str = rootBundle.loadString(asset.#{asset_id}.keyName);
    return str;
  }
        CODE

        r_dart_file.puts(assetMethod_code)

      end

      r_text_code_footer = <<-CODE
}
      CODE
      r_dart_file.puts(r_text_code_footer)


      r_dart_file.close
      puts "generate r.g.dart done !!!"

      puts "execute `flutter pub get` now ..."

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts "execute `flutter pub get` done !!!"

      illegal_assets = []
      uniq_flutter_assets.each do |asset|
        file_basename_no_extension = File.basename(asset, ".*")

        if FlutterAssetTool.is_legalize_file_basename(file_basename_no_extension) == false
          illegal_assets << asset
        end

      end

      puts("[√]: generate done !!!")

      if illegal_assets.length > 0
        puts ""
        puts "[!]: warning, find these assets who's asset name contains bad characters: "
        illegal_assets.each do |asset|
          puts "  - #{asset}"
        end
        puts "[*]: to fix it, you should only use letters (a-z,A-Z), numbers (0-9), and the underscore character (_) to name the asset"

      end

    end

    # Launch a monitoring service that continuously monitors asset changes for your project.
    # If there are any changes, it will automatically execute `flr generate`.
    # You can terminate the service by manually pressing `Ctrl-C`.
    def self.start_assert_monitor
      flutter_project_root_dir = "#{Pathname.pwd}"

      # 读取 Flrfile，获取要搜索的资源目录
      flrfile_path = "#{flutter_project_root_dir}/Flrfile.yaml"

      # 检测当前目录是否存在 Flrfile.yaml；
      # 若不存在，说明当前工程目录还没有执行 `Flr init`，这时候直接终止创建，并打印错误提示
      unless File.exist?(flrfile_path)
        message = <<-MESSAGE
[x]: #{flrfile_path} not found
[*]: please run `flr init` to fix it
        MESSAGE
        abort(message)
      end

      puts("execute `fly generate` and launch a monitoring service")
      puts("\n")

      now_str = Time.now.to_s
      puts("-------------------- #{now_str} --------------------")
      puts("execute `fly generate` now ...")
      puts("\n")
      generate
      puts("\n")
      puts("execute `fly generate` done !!!")
      puts("specify assets and generate `r.g.dart` done !!!")
      puts("-------------------------------------------------------------------")
      puts("\n")

      flrfile = File.open(flrfile_path, "r")
      flrfile_yaml = YAML.load(flrfile)
      flrfile.close

      image_asset_dir_paths = flrfile_yaml["assets"]["images"]
      text_asset_dir_paths = flrfile_yaml["assets"]["texts"]
      all_asset_dir_paths = []

      if image_asset_dir_paths.is_a?(Array)
        all_asset_dir_paths = all_asset_dir_paths + image_asset_dir_paths
      end

      if text_asset_dir_paths.is_a?(Array)
        all_asset_dir_paths = all_asset_dir_paths + text_asset_dir_paths
      end

      now_str = Time.now.to_s
      puts("-------------------- #{now_str} --------------------")
      puts("launch a monitoring service now ...")
      puts("launching ...")
      # stop the monitoring service if exists
      stop_assert_monitor
      puts("launch a monitoring service done !!!")
      all_asset_dir_paths = all_asset_dir_paths.uniq
      puts("the monitoring service is monitoring these asset directories:")
      all_asset_dir_paths.each do |dir_path|
        puts("- #{dir_path}")
      end
      puts("-------------------------------------------------------------------")
      puts("\n")

      # Allow array of directories as input #92
      # https://github.com/guard/listen/pull/92
      @@listener = Listen.to(*all_asset_dir_paths, ignore: [/\.DS_Store/], latency: 0.5, wait_for_delay: 5, relative: true) do |modified, added, removed|
        # for example: 2013-03-30 03:13:14 +0900
        now_str = Time.now.to_s
        puts("-------------------- #{now_str} --------------------")
        puts("modified absolute paths: #{modified}")
        puts("added absolute paths: #{added}")
        puts("removed absolute paths: #{removed}")
        puts("execute `fly generate` now ...")
        puts("\n")
        generate
        puts("\n")
        puts("execute `fly generate` done !!!")
        puts("specify assets and generate `r.g.dart` done !!!")
        puts("-------------------------------------------------------------------")
        puts("\n")
        puts("[!]: the monitoring service is monitoring the asset changes, and then auto specifies assets and generates `r.g.dart` ...")
        puts("[*]: you can press `Ctrl-C` to terminate it")
        puts("\n")
      end
      # not blocking
      @@listener.start

      # https://ruby-doc.org/core-2.5.0/Interrupt.html
      begin
        puts("[!]: the monitoring service is monitoring the asset changes, and then auto specifies assets and generates `r.g.dart` ...")
        puts("[*]: you can press `Ctrl-C` to terminate it")
        puts("\n")
        loop {}
      rescue Interrupt => e
        stop_assert_monitor
        puts("")
        puts("[√]: terminate monitor service done !!!")
      end

    end

    # stop assert monitor task
    def self.stop_assert_monitor
      if @@listener.nil? == false
        @@listener.stop
        @@listener = nil
      end
    end

    end

  class FlutterAssetTool

    # 历指定资源文件夹下所有文件（包括子文件夹），返回资源的依赖说明数组，如
    # ["packages/flutter_demo/assets/images/hot_foot_N.png", "packages/flutter_demo/assets/images/hot_foot_S.png"]
    def self.get_assets_in_dir (asset_dir_path, ignored_asset_types, package_name)
      file_dirname = asset_dir_path.split("lib/")[1]
      assets = []
      Find.find(asset_dir_path) do |path|
        if File.file?(path)
          file_basename = File.basename(path)

          if ignored_asset_types.include?(file_basename)
            next
          end

          asset_name = "#{file_dirname}/#{file_basename}"
          asset = "packages/#{package_name}/#{asset_name}"
          assets << asset
        end
      end
      uniq_assets = assets.uniq
      return uniq_assets
    end

    # 判断当前file_basename（无拓展名）是不是合法的文件名
    # 合法的文件名应该由数字、字母、_字符组成
    def self.is_legalize_file_basename (file_basename_no_extension)
      regx = /^[0-9A-Za-z_]+$/

      if file_basename_no_extension =~ regx
        return true
      else
        return false
      end
    end

    # 为当前asset生成合法的asset_id（资产ID）
    def self.generate_asset_id (asset, prior_asset_type=".*")
      file_extname = File.extname(asset).downcase

      file_basename = File.basename(asset)

      file_basename_no_extension = File.basename(asset, ".*")
      asset_id = file_basename_no_extension.dup
      if prior_asset_type.eql?(".*") or file_extname.eql?(prior_asset_type) == false
        ext_info = file_extname
        ext_info[0] = "_"
        asset_id = asset_id + ext_info
      end

      # 过滤非法字符
      asset_id = asset_id.gsub(/[^0-9A-Za-z_$]/, "_")

      # 首字母转化为小写
      capital = asset_id[0].downcase
      asset_id[0] = capital

      # 检测首字符是不是数字、_、$，若是则添加前缀字符"a"
      if capital =~ /[0-9_$]/
        asset_id = "a" + asset_id
      end

      return asset_id
    end

    # 为当前asset生成注释
    def self.generate_asset_comment (asset, package_name)

      asset_digest = asset.dup
      asset_digest["packages/#{package_name}/"] = ""

      asset_comment = "asset: \"#{asset_digest}\""

      return asset_comment
    end


    # 为当前asset生成AssetResource的代码
    def self.generate_assetResource_code (asset, package_name, prior_asset_type=".*")

      asset_id = generate_asset_id(asset, prior_asset_type)
      asset_comment = generate_asset_comment(asset, package_name)

      file_basename = File.basename(asset)

      file_basename_no_extension = File.basename(asset, ".*")

      file_extname = File.extname(asset).downcase

      file_dirname = asset.dup
      file_dirname["packages/#{package_name}/"] = ""
      file_dirname["/#{file_basename}"] = ""

      param_file_basename = file_basename.gsub(/[$]/, "\\$")
      param_file_basename_no_extension = file_basename_no_extension.gsub(/[$]/, "\\$")

      param_asset_name = "#{file_dirname}/#{param_file_basename}"

      assetResource_code = <<-CODE
  /// #{asset_comment}
  // ignore: non_constant_identifier_names
  final #{asset_id} = const AssetResource("#{param_asset_name}",
      packageName: R.package,
      fileDirname: "#{file_dirname}",
      fileBasename: "#{param_file_basename}",
      fileBasenameNoExtension: "#{param_file_basename_no_extension}",
      fileExtname: "#{file_extname}");

      CODE

      return assetResource_code
    end
  end
end