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

    # show the version of flr
    def self.version
      version_desc = "Flr version #{Flr::VERSION}\nCoreLogic version #{Flr::CORE_VERSION}"
      puts(version_desc)
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
      pubspec_file_path = FileUtil.get_pubspec_file_path

      # ----- Step-1 Begin -----
      # 进行环境检测:
      #  - 检测当前 flutter 工程根目录是否存在 pubspec.yaml
      #

      begin
        Checker.check_pubspec_file_is_existed(flutter_project_root_dir)
      rescue Exception => e
        puts(e.message)
        return
      end

      # ----- Step-1 End -----

      puts("init #{flutter_project_root_dir} now...")

      # ----- Step-2 Begin -----
      # 添加 flr_config 和 r_dart_library 的依赖声明到 pubspec.yaml
      #

      # 读取 pubspec.yaml，然后添加相关配置
      pubspec_config = FileUtil.load_pubspec_config_from_file(pubspec_file_path)
      dependencies = pubspec_config["dependencies"]

      # 添加 flr_config 到 pubspec.yaml
      #
      # flr_config: Flr的配置信息
      # ```yaml
      # flr:
      #  core_version: 1.0.0
      #  assets:
      #  fonts:
      # ```
      flr_config = Hash["core_version" => "#{Flr::CORE_VERSION}", "assets" => nil, "fonts" => nil]
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
      r_dart_library_hash = Hash["git" => Hash["url" => "https://github.com/YK-Unit/r_dart_library.git", "ref" => r_dart_library_version]]
      dependencies["r_dart_library"] = r_dart_library_hash

      # 更新并保存 pubspec.yaml
      pubspec_config["dependencies"] = dependencies
      FileUtil.dump_pubspec_config_to_file(pubspec_config, pubspec_file_path)

      puts("add flr configuration into pubspec.yaml done!")
      puts("add dependency \"r_dart_library\"(https://github.com/YK-Unit/r_dart_library) into pubspec.yaml done!")

      # ----- Step-2 End -----

      puts("get dependency \"r_dart_library\" via execute \"flutter pub get\" now ...")

      # ----- Step-3 Begin -----
      # 调用 flutter 工具，为 flutter 工程获取依赖

      get_flutter_pub_cmd = "flutter pub get"
      system(get_flutter_pub_cmd)

      puts("get dependency \"r_dart_library\" done !!!")

      # ----- Step-3 End -----

      puts("[√]: init done !!!")
    end

    # 按照以下步骤检测是否符合执行创建任务的条件
    # 1. 检测当前目录是否存在pubspec.yaml
    # 2. 检测pubspec.yaml中是否存在flr的配置
    # 3. 检测flr的配置中是否有配置了合法的资源目录路径
    # 4. 返回所有合法的资源目录路径数组
    # @return all_valid_asset_dir_paths
    def self.check_before_generate
      flutter_project_root_dir = "#{Pathname.pwd}"

      pubspec_path = "#{flutter_project_root_dir}/pubspec.yaml"

      # 检测当前目录是否存在 pubspec.yaml；
      # 若不存在，说明当前目录不是一个flutter工程目录，这时直接终止当前任务，并打印错误提示；
      unless File.exist?(pubspec_path)
        message = <<-MESSAGE
#{"[x]: #{pubspec_path} not found".error_style}
#{"[*]: please make sure current directory is a flutter project directory".tips_style}
        MESSAGE
        abort(message)
      end

      pubspec_yaml = safe_load_pubspec_file(pubspec_path)

      # 读取 pubspec_yaml，判断是否有 flr 的配置信息；
      # 若有，说明已经进行了初始化；然后检测是否配置了资源目录，若没有配置，这时直接终止当前任务，并提示开发者手动配置它
      # 若没有，说明还没进行初始化，这时直接终止当前任务，并提示开发者手动配置它

      flr_config = pubspec_yaml["flr"]
      unless flr_config.is_a?(Hash)
        message = <<-MESSAGE
#{"[x]: have no flr configuration in pubspec.yaml".error_style}
#{"[*]: please run \"flr init\" to fix it".tips_style}
        MESSAGE
        abort(message)
      end

      flr_core_version = flr_config["core_version"]
      all_asset_dir_paths = flr_config["assets"]

      unless all_asset_dir_paths.is_a?(Array)
        message = <<-MESSAGE
#{"[x]: have no valid asset directories configuration in pubspec.yaml".error_style}
#{"[*]: please manually configure the asset directories to fix it, for example: ".tips_style}

    #{"flr:".tips_style}
      #{"core_version: #{flr_core_version}".tips_style}
      #{"assets:".tips_style}
      #{"# config the asset directories that need to be scanned".tips_style}
      #{"- lib/assets/images".tips_style}
      #{"- lib/assets/texts".tips_style}

        MESSAGE
        abort(message)
      end

      # 移除非法的非法的 asset_dir_path（nil，空字符串）
      all_asset_dir_paths = all_asset_dir_paths - [nil, ""]
      # 过滤重复的 asset_dir_path
      all_asset_dir_paths = all_asset_dir_paths.uniq

      # 过滤非法的asset_dir_path：不存在对应的目录
      illegal_asset_dir_paths = []
      all_asset_dir_paths.each do |asset_dir_path|
        if File.exist?(asset_dir_path) == false
          illegal_asset_dir_paths.push(asset_dir_path)
          next
        end
      end

      if illegal_asset_dir_paths.length > 0
        puts("")
        puts("[!]: warning, found the following asset directories who do not exist: ".warning_style)
        illegal_asset_dir_paths.each do |asset_dir_path|
          puts("  - #{asset_dir_path}".warning_style)
        end
        puts("")
        all_asset_dir_paths = all_asset_dir_paths - illegal_asset_dir_paths
      end


      # 若当前all_asset_dir_paths数量为0，则说明开发者没有配置资源目录路径，这时直接终止当前任务，并提示开发者手动配置它
      unless all_asset_dir_paths.length > 0
        message = <<-MESSAGE
#{"[x]: have no valid asset directories configuration in pubspec.yaml".error_style}
#{"[*]: please manually configure the asset directories to fix it, for example: ".tips_style}

    #{"flr:".tips_style}
      #{"version: #{flr_core_version}".tips_style}
      #{"assets:".tips_style}
      #{"# config the asset directories that need to be scanned".tips_style}
      #{"- lib/assets/images".tips_style}
      #{"- lib/assets/texts".tips_style}

        MESSAGE
        abort(message)
      end

      return all_asset_dir_paths
    end

    # 扫描资源目录，自动为资源添加声明到 pubspec.yaml 和生成 r.g.dart
    def self.generate

      flutter_project_root_dir = FileUtil.get_cur_flutter_project_root_dir
      pubspec_file_path = FileUtil.get_pubspec_file_path

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
      # 进行核心逻辑版本检测：
      # 检测Flr配置中的核心逻辑版本号和当前工具的核心逻辑版本号是否一致；若不一致，则生成“核心逻辑版本不一致”的警告日志，存放到警告日志数组

      flr_core_version = flr_config["core_version"]

      if flr_core_version.nil?
        flr_core_version = "unknown"
      end

      if flr_core_version != Flr::CORE_VERSION
        message = <<-MESSAGE
#{"[!]: warning, the core logic version of the configured Flr tool is #{flr_core_version}, while the core logic version of the currently used Flr tool is #{Flr::CORE_VERSION}".warning_style}
#{"[*]: to fix it, you should make sure that the core logic version of the Flr tool you are currently using is consistent with the configuration".tips_style}
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
      legal_resource_dir_result_tuple = resource_dir_result_tuple[0]
      assets_legal_resource_dir_array = legal_resource_dir_result_tuple[0]
      fonts_legal_resource_dir_array = legal_resource_dir_result_tuple[1]
      # 非法的资源目录数组
      illegal_resource_dir_array = resource_dir_result_tuple[1]

      if illegal_resource_dir_array.length > 0
        message = "[!]: warning, found the following resource directory who is non-existed: ".warning_style
        illegal_resource_dir_array.each do |resource_dir|
          message = message + "\n" + "  - #{resource_dir}".warning_style
        end

        warning_messages.push(message)
      end

      # ----- Step-3 End -----

      # 扫描资源
      puts("scan assets now ...")

      # ----- Step-4 Begin -----
      # 扫描assets_legal_resource_dir数组中的legal_resource_dir，输出image_asset数组和illegal_image_file数组：
      # - 创建image_asset数组、illegal_image_file数组；
      # - 遍历assets_legal_resource_dir数组，按照如下处理每个资源目录：
      #  - 扫描当前资源目录和其第1级的子目录，查找所有image_file；
      #  - 根据legal_resource_file的标准，筛选查找结果生成legal_image_file子数组和illegal_image_file子数组；illegal_image_file子数组合并到illegal_image_file数组；
      #  - 根据image_asset的定义，遍历legal_image_file子数组，生成image_asset子数；组；image_asset子数组合并到image_asset数组。
      # - 对image_asset数组做去重处理；
      # - 按照字典顺序对image_asset数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      # - 输出image_asset数组和illegal_image_file数组。
      #

      image_asset_array = []
      illegal_image_file_array = []

      assets_legal_resource_dir_array.each do |resource_dir|
        image_file_result_tuple = FileUtil.find_image_files(resource_dir)
        legal_image_file_subarray = image_file_result_tuple[0]
        illegal_image_file_subarray = image_file_result_tuple[1]

        illegal_image_file_array += illegal_image_file_subarray

        image_asset_subarray = AssetUtil.generate_image_assets(legal_image_file_subarray, resource_dir, package_name)
        image_asset_array += image_asset_subarray
      end

      image_asset_array.uniq!
      image_asset_array.sort!

      # ----- Step-4 End -----

      # ----- Step-5 Begin -----
      # 扫描assets_legal_resource_dir数组中的legal_resource_dir，输出text_asset数组和illegal_text_file数组：
      # - 创建text_asset数组、illegal_text_file数组；
      #
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

        text_asset_subarray = AssetUtil.generate_text_assets(legal_text_file_subarray, resource_dir, package_name)
        text_asset_array += text_asset_subarray
      end

      text_asset_array.uniq!
      text_asset_array.sort!

      # ----- Step-5 End -----

      # ----- Step-6 Begin -----
      # 扫描fonts_legal_resource_dir数组中的legal_resource_dir，输出font_family_config数组、illegal_font_file数组；：
      #
      # - 创建font_family_config数组、illegal_font_file数组；
      # - 遍历fonts_legal_resource_dir数组，按照如下处理每个资源目录：
      #  - 扫描当前资源目录，获得其第1级子目录数组，并按照字典顺序对数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      #  - 遍历第1级子目录数组，按照如下处理每个子目录：
      #    - 获取当前子目录的名称，生成font_family_name；
      #    - 扫描当前子目录和其所有子目录，查找所有font_file；
      #    - 根据legal_resource_file的标准，筛选查找结果生成legal_font_file数组和illegal_font_file子数组；illegal_font_file子数组合并到illegal_font_file数组；
      #    - 据font_asset的定义，遍历legal_font_file数组，生成font_asset_config数组；
      #    - 根据font_family_config的定义，为当前子目录组织font_family_name和font_asset_config数组生成font_family_config对象，添加到font_family_config子数组；font_family_config子数组合并到font_family_config数组。
      # - 输出font_family_config数组、illegal_font_file数组。
      #

      font_family_config_array = []
      illegal_font_file_array = []

      fonts_legal_resource_dir_array.each do |resource_dir|
        top_child_dir_array = FileUtil.find_top_child_dirs(resource_dir)

        top_child_dir_array.sort!

        top_child_dir_array.each do |child_dir|
          font_family_name = File.basename(child_dir)

          font_file_result_tuple = FileUtil.find_font_files(child_dir)
          legal_font_file_array = font_file_result_tuple[0]
          illegal_font_file_subarray = font_file_result_tuple[1]

          illegal_font_file_array += illegal_font_file_subarray

          unless legal_font_file_array.length > 0
            next
          end

          font_asset_config_array = AssetUtil.generate_font_asset_configs(legal_font_file_array, child_dir, package_name)
          font_family_config =  Hash["family" => font_family_name , "fonts" => font_asset_config_array]
          font_family_config_array.push(font_family_config)
        end
      end

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
        message = message + "\n" + "[*]: to fix it, you should only use letters (a-z, A-Z), numbers (0-9), and the other legal characters ('_', '+', '-', '.', '·', '!', '@', '&', '$', '￥') to name the asset".tips_style

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
      # 按照SVG分类，从image_asset数组筛选得到有序的non_svg_image_asset数组和svg_image_asset数组：
      #  - 按照SVG分类，从image_asset数组筛选得到non_svg_image_asset数组和svg_image_asset数组；
      #  - 按照字典顺序对non_svg_image_asset数组和svg_image_asset数组做升序排列（一般使用开发语言提供的默认的sort算法即可）；
      #

      non_svg_image_asset_array = []
      svg_image_asset_array = []

      image_asset_array.each do |image_asset|
        file_extname = File.extname(image_asset).downcase

        if file_extname.eql?(".svg")
          svg_image_asset_array.push(image_asset)
        else
          non_svg_image_asset_array.push(image_asset)
        end
      end

      non_svg_image_asset_array.sort!
      svg_image_asset_array.sort!

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
      g__R_Image_AssetResource_class_code = CodeUtil.generate__R_Image_AssetResource_class(non_svg_image_asset_array, package_name)
      r_dart_file.puts(g__R_Image_AssetResource_class_code)

      # ----- Step-13 End -----

      # ----- Step-14 Begin -----
      # 遍历 svg_image_asset 数组，生成 _R_Svg_AssetResource 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Svg_AssetResource_class_code = CodeUtil.generate__R_Svg_AssetResource_class(svg_image_asset_array, package_name)
      r_dart_file.puts(g__R_Svg_AssetResource_class_code)

      # ----- Step-14 End -----

      # ----- Step-15 Begin -----
      # 遍历 text_asset 数组，生成 _R_Image_AssetResource 类，追加写入 r.g.dart
      #

      r_dart_file.puts("\n")
      g__R_Text_AssetResource_class_code = CodeUtil.generate__R_Text_AssetResource_class(text_asset_array, package_name)
      r_dart_file.puts(g__R_Text_AssetResource_class_code)

      # ----- Step-15 End -----


      # ----- Step-16 Begin -----
      # 遍历non_svg_image_asset数组，生成 _R_Image 类，追加写入 r.g.dart
      #

      r_dart_file.puts("\n")
      g__R_Image_class_code = CodeUtil.generate__R_Image_class(non_svg_image_asset_array, package_name)
      r_dart_file.puts(g__R_Image_class_code)

      # ----- Step-16 End -----

      # ----- Step-17 Begin -----
      # 遍历 svg_image_asset 数组，生成 _R_Svg 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Svg_class_code = CodeUtil.generate__R_Svg_class(svg_image_asset_array, package_name)
      r_dart_file.puts(g__R_Svg_class_code)

      # ----- Step-17 End -----

      # ----- Step-18 Begin -----
      # 遍历 text_asset 数组，生成 _R_Image 类，追加写入 r.g.dart。
      #

      r_dart_file.puts("\n")
      g__R_Text_class_code = CodeUtil.generate__R_Text_class(text_asset_array, package_name)
      r_dart_file.puts(g__R_Text_class_code)

      # ----- Step-18 End -----

      # ----- Step-19 Begin -----
      # 遍历font_family_config数组，根据下面的模板生成_R_Font_Family类，追加写入r.g.dart。

      r_dart_file.puts("\n")
      g__R_Font_Family_class_code = CodeUtil.generate__R_Font_Family_class(font_family_config_array, package_name)
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

      flutter_format_cmd = "flutter format #{r_dart_path}"
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
    def self.start_assert_monitor

      flutter_project_root_dir = FileUtil.get_cur_flutter_project_root_dir
      pubspec_file_path = FileUtil.get_pubspec_file_path

      # ----- Step-1 Begin -----
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

      # ----- Step-1 End -----

      # ----- Step-2 Begin -----
      # 从 pubspec.yaml 读取 legal_resource_dir 数组
      #
      begin
        pubspec_config = FileUtil.load_pubspec_config_from_file(pubspec_file_path)

        flr_config = pubspec_config["flr"]

        resource_dir_result_tuple = Checker.check_flr_assets_is_legal(flr_config)

      rescue Exception => e
        puts(e.message)
        return
      end

      # 合法的资源目录数组
      legal_resource_dir_array = resource_dir_result_tuple[0]
      # 非法的资源目录数组
      illegal_resource_dir_array = resource_dir_result_tuple[1]

      # ----- Step-2 End -----

      # ----- Step-3 Begin -----
      # 启动资源监控服务
      #  - 启动一个文件监控服务，对 legal_resource_dir 数组中的资源目录进行文件监控
      #  - 若服务检测到资源变化（资源目录下的发生增/删/改文件），则执行一次 flr generate 操作
      #

      now_str = Time.now.to_s
      puts("--------------------------- #{now_str} ---------------------------")
      puts("launch a monitoring service now ...")
      puts("launching ...")
      # stop the monitoring service if exists
      stop_assert_monitor
      puts("launch a monitoring service done !!!")
      puts("the monitoring service is monitoring the following resource directory:")
      legal_resource_dir_array.each do |resource_dir|
        puts("  - #{resource_dir}")
      end
      if illegal_resource_dir_array.length > 0
        puts("")
        puts("[!]: warning, found the following resource directory who is non-existed: ".warning_style)
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
        stop_assert_monitor
        puts("")
        puts("[√]: terminate monitor service done !!!")
      end

    end

    # 停止资源变化监控服务
    def self.stop_assert_monitor
      if @@listener.nil? == false
        @@listener.stop
        @@listener = nil
      end
    end

  end

end