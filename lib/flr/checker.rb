require 'flr/string_extensions'

module Flr
  # 条件检测器，提供检测各种条件是否合法的方法
  class Checker

    # check_pubspec_file_is_existed(flutter_project_dir)  ->  true
    #
    # 检测当前flutter工程目录是否存在pubspec.yaml文件
    # 若存在，返回true
    # 若不存在，则抛出异常
    #
    # === Examples
    #
    # flutter_project_dir = "~path/to/flutter_r_demo"
    # Checker.check_pubspec_file_is_existed(flutter_project_dir)
    #
    def self.check_pubspec_file_is_existed(flutter_project_dir)
      pubspec_file_path = flutter_project_dir + "/pubspec.yaml"

      if File.exist?(pubspec_file_path) == false
        message = <<-MESSAGE
#{"[x]: #{pubspec_file_path} not found".error_style}
#{"[*]: please make sure pubspec.yaml is existed in #{flutter_project_dir}".tips_style}
        MESSAGE

        raise(message)
      end

    end

    # check_flr_config_is_existed(pubspec_config)  ->  true
    #
    # 检测pubspec.yaml中是否存在flr的配置信息`flr_config`：
    #
    # ``` yaml
    # flr:
    #   core_version: 1.0.0
    #   dartfmt_line_length: 80
    #   assets:
    #   fonts:
    # ```
    # 若存在，返回true
    # 若不存在，则抛出异常
    #
    # === Examples
    #
    # pubspec_config = YAML.load(pubspec_file)
    # Checker.check_flr_config_is_existed(pubspec_config)
    #
    def self.check_flr_config_is_existed(pubspec_config)
      flr_config = pubspec_config["flr"]

      if flr_config.is_a?(Hash) == false
        message = <<-MESSAGE
#{"[x]: have no flr configuration in pubspec.yaml".error_style}
#{"[*]: please run \"flr init\" to fix it".tips_style}
        MESSAGE

        raise(message)
      end

      return true
    end

    # check_flr_assets_is_legal(flutter_project_dir, flr_config)  ->  resource_dir_result_tuple
    #
    # 检测当前flr配置信息中的assets配置是否合法
    # 若合法，返回资源目录结果三元组 resource_dir_result_triplet
    # 若不合法，抛出异常
    #
    # resource_dir_result_tuple = [assets_legal_resource_dir_array, illegal_resource_dir_array, fonts_legal_resource_dir_array]
    #
    #
    # flr的assets配置是用于配置需要flr进行扫描的资源目录，如：
    #
    # ``` yaml
    # flr:
    #   core_version: 1.0.0
    #   dartfmt_line_length: 80
    #   assets:
    #     - lib/assets/images
    #     - lib/assets/texts
    #   fonts:
    #     - lib/assets/fonts
    # ```
    #
    # 判断flr的assets配置合法的标准是：assets配置的resource_dir数组中的legal_resource_dir数量大于0。
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # assets_legal_resource_dir_array = ["~/path/to/flutter_r_demo/lib/assets/images", "~/path/to/flutter_r_demo/lib/assets/texts"]
    # fonts_legal_resource_dir_array = ["~/path/to/flutter_r_demo/lib/assets/fonts"]
    # illegal_resource_dir_array = ["~/path/to/flutter_r_demo/to/non-existed_folder"]
    #
    def self.check_flr_assets_is_legal(flutter_project_dir, flr_config)
      core_version = flr_config["core_version"]
      dartfmt_line_length = flr_config["dartfmt_line_length"]
      assets_resource_dir_array = flr_config["assets"]
      fonts_resource_dir_array = flr_config["fonts"]

      if assets_resource_dir_array.is_a?(Array) == false
        assets_resource_dir_array = []
      end

      if fonts_resource_dir_array.is_a?(Array) == false
        fonts_resource_dir_array = []
      end

      # 移除非法的 resource_dir（nil，空字符串，空格字符串）
      assets_resource_dir_array = assets_resource_dir_array - [nil, "", " "]
      fonts_resource_dir_array = fonts_resource_dir_array - [nil, "", " "]
      # 过滤重复的 resource_dir
      assets_resource_dir_array = assets_resource_dir_array.uniq
      fonts_resource_dir_array = fonts_resource_dir_array.uniq


      # 筛选合法的和非法的resource_dir
      assets_legal_resource_dir_array = []
      fonts_legal_resource_dir_array = []
      illegal_resource_dir_array = []

      assets_resource_dir_array.each do |relative_resource_dir|
        resource_dir = flutter_project_dir + "/" + relative_resource_dir
        if File.exist?(resource_dir) == true
          assets_legal_resource_dir_array.push(resource_dir)
        else
          illegal_resource_dir_array.push(resource_dir)
        end
      end

      fonts_resource_dir_array.each do |relative_resource_dir|
        resource_dir = flutter_project_dir + "/" + relative_resource_dir
        if File.exist?(resource_dir) == true
          fonts_legal_resource_dir_array.push(resource_dir)
        else
          illegal_resource_dir_array.push(resource_dir)
        end
      end

      legal_resource_dir_array = assets_legal_resource_dir_array + fonts_legal_resource_dir_array
      if legal_resource_dir_array.length <= 0

        if illegal_resource_dir_array.length > 0
          message = "[!]: warning, found the following resource directory which is not existed: ".warning_style
          illegal_resource_dir_array.each do |resource_dir|
            message = message + "\n" + "  - #{resource_dir}".warning_style
          end
          puts(message)
          puts("")
        end

        message = <<-MESSAGE
#{"[x]: have no valid resource directories configuration in pubspec.yaml".error_style}
#{"[*]: please manually configure the resource directories to fix it, for example: ".tips_style}

    #{"flr:".tips_style}
      #{"core_version: #{core_version}".tips_style}
      #{"dartfmt_line_length: #{dartfmt_line_length}".tips_style}
      #{"# config the image and text resource directories that need to be scanned".tips_style}
      #{"assets:".tips_style}
        #{"- lib/assets/images".tips_style}
        #{"- lib/assets/texts".tips_style}
      #{"# config the font resource directories that need to be scanned".tips_style}
      #{"fonts:".tips_style}
        #{"- lib/assets/fonts".tips_style}
        MESSAGE

        raise(message)
      end

      resource_dir_result_tuple = [assets_legal_resource_dir_array, fonts_legal_resource_dir_array, illegal_resource_dir_array]
      return resource_dir_result_tuple
    end
  end
end


