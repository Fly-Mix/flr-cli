require 'yaml'
require 'find'
require 'listen'
require 'flr/version'

module Flr
  class Command

    # Listen Class Instance
    @@listener = nil

    # show the version of flr
    def self.version()
      version_desc = "flr version #{Flr::VERSION}"
      puts(version_desc)
    end

    # create a `Flrfile.yaml` file for the current directory if none currently exists,
    # and auto specify package `r_dart_library`(https://github.com/YK-Unit/r_dart_library) in `pubspec.yaml`.
    def self.init()
      flutter_project_root_dir = "#{Pathname.pwd}"

      flrfile_path = flutter_project_root_dir + "/Flrfile.yaml"
      pubspec_path = flutter_project_root_dir + "/pubspec.yaml"

      # 检测当前目录是否存在 pubspec.yaml；
      # 若不存在，说明当前目录不是一个flutter工程目录，这时直接终止初始化，并打印错误提示；
      unless File.exist?(pubspec_path)
        message = <<-HEREDO
[x]: #{pubspec_path} not found
[*]: please make sure current directory is a flutter project directory
        HEREDO
        abort(message)
      end

      puts("init #{flutter_project_root_dir} now...")

      # 若不存在 Flrfile，则创建一个 Flrfile
      if File.exist?(flrfile_path) == false
        flrfile_file = File.open(flrfile_path, "w")

        flrfile_content = <<-HEREDO
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

        HEREDO

        flrfile_file.puts(flrfile_content)
        flrfile_file.close

        puts("create Flrfile.yaml done !!!")
      end

      # 更新 pubspec.yaml，添加和获取依赖包 `r_dart_library`(https://github.com/YK-Unit/r_dart_library)
      pubspec_file = File.open(pubspec_path, 'r')
      pubspec_yaml = YAML.load(pubspec_file)
      pubspec_file.close
      dependencies = pubspec_yaml["dependencies"]

      r_dart_library = Hash["git" => Hash["url"  => "git@github.com:YK-Unit/r_dart_library.git"]]
      dependencies["r_dart_library"] = r_dart_library

      pubspec_yaml["dependencies"] = dependencies

      pubspec_file = File.open(pubspec_path, 'w')
      pubspec_file.write(pubspec_yaml.to_yaml)
      pubspec_file.close

      puts("add dependency `r_dart_library`(https://github.com/YK-Unit/r_dart_library) into pubspec.yaml done!")

      puts "get dependency `r_dart_library` via run `flutter pub get` now ..."

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts "get dependency `r_dart_library` done !!!"

      puts("[√]: init done !!!")
    end

    # scan the assets based on the configs in `Flrfile.yaml`,
    # and then auto specify assets in `pubspec.yaml`,
    # and generate `R.dart` file,
    # and generate asset ID codes in `R.dart`.
    def self.generate()
      flutter_project_root_dir = "#{Pathname.pwd}"

      # 读取 Flrfile，获取要搜索的资源目录
      flrfile_path = "#{flutter_project_root_dir}/Flrfile.yaml"

      # 检测当前目录是否存在 Flrfile.yaml；
      # 若不存在，说明当前工程目录还没有执行 `Flr init`，这时候直接终止创建，并打印错误提示
      unless File.exist?(flrfile_path)
        message = <<-HEREDO
[x]: #{flrfile_path} not found
[*]: please run `flr init` to fix it
        HEREDO
        abort(message)
      end

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

      all_asset_dir_paths = all_asset_dir_paths.uniq

      # 需要过滤的资源
      # .DS_Store 是 macOS 下文件夹里默认自带的的隐藏文件
      ignored_asset_basenames = [".DS_Store"]

      # 添加资源声明到 `pubspec.yaml`
      puts("add the asset declarations into `pubspec.yaml` now ...")

      pubspec_path = "#{flutter_project_root_dir}/pubspec.yaml"
      pubspec_file = File.open(pubspec_path, 'r')
      pubspec_yaml = YAML.load(pubspec_file)
      pubspec_file.close

      package_name = pubspec_yaml["name"]
      flutter_assets = []
      all_asset_dir_paths.each do |asset_dir_path|
        specified_assets = FlutterAssetTool.get_assets_in_dir(asset_dir_path, ignored_asset_basenames, package_name)
        flutter_assets = flutter_assets + specified_assets
      end

      uniq_flutter_assets = flutter_assets.uniq
      pubspec_yaml["flutter"]["assets"] = uniq_flutter_assets

      pubspec_file = File.open(pubspec_path, 'w')
      pubspec_file.write(pubspec_yaml.to_yaml)
      pubspec_file.close

      puts("add the asset declarations into `pubspec.yaml` done !!!")

      # 创建生成 `R.dart`

      puts("generate R.dart now ...")

      r_dart_path = "#{flutter_project_root_dir}/lib/R.dart"
      r_dart_file = File.open(r_dart_path,"w")

      # 生成 `class R` 的代码
      r_declaration = <<-HEREDOC
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:r_dart_library/asset_svg.dart';

/// This `R` class is generated and contains references to static resources.
class R {
  /// package name: #{package_name}
  static const package = "#{package_name}";
}

      HEREDOC
      r_dart_file.puts(r_declaration)

      # 生成 `class R_Image` 的代码
      r_image_declaration_header = <<-HEREDOC
/// Because dart does not support nested class, so use class `R_Image` to replace nested class `R.Image`
// ignore: camel_case_types
class R_Image {

      HEREDOC
      r_dart_file.puts(r_image_declaration_header)


      supported_asset_images = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".icon", ".bmp", ".wbmp"]
      # 根据遍历得到的静态资源数组，生成对应变量声明，写入到 `R.dart` 中
      uniq_flutter_assets.each do |asset|
        # asset example: packages/flutter_demo/assets/images/hot_foot_N.png
        # file_basename example: hot_foot_N.png
        # asset_basename example: hot_foot_N
        # asset_dir_name example: assets/images

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless supported_asset_images.include?(file_extname)
          next
        end

        file_basename = File.basename(asset)

        asset_basename = File.basename(asset, ".*")
        if file_extname.eql?(".png") == false
          extinfo = file_extname
          extinfo[0] = "_"
          asset_basename = asset_basename + extinfo
        end
        asset_basename = FlutterAssetTool.get_legalize_asset_basename(asset_basename)


        asset_dir_name = asset.dup
        asset_dir_name["packages/#{package_name}/"] = ""
        asset_dir_name["/#{file_basename}"] = ""

        param_file_basename = file_basename.gsub(/[$]/, "\\$")
        param_assetName = "#{asset_dir_name}/#{param_file_basename}"

        asset_declaration = <<-HEREDOC
  /// asset: "#{asset_dir_name}/#{file_basename}"
  // ignore: non_constant_identifier_names
  static const #{asset_basename} = AssetImage("#{param_assetName}", package: R.package);

        HEREDOC

        r_dart_file.puts(asset_declaration)

      end

      r_image_declaration_footer = <<-HEREDOC
}

      HEREDOC
      r_dart_file.puts(r_image_declaration_footer)


      # 生成 `class R_Svg` 的代码
      r_svg_declaration_header = <<-HEREDOC
/// Because dart does not support nested class, so use class `R_Svg` to replace nested class `R.Svg`
// ignore: camel_case_types
class R_Svg {

      HEREDOC
      r_dart_file.puts(r_svg_declaration_header)

      # 根据遍历得到的静态资源数组，生成对应变量声明，写入到“R.dart”中
      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的图片资源，则跳过
        unless file_extname.eql?(".svg")
          next
        end

        file_basename = File.basename(asset)

        asset_basename = File.basename(asset, ".*")
        asset_basename = FlutterAssetTool.get_legalize_asset_basename(asset_basename)

        asset_dir_name = asset.dup
        asset_dir_name["packages/#{package_name}/"] = ""
        asset_dir_name["/#{file_basename}"] = ""

        param_asset = asset.dup
        param_asset = param_asset.gsub(/[$]/, "\\$")

        asset_declaration = <<-HEREDOC
  /// asset: #{asset_dir_name}/#{file_basename}
  // ignore: non_constant_identifier_names
  static AssetSvg #{asset_basename}({@required double width, @required double height}) {
    var assetFullPath = "#{param_asset}";
    var imageProvider = AssetSvg(assetFullPath, width: width, height: height);
    return imageProvider;
  }

        HEREDOC

        r_dart_file.puts(asset_declaration)

      end

      r_svg_declaration_footer = <<-HEREDOC
}
      HEREDOC
      r_dart_file.puts(r_svg_declaration_footer)

      # 生成 `class R_Text` 的代码
      r_text_declaration_header = <<-HEREDOC
/// Because dart does not support nested class, so use class `R_Json` to replace nested class `R.Json`
// ignore: camel_case_types
class R_Text {

      HEREDOC
      r_dart_file.puts(r_text_declaration_header)

      supported_asset_txts = [".txt", ".json", ".yaml", ".xml"]
      # 根据遍历得到的静态资源数组，生成对应变量声明，写入到“R.dart”中
      uniq_flutter_assets.each do |asset|

        file_extname = File.extname(asset).downcase

        # 如果当前不是支持的文本资源，则跳过
        unless supported_asset_txts.include?(file_extname)
          next
        end

        file_basename = File.basename(asset)

        asset_basename = File.basename(asset, ".*")
        extinfo = file_extname
        extinfo[0] = "_"
        asset_basename = asset_basename + extinfo
        asset_basename = FlutterAssetTool.get_legalize_asset_basename(asset_basename)

        asset_dir_name = asset.dup
        asset_dir_name["packages/#{package_name}/"] = ""
        asset_dir_name["/#{file_basename}"] = ""

        param_asset = asset.dup
        param_asset = param_asset.gsub(/[$]/, "\\$")

        asset_declaration = <<-HEREDOC
  /// asset: #{asset_dir_name}/#{file_basename}
  // ignore: non_constant_identifier_names
  static Future<String> #{asset_basename}() {
    var assetFullPath = "#{param_asset}";
    var str = rootBundle.loadString(assetFullPath);
    return str;
  }

        HEREDOC

        r_dart_file.puts(asset_declaration)

      end

      r_text_declaration_footer = <<-HEREDOC
}

      HEREDOC
      r_dart_file.puts(r_text_declaration_footer)


      r_dart_file.close
      puts "generate R.dart done !!!"

      puts "run `flutter pub get` now ..."

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts "run `flutter pub get` done !!!"

      puts("[√]: generate done !!!")
    end

    # run a monitor service to keep monitoring the asset changes,
    # and then auto specify assets in `pubspec.yaml`,
    # and generate `R.dart` file,
    # until you manually press Ctrl-C to stop it.
    def self.start_assert_monitor()
      flutter_project_root_dir = "#{Pathname.pwd}"

      # 读取 Flrfile，获取要搜索的资源目录
      flrfile_path = "#{flutter_project_root_dir}/Flrfile.yaml"

      # 检测当前目录是否存在 Flrfile.yaml；
      # 若不存在，说明当前工程目录还没有执行 `Flr init`，这时候直接终止创建，并打印错误提示
      unless File.exist?(flrfile_path)
        message = <<-HEREDO
[x]: #{flrfile_path} not found
[*]: please run `flr init` to fix it
        HEREDO
        abort(message)
      end

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

      all_asset_dir_paths = all_asset_dir_paths.uniq
      puts("start monitoring these asset directories:")
      all_asset_dir_paths.each do |dir_path|
        puts("- #{dir_path}")
      end
      puts("\n")

      stop_assert_monitor

      # Allow array of directories as input #92
      # https://github.com/guard/listen/pull/92
      @@listener = Listen.to(*all_asset_dir_paths, ignore: [/\.DS_Store/], latency: 0.5, wait_for_delay: 5, relative: true) do |modified, added, removed|
        # for example: 2013-03-30 03:13:14 +0900
        now_str = Time.now.to_s
        puts("-------------------- #{now_str} --------------------")
        puts("modified absolute paths: #{modified}")
        puts("added absolute paths: #{added}")
        puts("removed absolute paths: #{removed}")
        puts("\n")
        puts("specify assets and generate `R.dart` now ...")
        generate
        puts("specify assets and generate `R.dart` done !!!")
        puts("\n")
        puts("[!]: the monitor service is runing: it's keeping monitoring the asset changes, and then auto specify assets and generate `R.dart` ...")
        puts("[*]: you can press Ctrl-C to stop it")
        puts("\n")
      end
      # not blocking
      @@listener.start

      # https://ruby-doc.org/core-2.5.0/Interrupt.html
      begin
        puts("[!]: the monitor service is runing: it's keeping monitoring the asset changes, and then auto specify assets and generate `R.dart` ...")
        puts("[*]: you can press Ctrl-C to stop it")
        puts("\n")
        loop {}
      rescue Interrupt => e
        stop_assert_monitor
        puts("")
        puts("[√]: stop monitor service done !!!")
      end

    end

    # stop assert monitor task
    def self.stop_assert_monitor()
      if @@listener.nil? == false
        @@listener.stop
        @@listener = nil
      end
    end

    end

  class FlutterAssetTool
    # 历指定资源文件夹下所有文件（包括子文件夹），返回资源的依赖说明数组，如
    # ["packages/flutter_demo/assets/images/hot_foot_N.png", "packages/flutter_demo/assets/images/hot_foot_S.png"]
    def self.get_assets_in_dir (asset_dir_path, ignored_asset_basenames, package_name)
      asset_dir_name = asset_dir_path.split("lib/")[1]
      assets = []
      Find.find(asset_dir_path) do |path|
        if File.file?(path)
          file_basename = File.basename(path)

          if ignored_asset_basenames.include?(file_basename)
            next
          end

          asset = "packages/#{package_name}/#{asset_dir_name}/#{file_basename}"
          assets << asset
        end
      end
      uniq_assets = assets.uniq
      return uniq_assets
    end

    # 专有名词解释：
    # asset example: packages/flutter_demo/assets/images/hot_foot_N.png
    # file_basename example: hot_foot_N.png
    # asset_basename example: hot_foot_N
    # file_extname example: .png
    # asset_dir_name example: assets/images
    #
    # 生成合法的asset_basename
    def self.get_legalize_asset_basename (illegal_asset_basename)
      # 过滤非法字符
      asset_basename = illegal_asset_basename.gsub(/[^0-9A-Za-z_$]/, "_")

      # 首字母转化为小写
      capital = asset_basename[0].downcase
      asset_basename[0] = capital

      # 检测首字符是不是数字、_、$，若是则添加前缀字符"a"
      if capital =~ /[0-9_$]/
        asset_basename = "a" + asset_basename
      end

      return asset_basename
    end
  end
end