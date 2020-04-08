require 'yaml'
require 'find'
require 'listen'
require 'flr/version'
require 'flr/string_extensions'
require 'flr/checker'
require 'flr/util/file_util'
require 'flr/util/asset_util'
require 'flr/util/code_util'

# 专有名词简单解释和示例：
# （详细定义请看 flr-core 项目的文档描述）
#
# package_name：flutter工程的package产物的名称，例如“flutter_demo”
# resource_file：flutter工程的资源文件，例如“lib/assets/images/hot_foot_N.png”、“lib/assets/images/3.0x/hot_foot_N.png”
# asset：flutter工程的package产物中资源，可当作是工程中的资源文件的映射和声明，例如上述2个资源对于的asset都是“packages/flutter_demo/assets/images/hot_foot_N.png”
# file_basename：资源的文件名，其定义是“#{file_basename_no_extension}#{file_extname}”，例如“hot_foot_N.png”
# file_basename_no_extension：资源的不带扩展名的文件名，例如“hot_foot_N”
# file_extname：资源的扩展名，例如“.png”
#
# asset_name：main asset的名称，例如“assets/images/hot_foot_N.png”
# asset_id：资源ID，其值一般为 file_basename_no_extension

module Flr
  class Command

    # Listen Class Instance
    @@listener = nil

    # display the version of flr
    def self.version
      version_desc = "Flr version #{Flr::VERSION}\nCoreLogic version #{Flr::CORE_VERSION}"
      puts(version_desc)
    end

    # display recommended flutter resource structure
    def self.display_recommended_flutter_resource_structure
      message = <<-MESSAGE
Flr recommends the following flutter resource structure:

  flutter_project_root_dir
  ├── build
  │   ├── ..
  ├── lib
  │   ├── assets
  │   │   ├── images #{"// image resource directory of all modules".red}
  │   │   │   ├── \#{module} #{"// image resource directory of a module".red}
  │   │   │   │   ├── \#{main_image_asset}
  │   │   │   │   ├── \#{variant-dir} #{"// image resource directory of a variant".red}
  │   │   │   │   │   ├── \#{image_asset_variant}
  │   │   │   │
  │   │   │   ├── home #{"// image resource directory of home module".red}
  │   │   │   │   ├── home_badge.svg
  │   │   │   │   ├── home_icon.png
  │   │   │   │   ├── 3.0x #{"// image resource directory of a 3.0x-ratio-variant".red}
  │   │   │   │   │   ├── home_icon.png
  │   │   │   │		
  │   │   ├── texts #{"// text resource directory".red}
  │   │   │   │     #{"// (you can also break it down further by module)".red}
  │   │   │   └── test.json
  │   │   │   └── test.yaml
  │   │   │   │
  │   │   ├── fonts #{"// font resource directory of all font-families".red}
  │   │   │   ├── \#{font-family} #{"// font resource directory of a font-family".red}
  │   │   │   │   ├── \#{font-family}-\#{font_weight_or_style}.ttf
  │   │   │   │
  │   │   │   ├── Amiri #{"// font resource directory of Amiri font-family".red}
  │   │   │   │   ├── Amiri-Regular.ttf
  │   │   │   │   ├── Amiri-Bold.ttf
  │   │   │   │   ├── Amiri-Italic.ttf
  │   │   │   │   ├── Amiri-BoldItalic.ttf
  │   ├── ..

#{"[*]: Then config the resource directories that need to be scanned as follows：".tips_style}

  #{"flr:".tips_style}
    #{"core_version: #{Flr::CORE_VERSION}".tips_style}
    #{"dartfmt_line_length: #{Flr::DARTFMT_LINE_LENGTH}".tips_style}
    #{"# config the image and text resource directories that need to be scanned".tips_style}
    #{"assets:".tips_style}
      #{"- lib/assets/images".tips_style}
      #{"- lib/assets/texts".tips_style}
    #{"# config the font resource directories that need to be scanned".tips_style}
    #{"fonts:".tips_style}
      #{"- lib/assets/fonts".tips_style}

      MESSAGE

      puts(message)
    end

    # get the right version of r_dart_library package based on flutter's version
    # to get more detail, see https://github.com/YK-Unit/r_dart_library#dependency-relationship-table
    def self.get_r_dart_library_version
      r_dart_library_version = "0.1.1"

      # $ flutter --version
      # Flutter 1.12.13+hotfix.5 • channel stable • https://github.com/flutter/flutter.git
      # Framework • revision 27321ebbad (5 weeks ago) • 2019-12-10 18:15:01 -0800
      # Engine • revision 2994f7e1e6
      # Tools • Dart 2.7.0
      flutter_version_result = `flutter --version`
      if (flutter_version_result.nil? == true || flutter_version_result.empty? == true)
        return r_dart_library_version
      end

      version_with_hotfix_str = flutter_version_result.split(" ")[1]
      version_without_hotfix_str = version_with_hotfix_str.split("+")[0]

      if Version.new(version_with_hotfix_str) >= Version.new("1.10.15")
        r_dart_library_version = "0.2.1"
      end

      return r_dart_library_version
    end

    # 对 flutter 工程进行初始化
    def self.init
      flutter_project_root_dir = FileUtil.get_cur_flutter_project_root_dir

      # ----- Step-1 Begin -----
      # 进行环境检测:
      #  - 检测当前 flutter 工程根目录是否存在 pubspec.yaml
      #

      begin
        Checker.check_pubspec_file_is_existed(flutter_project_root_dir)

        pubspec_file_path = FileUtil.get_pubspec_file_path

        pubspec_config = FileUtil.load_pubspec_config_from_file(pubspec_file_path)

      rescue Exception => e
        puts(e.message)
        return
      end

      # ----- Step-1 End -----

      puts("init #{flutter_project_root_dir} now...")

      # ----- Step-2 Begin -----
      # 添加 flr_config 和 r_dart_library 的依赖声明到 pubspec.yaml
      #

      dependencies_config = pubspec_config["dependencies"]

      # 添加flr_config到pubspec.yaml：检测当前是否存在flr_config；若不存在，则添加flr_config；若存在，则按照以下步骤处理：
      #  - 读取dartfmt_line_length选项、assets选项和fonts选项的值（这些选项值若存在，则应用于新建的flr_config；需要注意，使用前需要判断选项值是否合法：dartfmt_line_length选项值 >=80；assets选项和fonts选项的值为数组）
      #  - 新建flr_config，然后使用旧值或者默认值设置各个选项
      #
      # flr_config: Flr的配置信息
      # ```yaml
      # flr:
      #  core_version: 1.0.0
      #  dartfmt_line_length: 80
      #  assets: []
      #  fonts: []
      # ```

      dartfmt_line_length = Flr::DARTFMT_LINE_LENGTH
      asset_resource_dir_array = []
      font_resource_dir_array = []

      old_flr_config = pubspec_config["flr"]
      if old_flr_config.is_a?(Hash)
        dartfmt_line_length = old_flr_config["dartfmt_line_length"]
        if dartfmt_line_length.nil? or dartfmt_line_length.is_a?(Integer) == false
          dartfmt_line_length = Flr::DARTFMT_LINE_LENGTH
        end
        if dartfmt_line_length < Flr::DARTFMT_LINE_LENGTH
          dartfmt_line_length = Flr::DARTFMT_LINE_LENGTH
        end

        asset_resource_dir_array = old_flr_config["assets"]
        if asset_resource_dir_array.nil? or asset_resource_dir_array.is_a?(Array) == false
          asset_resource_dir_array = []
        end

        font_resource_dir_array = old_flr_config["fonts"]
        if font_resource_dir_array.nil? or font_resource_dir_array.is_a?(Array) == false
          font_resource_dir_array = []
        end
      end

      flr_config = Hash["core_version" => "#{Flr::CORE_VERSION}", "dartfmt_line_length" => dartfmt_line_length,  "assets" => asset_resource_dir_array, "fonts" => font_resource_dir_array]
      pubspec_config["flr"] = flr_config

      # 添加 r_dart_library（https://github.com/YK-Unit/r_dart_library）的依赖声明
      #  - 获取正确的库版本
      #  - 添加依赖声明
      #
      # r_dart_library的依赖声明：
      # ```yaml
      # r_dart_library:
      #  git:
      #    url: "https://github.com/YK-Unit/r_dart_library.git"
      #    ref: 0.1.1
      # ```
      r_dart_library_version = get_r_dart_library_version
      r_dart_library_config = Hash["git" => Hash["url" => "https://github.com/YK-Unit/r_dart_library.git", "ref" => r_dart_library_version]]
      dependencies_config["r_dart_library"] = r_dart_library_config
      pubspec_config["dependencies"] = dependencies_config

      puts("add flr configuration into pubspec.yaml done!")
      puts("add dependency \"r_dart_library\"(https://github.com/YK-Unit/r_dart_library) into pubspec.yaml done!")

      # ----- Step-2 End -----

      # ----- Step-3 Begin -----
      # 对Flutter配置进行修正，以避免执行获取依赖操作时会失败：
      # - 检测Flutter配置中的assets选项是否是一个非空数组；若不是，则删除assets选项；
      # - 检测Flutter配置中的fonts选项是否是一个非空数组；若不是，则删除fonts选项。
      #

      flutter_config = pubspec_config["flutter"]

      flutter_assets = flutter_config["assets"]
      should_rm_flutter_assets_Key = true
      if flutter_assets.is_a?(Array) == true and flutter_assets.empty? == false
        should_rm_flutter_assets_Key = false
      end
      if should_rm_flutter_assets_Key
        flutter_config.delete("assets")
      end

      flutter_fonts = flutter_config["fonts"]
      should_rm_flutter_fonts_Key = true
      if flutter_fonts.is_a?(Array) == true and flutter_fonts.empty? == false
        should_rm_flutter_fonts_Key = false
      end
      if should_rm_flutter_fonts_Key
        flutter_config.delete("fonts")
      end

      pubspec_config["flutter"] = flutter_config

      # ----- Step-3 End -----

      # 保存 pubspec.yaml
      FileUtil.dump_pubspec_config_to_file(pubspec_config, pubspec_file_path)

      puts("get dependency \"r_dart_library\" via execute \"flutter pub get\" now ...")

      # ----- Step-4 Begin -----
      # 调用 flutter 工具，为 flutter 工程获取依赖

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts("get dependency \"r_dart_library\" done !!!")

      # ----- Step-4 End -----

      puts("[√]: init done !!!")

      puts("")
      puts("[*]: if you want to know how to make a good resource structure for your flutter project, please run \"flr recommend\" ".tips_style)

    end

    # 扫描资源目录，自动为资源添加声明到 pubspec.yaml 和生成 r.g.dart
    def self.generate

      flutter_project_root_dir = FileUtil.get_cur_flutter_project_root_dir

      # 警告日志数组
      warning_messages = []

      # ----- Step-1 Begin -----
      # 进行环境检测；若发现不合法的环境，则抛出异常，终止当前进程：
      # - 检测当前flutter工程根目录是否存在pubspec.yaml
      # - 检测当前pubspec.yaml中是否存在Flr的配置
      # - 检测当前flr_config中的resource_dir配置是否合法：
      #   判断合法的标准是：assets配置或者fonts配置了至少1个legal_resource_dir
      #

      begin
        Checker.check_pubspec_file_is_existed(flutter_project_root_dir)

        pubspec_file_path = FileUtil.get_pubspec_file_path

        pubspec_config = FileUtil.load_pubspec_config_from_file(pubspec_file_path)

        Checker.check_flr_config_is_existed(pubspec_config)

        flr_config = pubspec_config["flr"]

        resource_dir_result_tuple = Checker.check_flr_assets_is_legal(flutter_project_root_dir, flr_config)

      rescue Exception => e
        puts(e.message)
        return
      end

      package_name = pubspec_config["name"]

      # ----- Step-1 End -----

      # ----- Step-2 Begin -----
      # 进行核心逻辑版本检测：
      # 检测flr_config中的core_version和当前工具的core_version是否一致；若不一致，则按照以下规则处理：
      #  - 更新flr_config中的core_version的值为当前工具的core_version；
      #  - 生成“核心逻辑版本不一致”的警告日志，存放到警告日志数组。
      #

      flr_core_version = flr_config["core_version"]

      if flr_core_version.nil?
        flr_core_version = "unknown"
      end

      if flr_core_version != Flr::CORE_VERSION
        flr_config["core_version"] = Flr::CORE_VERSION

        message = <<-MESSAGE
#{"[!]: warning, some team members may be using Flr tool with core_version #{flr_core_version}, while you are using Flr tool with core_version #{Flr::CORE_VERSION}".warning_style}
#{"[*]: to fix it, you and your team members should use the Flr tool with same core_version".tips_style}
#{"[*]: \"core_version\" is the core logic version of Flr tool, you can run \"flr version\" to get it".tips_style}

        MESSAGE

        warning_messages.push(message)
      end

      # ----- Step-2 End -----

      # ----- Step-3 Begin -----
      # 获取assets_legal_resource_dir数组、fonts_legal_resource_dir数组和illegal_resource_dir数组：
      # - 从flr_config中的assets配置获取assets_legal_resource_dir数组和assets_illegal_resource_dir数组；
      # - 从flr_config中的fonts配置获取fonts_legal_resource_dir数组和fonts_illegal_resource_dir数组；
      # - 合并assets_illegal_resource_dir数组和fonts_illegal_resource_dir数组为illegal_resource_dir数组‘；若illegal_resource_dir数组长度大于0，则生成“存在非法的资源目录”的警告日志，存放到警告日志数组。

      # 合法的资源目录数组
      assets_legal_resource_dir_array = resource_dir_result_tuple[0]
      fonts_legal_resource_dir_array = resource_dir_result_tuple[1]
      # 非法的资源目录数组
      illegal_resource_dir_array = resource_dir_result_tuple[2]

      if illegal_resource_dir_array.length > 0
        message = "[!]: warning, found the following resource directory which is not existed: ".warning_style
        illegal_resource_dir_array.each do |resource_dir|
          message = message + "\n" + "  - #{resource_dir}".warning_style
        end

        warning_messages.push(message)
      end

      # ----- Step-3 End -----

      # 扫描资源
      puts("scan assets now ...")

      # ----- Step-4 Begin -----
      # 扫描assets_legal_resource_dir数组中的legal_resource_dir，输出有序的image_asset数组、non_svg_image_asset数组、svg_image_asset数组、illegal_image_file数组：
      # - 创建image_asset数组、illegal_image_file数组；
      # - 遍历assets_legal_resource_dir数组，按照如下处理每个资源目录：
      #  - 扫描当前资源目录和其所有层级的子目录，查找所有image_file；
      #  - 根据legal_resource_file的标准，筛选查找结果生成legal_image_file子数组和illegal_image_file子数组；illegal_image_file子数组合并到illegal_image_file数组；
      #  - 根据image_asset的定义，遍历legal_image_file子数组，生成image_asset子数；组；image_asset子数组合并到image_asset数组。
      # - 对image_asset数组做去重处理；
      # - 按照字典顺序对image_asset数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      # - 按照SVG分类，从image_asset数组筛选得到有序的non_svg_image_asset数组和svg_image_asset数组：
      #  - 按照SVG分类，从image_asset数组筛选得到non_svg_image_asset数组和svg_image_asset数组；
      #  - 按照字典顺序对non_svg_image_asset数组和svg_image_asset数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      # - 输出有序的image_asset数组、non_svg_image_asset数组、svg_image_asset数组、illegal_image_file数组。

      image_asset_array = []
      illegal_image_file_array = []

      assets_legal_resource_dir_array.each do |resource_dir|
        image_file_result_tuple = FileUtil.find_image_files(resource_dir)
        legal_image_file_subarray = image_file_result_tuple[0]
        illegal_image_file_subarray = image_file_result_tuple[1]

        illegal_image_file_array += illegal_image_file_subarray

        image_asset_subarray = AssetUtil.generate_image_assets(flutter_project_root_dir, package_name, legal_image_file_subarray)
        image_asset_array += image_asset_subarray
      end

      image_asset_array.uniq!
      image_asset_array.sort!

      non_svg_image_asset_array = []
      svg_image_asset_array = []

      image_asset_array.each do |image_asset|
        if FileUtil.is_svg_image_resource_file?(image_asset)
          svg_image_asset_array.push(image_asset)
        else
          non_svg_image_asset_array.push(image_asset)
        end

      end

      non_svg_image_asset_array.sort!
      svg_image_asset_array.sort!

      # ----- Step-4 End -----

      # ----- Step-5 Begin -----
      # 扫描assets_legal_resource_dir数组中的legal_resource_dir，输出text_asset数组和illegal_text_file数组：
      # - 创建text_asset数组、illegal_text_file数组；
      # - 遍历assets_legal_resource_dir数组，按照如下处理每个资源目录：
      #  - 扫描当前资源目录和其所有层级的子目录，查找所有text_file；
      #  - 根据legal_resource_file的标准，筛选查找结果生成legal_text_file子数组和illegal_text_file子数组；illegal_text_file子数组合并到illegal_text_file数组；
      #  - 根据text_asset的定义，遍历legal_text_file子数组，生成text_asset子数组；text_asset子数组合并到text_asset数组。
      # - 对text_asset数组做去重处理；
      # - 按照字典顺序对text_asset数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      # - 输出text_asset数组和illegal_image_file数组。
      #

      text_asset_array = []
      illegal_text_file_array = []

      assets_legal_resource_dir_array.each do |resource_dir|
        text_file_result_tuple = FileUtil.find_text_files(resource_dir)
        legal_text_file_subarray = text_file_result_tuple[0]
        illegal_text_file_subarray = text_file_result_tuple[1]

        illegal_text_file_array += illegal_text_file_subarray

        text_asset_subarray = AssetUtil.generate_text_assets(flutter_project_root_dir, package_name, legal_text_file_subarray)
        text_asset_array += text_asset_subarray
      end

      text_asset_array.uniq!
      text_asset_array.sort!

      # ----- Step-5 End -----

      # ----- Step-6 Begin -----
      # 扫描fonts_legal_resource_dir数组中的legal_resource_dir，输出font_family_config数组、illegal_font_file数组：
      # - 创建font_family_config数组、illegal_font_file数组；
      # - 遍历fonts_legal_resource_dir数组，按照如下处理每个资源目录：
      #  - 扫描当前资源目录，获得其第1级子目录数组，并按照字典顺序对数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      #  - 遍历第1级子目录数组，按照如下处理每个子目录：
      #    - 获取当前子目录的名称，生成font_family_name；
      #    - 扫描当前子目录和其所有子目录，查找所有font_file；
      #    - 根据legal_resource_file的标准，筛选查找结果生成legal_font_file数组和illegal_font_file子数组；illegal_font_file子数组合并到illegal_font_file数组；
      #    - 据font_asset的定义，遍历legal_font_file数组，生成font_asset_config数组；
      #    - 按照字典顺序对生成font_asset_config数组做升序排列（比较asset的值）；
      #    - 根据font_family_config的定义，为当前子目录组织font_family_name和font_asset_config数组生成font_family_config对象，添加到font_family_config子数组；font_family_config子数组合并到font_family_config数组。
      # - 输出font_family_config数组、illegal_font_file数组；
      # - 按照字典顺序对font_family_config数组做升序排列（比较family的值）。
      #

      font_family_config_array = []
      illegal_font_file_array = []

      fonts_legal_resource_dir_array.each do |resource_dir|
        font_family_dir_array = FileUtil.find_top_child_dirs(resource_dir)

        font_family_dir_array.each do |font_family_dir|
          font_family_name = File.basename(font_family_dir)

          font_file_result_tuple = FileUtil.find_font_files_in_font_family_dir(font_family_dir)
          legal_font_file_array = font_file_result_tuple[0]
          illegal_font_file_subarray = font_file_result_tuple[1]

          illegal_font_file_array += illegal_font_file_subarray

          unless legal_font_file_array.length > 0
            next
          end

          font_asset_config_array = AssetUtil.generate_font_asset_configs(flutter_project_root_dir, package_name, legal_font_file_array)
          font_asset_config_array.sort!{|a, b| a["asset"] <=> b["asset"]}

          font_family_config =  Hash["family" => font_family_name , "fonts" => font_asset_config_array]
          font_family_config_array.push(font_family_config)
        end
      end

      font_family_config_array.sort!{|a, b| a["family"] <=> b["family"]}

      # ----- Step-6 End -----

      puts("scan assets done !!!")

      # ----- Step-7 Begin -----
      # 检测是否存在illegal_resource_file：
      # - 合并illegal_image_file数组、illegal_text_file数组和illegal_font_file数组为illegal_resource_file数组；
      # - 若illegal_resource_file数组长度大于0，则生成“存在非法的资源文件”的警告日志，存放到警告日志数组。

      illegal_resource_file_array = illegal_image_file_array + illegal_text_file_array + illegal_font_file_array
      if illegal_resource_file_array.length > 0
        message = "[!]: warning, found the following illegal resource file who's file basename contains illegal characters: ".warning_style
        illegal_resource_file_array.each do |resource_file|
          message = message + "\n" + "  - #{resource_file}".warning_style
        end
        message = message + "\n" + "[*]: to fix it, you should only use letters (a-z, A-Z), numbers (0-9), and the other legal characters ('_', '+', '-', '.', '·', '!', '@', '&', '$', '￥') to name the file".tips_style

        warning_messages.push(message)
      end

      # ----- Step-7 End -----

      puts("specify scanned assets in pubspec.yaml now ...")

      # ----- Step-8 Begin -----
      # 为扫描得到的legal_resource_file添加资源声明到pubspec.yaml：
      # - 合并image_asset数组和text_asset数组为asset数组（image_asset数组元素在前）;
      # - 修改pubspec.yaml中flutter-assets配置的值为asset数组；
      # - 修改pubspec.yaml中flutter-fonts配置的值为font_family_config数组。

      asset_array = image_asset_array + text_asset_array
      if asset_array.length > 0
        pubspec_config["flutter"]["assets"] = asset_array
      else
        pubspec_config["flutter"].delete("assets")
      end

      if font_family_config_array.length > 0
        pubspec_config["flutter"]["fonts"] = font_family_config_array
      else
        pubspec_config["flutter"].delete("fonts")
      end

      FileUtil.dump_pubspec_config_to_file(pubspec_config, pubspec_file_path)

      # ----- Step-8 End -----

      puts("specify scanned assets in pubspec.yaml done !!!")

      # ----- Step-9 Begin -----
      # 分别遍历non_svg_image_asset数组、svg_image_asset数组、text_asset数组，
      # 根据asset_id生成算法，分别输出non_svg_image_asset_id字典、svg_image_asset_id 字典、text_asset_id字典。
      # 字典的key为asset，value为asset_id。
      #
      non_svg_image_asset_id_dict = Hash[]
      svg_image_asset_id_dict = Hash[]
      text_asset_id_dict = Hash[]

      non_svg_image_asset_array.each do |asset|
        used_asset_id_array = non_svg_image_asset_id_dict.values
        asset_id = CodeUtil.generate_asset_id(asset, used_asset_id_array, Flr::PRIOR_NON_SVG_IMAGE_FILE_TYPE)
        non_svg_image_asset_id_dict[asset] = asset_id
      end

      svg_image_asset_array.each do |asset|
        used_asset_id_array = svg_image_asset_id_dict.values
        asset_id = CodeUtil.generate_asset_id(asset, used_asset_id_array, Flr::PRIOR_SVG_IMAGE_FILE_TYPE)
        svg_image_asset_id_dict[asset] = asset_id
      end

      text_asset_array.each do |asset|
        used_asset_id_array = text_asset_id_dict.values
        asset_id = CodeUtil.generate_asset_id(asset, used_asset_id_array, Flr::PRIOR_TEXT_FILE_TYPE)
        text_asset_id_dict[asset] = asset_id
      end

      # ----- Step-9 End -----

      puts("generate \"r.g.dart\" now ...")

      # ----- Step-10 Begin -----
      # 在当前根目录下创建新的r.g.dart文件。
      #

      r_dart_path = "#{flutter_project_root_dir}/lib/r.g.dart"
      r_dart_file = File.open(r_dart_path, "w")

      # ----- Step-10 End -----

      # ----- Step-11 Begin -----
      # 生成 R 类的代码，追加写入r.g.dart
      #

      g_R_class_code = CodeUtil.generate_R_class(package_name)
      r_dart_file.puts(g_R_class_code)

      # ----- Step-11 End -----

      # ----- Step-12 Begin -----
      # 生成 AssetResource 类的代码，追加写入r.g.dart
      #

      r_dart_file.puts("\n")
      g_AssetResource_class_code = CodeUtil.generate_AssetResource_class(package_name)
      r_dart_file.puts(g_AssetResource_class_code)

      # ----- Step-12 End -----

      # ----- Step-13 Begin -----
      # 遍历 non_svg_image_asset 数组，生成 _R_Image_AssetResource 类，追加写入 r.g.dart
      #

      r_dart_file.puts("\n")
      g__R_Image_AssetResource_class_code = CodeUtil.generate__R_Image_AssetResource_class(non_svg_image_asset_array, non_svg_image_asset_id_dict, package_name)
      r_dart_file.puts(g__R_Image_AssetResource_class_code)

      # ----- Step-13 End -----

      # ----- Step-14 Begin -----
      # 遍历 svg_image_asset 数组，生成 _R_Svg_AssetResource 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Svg_AssetResource_class_code = CodeUtil.generate__R_Svg_AssetResource_class(svg_image_asset_array, svg_image_asset_id_dict,  package_name)
      r_dart_file.puts(g__R_Svg_AssetResource_class_code)

      # ----- Step-14 End -----

      # ----- Step-15 Begin -----
      # 遍历 text_asset 数组，生成 _R_Image_AssetResource 类，追加写入 r.g.dart
      #

      r_dart_file.puts("\n")
      g__R_Text_AssetResource_class_code = CodeUtil.generate__R_Text_AssetResource_class(text_asset_array, text_asset_id_dict, package_name)
      r_dart_file.puts(g__R_Text_AssetResource_class_code)

      # ----- Step-15 End -----


      # ----- Step-16 Begin -----
      # 遍历non_svg_image_asset数组，生成 _R_Image 类，追加写入 r.g.dart
      #

      r_dart_file.puts("\n")
      g__R_Image_class_code = CodeUtil.generate__R_Image_class(non_svg_image_asset_array, non_svg_image_asset_id_dict, package_name)
      r_dart_file.puts(g__R_Image_class_code)

      # ----- Step-16 End -----

      # ----- Step-17 Begin -----
      # 遍历 svg_image_asset 数组，生成 _R_Svg 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Svg_class_code = CodeUtil.generate__R_Svg_class(svg_image_asset_array, svg_image_asset_id_dict, package_name)
      r_dart_file.puts(g__R_Svg_class_code)

      # ----- Step-17 End -----

      # ----- Step-18 Begin -----
      # 遍历 text_asset 数组，生成 _R_Image 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Text_class_code = CodeUtil.generate__R_Text_class(text_asset_array, text_asset_id_dict, package_name)
      r_dart_file.puts(g__R_Text_class_code)

      # ----- Step-18 End -----

      # ----- Step-19 Begin -----
      # 遍历font_family_config数组，根据下面的模板生成_R_Font_Family类，追加写入r.g.dart。

      r_dart_file.puts("\n")
      g__R_Font_Family_class_code = CodeUtil.generate__R_FontFamily_class(font_family_config_array, package_name)
      r_dart_file.puts(g__R_Font_Family_class_code)

      # ----- Step-19 End -----

      # ----- Step-20 Begin -----
      # 结束操作，保存 r.g.dart
      #

      r_dart_file.close
      puts("generate \"r.g.dart\" done !!!")

      # ----- Step-20 End -----

      # ----- Step-21 Begin -----
      # 调用 flutter 工具对 r.g.dart 进行格式化操作
      #

      dartfmt_line_length = flr_config["dartfmt_line_length"]
      if dartfmt_line_length.nil? or dartfmt_line_length.is_a?(Integer) == false
        dartfmt_line_length = Flr::DARTFMT_LINE_LENGTH
      end

      if dartfmt_line_length < Flr::DARTFMT_LINE_LENGTH
        dartfmt_line_length = Flr::DARTFMT_LINE_LENGTH
      end

      flutter_format_cmd = "flutter format #{r_dart_path} -l #{dartfmt_line_length}"
      puts("execute \"#{flutter_format_cmd}\" now ...")
      system(flutter_format_cmd)
      puts("execute \"#{flutter_format_cmd}\" done !!!")

      # ----- Step-21 End -----

      # ----- Step-22 Begin -----
      # 调用flutter工具，为flutter工程获取依赖
      #

      get_flutter_pub_cmd = "flutter pub get"
      puts("execute \"#{get_flutter_pub_cmd}\" now ...")
      system(get_flutter_pub_cmd)
      puts("execute \"#{get_flutter_pub_cmd}\" done !!!")

      # ----- Step-22 End -----

      puts("[√]: generate done !!!")

      # ----- Step-23 Begin -----
      # 判断警告日志数组是否为空，若不为空，输出所有警告日志
      #

      if warning_messages.length > 0
        warning_messages.each do |warning_message|
          puts("")
          puts(warning_message)
        end
      end

      # ----- Step-23 End -----

    end

    # 启动一个资源变化监控服务，若检测到有资源变化，就自动执行generate操作；手动输入`Ctrl-C`，可终止当前服务
    def self.start_monitor

      flutter_project_root_dir = FileUtil.get_cur_flutter_project_root_dir

      # ----- Step-1 Begin -----
      # 进行环境检测；若发现不合法的环境，则抛出异常，终止当前进程：
      # - 检测当前flutter工程根目录是否存在pubspec.yaml
      # - 检测当前pubspec.yaml中是否存在Flr的配置
      # - 检测当前flr_config中的resource_dir配置是否合法：
      #   判断合法的标准是：assets配置或者fonts配置了至少1个legal_resource_dir
      #

      begin
        Checker.check_pubspec_file_is_existed(flutter_project_root_dir)

        pubspec_file_path = FileUtil.get_pubspec_file_path

        pubspec_config = FileUtil.load_pubspec_config_from_file(pubspec_file_path)

        Checker.check_flr_config_is_existed(pubspec_config)

        flr_config = pubspec_config["flr"]

        resource_dir_result_tuple = Checker.check_flr_assets_is_legal(flr_config)

      rescue Exception => e
        puts(e.message)
        return
      end

      package_name = pubspec_config["name"]

      # ----- Step-1 End -----

      # ----- Step-2 Begin -----
      # 执行一次 flr generate 操作
      #

      now_str = Time.now.to_s
      puts("--------------------------- #{now_str} ---------------------------")
      puts("scan assets, specify scanned assets in pubspec.yaml, generate \"r.g.dart\" now ...")
      puts("\n")
      generate
      puts("\n")
      puts("scan assets, specify scanned assets in pubspec.yaml, generate \"r.g.dart\" done !!!")
      puts("---------------------------------------------------------------------------------")
      puts("\n")

      # ----- Step-2 End -----

      # ----- Step-3 Begin -----
      # 获取legal_resource_dir数组：
      # - 从flr_config中的assets配置获取assets_legal_resource_dir数组；
      # - 从flr_config中的fonts配置获取fonts_legal_resource_dir数组；
      # - 合并assets_legal_resource_dir数组和fonts_legal_resource_dir数组为legal_resource_dir数组。
      #

      # 合法的资源目录数组
      assets_legal_resource_dir_array = resource_dir_result_tuple[0]
      fonts_legal_resource_dir_array = resource_dir_result_tuple[1]

      legal_resource_dir_array = assets_legal_resource_dir_array + fonts_legal_resource_dir_array

      # 非法的资源目录数组
      illegal_resource_dir_array = resource_dir_result_tuple[2]

      # ----- Step-3 End -----

      # ----- Step-4 Begin -----
      # 启动资源监控服务
      #  - 启动一个文件监控服务，对 legal_resource_dir 数组中的资源目录进行文件监控
      #  - 若服务检测到资源变化（资源目录下的发生增/删/改文件），则执行一次 flr generate 操作
      #

      now_str = Time.now.to_s
      puts("--------------------------- #{now_str} ---------------------------")
      puts("launch a monitoring service now ...")
      puts("launching ...")
      # stop the monitoring service if exists
      stop_monitor
      puts("launch a monitoring service done !!!")
      puts("the monitoring service is monitoring the following resource directory:")
      legal_resource_dir_array.each do |resource_dir|
        puts("  - #{resource_dir}")
      end
      if illegal_resource_dir_array.length > 0
        puts("")
        puts("[!]: warning, found the following resource directory which is not existed: ".warning_style)
        illegal_resource_dir_array.each do |resource_dir|
          puts("  - #{resource_dir}".warning_style)
        end
      end
      puts("---------------------------------------------------------------------------------")
      puts("\n")

      # Allow array of directories as input #92
      # https://github.com/guard/listen/pull/92
      @@listener = Listen.to(*legal_resource_dir_array, ignore: [/\.DS_Store/], latency: 0.5, wait_for_delay: 5, relative: true) do |modified, added, removed|
        # for example: 2013-03-30 03:13:14 +0900
        now_str = Time.now.to_s
        puts("--------------------------- #{now_str} ---------------------------")
        puts("modified resource files: #{modified}")
        puts("added resource files: #{added}")
        puts("removed resource files: #{removed}")
        puts("scan assets, specify scanned assets in pubspec.yaml, generate \"r.g.dart\" now ...")
        puts("\n")
        generate
        puts("\n")
        puts("scan assets, specify scanned assets in pubspec.yaml, generate \"r.g.dart\" done !!!")
        puts("---------------------------------------------------------------------------------")
        puts("\n")
        puts("[*]: the monitoring service is monitoring the asset changes, and then auto scan assets, specifies assets and generates \"r.g.dart\" ...".tips_style)
        puts("[*]: you can press \"Ctrl-C\" to terminate it".tips_style)
        puts("\n")
      end
      # not blocking
      @@listener.start

      # https://ruby-doc.org/core-2.5.0/Interrupt.html
      begin
        puts("[*]: the monitoring service is monitoring the asset changes, and then auto scan assets, specifies assets and generates \"r.g.dart\" ...".tips_style)
        puts("[*]: you can press \"Ctrl-C\" to terminate it".tips_style)
        puts("\n")
        loop {}
      rescue Interrupt => e
        stop_monitor
        puts("")
        puts("[√]: terminate monitor service done !!!")
      end

      # ----- Step-4 End -----

    end

    # 停止资源变化监控服务
    def self.stop_monitor
      if @@listener.nil? == false
        @@listener.stop
        @@listener = nil
      end
    end

  end

end