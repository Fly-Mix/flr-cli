require 'yaml'
require 'find'
require 'flr/version'

module Flr
  class Command

    # Shwo version of flr
    def self.version()
      version_desc = "flr version #{Flr::VERSION}"
      puts(version_desc)
    end

    # Create a `Flrfile` for the current directory if none currently exists,
    #       and add the dependency declaration of `r_dart_library`(https://github.com/YK-Unit/r_dart_library)  into `pubspec.yaml`.
    #
    def self.init()
      flutter_project_root_dir = "#{Pathname.pwd}"

      puts("init #{flutter_project_root_dir} now...")

      flrfile_path = flutter_project_root_dir + "/Flrfile"
      pubspec_path = flutter_project_root_dir + "/pubspec.yaml"

      # 检测当前目录是否存在 pubspec.yaml；若不存在，说明不是一个flutter工程，然后直接终止初始化
      unless File.exist?(pubspec_path)
        #abort("[✕]: #{pubspec_path} not found")
      end

      # 若不存在 Flrfile，则创建一个 Flrfile
      if File.exist?(flrfile_path) == false
        flrfile = File.open(flrfile_path, "w")

        flrfile_content = <<-HEREDO
# Flrfile is a YAML file, 
#   and is used to config the asset directories that needs to be searched.

assets:

  # config the image asset directories that needs to be searched
  # supported image assets: [".png", ".jpg", ".jpeg", ".gif", ".webp", ".icon", ".bmp", ".wbmp", ".svg"]
  # config example: - lib/assets/images
  images:
    #- lib/assets/images

  # config the text asset directories that needs to be searched
  # supported text assets: [".txt", ".json", ".yaml", ".xml"]
  # config example: - lib/assets/texts
  texts:
    #- lib/assets/texts

        HEREDO

        flrfile.puts(flrfile_content)
        flrfile.close

        puts("create Flrfile done !!!")
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

    # Search the asserts based on the assert directory settings in `Flrfile`,
    #       and then add the assert declarations into `pubspec.yaml`,
    #       and then generate `R.dart`.
    #
    def self.generate()
      flutter_project_root_dir = "#{Pathname.pwd}"

      # 读取 Flrfile，获取要搜索的资源目录
      flrfile_path = "#{flutter_project_root_dir}/Flrfile"
      flrfile = File.open(flrfile_path, "r")
      flrfile_yaml = YAML.load(flrfile)
      flrfile.close

      image_assert_dir_paths = flrfile_yaml["assets"]["images"]
      text_assert_dir_paths = flrfile_yaml["assets"]["texts"]
      all_assert_dir_paths = []

      if image_assert_dir_paths.is_a?(Array)
        all_assert_dir_paths = all_assert_dir_paths + image_assert_dir_paths
      end

      if text_assert_dir_paths.is_a?(Array)
        all_assert_dir_paths = all_assert_dir_paths + text_assert_dir_paths
      end

      all_assert_dir_paths = all_assert_dir_paths.uniq

      # 需要过滤的资源
      # .DS_Store 是 macOS 下文件夹里默认自带的的隐藏文件
      ignored_asset_basenames = [".DS_Store"]

      # 添加资源声明到 `pubspec.yaml`
      puts("add the assert declarations into `pubspec.yaml` now ...")

      pubspec_path = "#{flutter_project_root_dir}/pubspec.yaml"
      pubspec_file = File.open(pubspec_path, 'r')
      pubspec_yaml = YAML.load(pubspec_file)
      pubspec_file.close

      package_name = pubspec_yaml["name"]
      flutter_assets = []
      all_assert_dir_paths.each do |assert_dir_path|
        specified_assets = FlutterAssertTool.get_asserts_in_dir(assert_dir_path, ignored_asset_basenames, package_name)
        flutter_assets = flutter_assets + specified_assets
      end

      uniq_flutter_assets = flutter_assets.uniq
      pubspec_yaml["flutter"]["assets"] = uniq_flutter_assets

      pubspec_file = File.open(pubspec_path, 'w')
      pubspec_file.write(pubspec_yaml.to_yaml)
      pubspec_file.close

      puts("add the assert declarations into `pubspec.yaml` done !!!")

      # 创建生成 `R.dart`

      puts("generate R.dart now ...")

      r_dart_path = "#{flutter_project_root_dir}/lib/R.dart"
      r_dart_file = File.open(r_dart_path,"w")

      # 生成 `class R` 的代码
      r_declaration = <<-HEREDOC
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:r_dart_library/assert_svg.dart';

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
        # assert_dir_name example: assets/images

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
        asset_basename = FlutterAssertTool.get_legalize_asset_basename(asset_basename)


        assert_dir_name = asset.dup
        assert_dir_name["packages/#{package_name}/"] = ""
        assert_dir_name["/#{file_basename}"] = ""

        param_file_basename = file_basename.gsub(/[$]/, "\\$")
        param_assetName = "#{assert_dir_name}/#{param_file_basename}"

        assert_declaration = <<-HEREDOC
  /// assert: "#{assert_dir_name}/#{file_basename}"
  // ignore: non_constant_identifier_names
  static const #{asset_basename} = AssetImage("#{param_assetName}", package: R.package);

        HEREDOC

        r_dart_file.puts(assert_declaration)

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
        asset_basename = FlutterAssertTool.get_legalize_asset_basename(asset_basename)

        assert_dir_name = asset.dup
        assert_dir_name["packages/#{package_name}/"] = ""
        assert_dir_name["/#{file_basename}"] = ""

        param_asset = asset.dup
        param_asset = param_asset.gsub(/[$]/, "\\$")

        assert_declaration = <<-HEREDOC
  /// assert: #{assert_dir_name}/#{file_basename}
  // ignore: non_constant_identifier_names
  static AssertSvg #{asset_basename}({@required double width, @required double height}) {
    var assertFullPath = "#{param_asset}";
    var imageProvider = AssertSvg(assertFullPath, width: width, height: height);
    return imageProvider;
  }

        HEREDOC

        r_dart_file.puts(assert_declaration)

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
        asset_basename = FlutterAssertTool.get_legalize_asset_basename(asset_basename)

        assert_dir_name = asset.dup
        assert_dir_name["packages/#{package_name}/"] = ""
        assert_dir_name["/#{file_basename}"] = ""

        param_asset = asset.dup
        param_asset = param_asset.gsub(/[$]/, "\\$")

        assert_declaration = <<-HEREDOC
  /// assert: #{assert_dir_name}/#{file_basename}
  // ignore: non_constant_identifier_names
  static Future<String> #{asset_basename}() {
    var assertFullPath = "#{param_asset}";
    var str = rootBundle.loadString(assertFullPath);
    return str;
  }

        HEREDOC

        r_dart_file.puts(assert_declaration)

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


  end

  class FlutterAssertTool
    # 历指定资源文件夹下所有文件（包括子文件夹），返回资源的依赖说明数组，如
    # ["packages/flutter_demo/assets/images/hot_foot_N.png", "packages/flutter_demo/assets/images/hot_foot_S.png"]
    def self.get_asserts_in_dir (assert_dir_path, ignored_asset_basenames, package_name)
      assert_dir_name = assert_dir_path.split("lib/")[1]
      assets = []
      Find.find(assert_dir_path) do |path|
        if File.file?(path)
          file_basename = File.basename(path)

          if ignored_asset_basenames.include?(file_basename)
            next
          end

          assert = "packages/#{package_name}/#{assert_dir_name}/#{file_basename}"
          assets << assert
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
    # assert_dir_name example: assets/images
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