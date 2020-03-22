require 'flr/string_extensions'

module Flr
  # 条件检测器，提供检测各种条件是否合法的方法
  class Checker

    # check_pubspec_file_is_existed(flutter_dir)  ->  true
    #
    # 检测当前flutter工程目录是否存在pubspec.yaml文件
    # 若存在，返回true
    # 若不存在，则抛出异常
    #
    # === Examples
    #
    # flutter_dir = "~/path/to/flutter_project"
    # Checker.check_pubspec_file_is_existed(flutter_dir)
    #
    def self.check_pubspec_file_is_existed(flutter_dir)
      pubspec_path = flutter_dir + "/pubspec.yaml"

      if File.exist?(pubspec_path) == false
        message = <<-MESSAGE
#{"[x]: #{pubspec_path} not found".error_style}
#{"[*]: please make sure pubspec.yaml is exist in #{flutter_dir}".tips_style}
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
    #   assets:
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

    # check_flr_assets_is_legal(flr_config)  ->  [[assets_legal_resource_dir_array, fonts_legal_resource_dir_array], illegal_resource_dir_array]
    #
    # 检测当前flr配置信息中的assets配置是否合法
    # 若合法，返回资源目录结果元组 resource_dir_result_tuple
    # resource_dir_result_tuple = [legal_resource_dir_result_tuple, illegal_resource_dir_array]
    # legal_resource_dir_result_tuple = [assets_legal_resource_dir_array, fonts_legal_resource_dir_array]
    # 若不合法，抛出异常
    #
    # flr的assets配置是用于配置需要flr进行扫描的资源目录，如：
    #
    # ``` yaml
    # flr:
    #   core_version: 1.0.0
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
    # assets_legal_resource_dir_array = ["lib/assets/images", "lib/assets/texts"]
    # fonts_legal_resource_dir_array = ["lib/assets/fonts"]
    # illegal_resource_dir_array = ["wrong/path/to/non-existed_folder"]
    #
    def self.check_flr_assets_is_legal(flr_config)
      core_version = flr_config["core_version"]
      assets_resource_dir_arry = flr_config["assets"]
      fonts_resource_dir_arry = flr_config["fonts"]

      if assets_resource_dir_arry.is_a?(Array) == false
        assets_resource_dir_arry = []
      end

      if fonts_resource_dir_arry.is_a?(Array) == false
        fonts_resource_dir_arry = []
      end

      # 移除非法的 resource_dir（nil，空字符串，空格字符串）
      assets_resource_dir_arry = assets_resource_dir_arry - [nil, "", " "]
      fonts_resource_dir_arry = fonts_resource_dir_arry - [nil, "", " "]
      # 过滤重复的 resource_dir
      assets_resource_dir_arry = assets_resource_dir_arry.uniq
      fonts_resource_dir_arry = fonts_resource_dir_arry.uniq


      # 筛选合法的和非法的resource_dir
      assets_legal_resource_dir_array = []
      fonts_legal_resource_dir_array = []
      illegal_resource_dir_array = []

      assets_resource_dir_arry.each do |resource_dir|
        if File.exist?(resource_dir) == true
          assets_legal_resource_dir_array.push(resource_dir)
        else
          illegal_resource_dir_array.push(resource_dir)
        end
      end

      fonts_resource_dir_arry.each do |resource_dir|
        if File.exist?(resource_dir) == true
          fonts_legal_resource_dir_array.push(resource_dir)
        else
          illegal_resource_dir_array.push(resource_dir)
        end
      end

      legal_resource_dir_array = assets_legal_resource_dir_array + fonts_legal_resource_dir_array
      if legal_resource_dir_array.length <= 0
        message = <<-MESSAGE
#{"[x]: have no valid resource directories configuration in pubspec.yaml".error_style}
#{"[*]: please manually configure the resource directories to fix it, for example: ".tips_style}

    #{"flr:".tips_style}
      #{"core_version: #{core_version}".tips_style}
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

      legal_resource_dir_result_tuple = [assets_legal_resource_dir_array, fonts_legal_resource_dir_array]
      resource_dir_result_tuple = [legal_resource_dir_result_tuple, illegal_resource_dir_array]
      return resource_dir_result_tuple
    end
  end
end


