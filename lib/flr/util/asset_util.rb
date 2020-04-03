require 'yaml'
require 'flr/constant'

module Flr

  # 资产相关的工具类方法
  class AssetUtil

    # is_asset_variant?(legal_resource_file) -> true or false
    #
    # 判断当前的资源文件是不是资产变体（asset_variant）类型
    #
    # 判断的核心算法是：
    # - 获取资源文件的父目录；
    # - 判断父目录是否符合资产变体目录的特征
    #   资产变体映射的的资源文件要求存放在“与 main_asset 在同一个目录下的”、“符合指定特征的”子目录中；
    #   截止目前，Flutter只支持一种变体类型：倍率变体；
    #   倍率变体只适用于非SVG类图片资源；
    #   倍率变体目录特征可使用此正则来判断：“^[0-9]*\.?[0-9]+[x]$”；
    #   倍率变体目录名称示例：“2.0x”、“3.0x”，“3x”；
    #
    def self.is_asset_variant?(legal_resource_file)

      if FileUtil.is_non_svg_image_resource_file?(legal_resource_file)
        dirname = File.dirname(legal_resource_file)
        parent_dir_name = File.basename(dirname)

        ratio_regx = /^[0-9]*\.?[0-9]+[x]$/
        if parent_dir_name =~ ratio_regx
          return true
        end
      end

      return false
    end

    # generate_main_asset(legal_resource_file, package_name) -> main_asset
    #
    # 为当前资源文件生成 main_asset
    #
    # === Examples
    # === Example-1
    # legal_resource_file = "lib/assets/images/test.png"
    # package_name = "flutter_r_demo"
    # main_asset = "packages/flutter_r_demo/assets/images/test.png"
    #
    # === Example-2
    # legal_resource_file = "lib/assets/images/3.0x/test.png"
    # package_name = "flutter_r_demo"
    # main_asset = "packages/flutter_r_demo/assets/images/test.png"
    #
    # === Example-3
    # legal_resource_file = "lib/assets/texts/3.0x/test.json"
    # package_name = "flutter_r_demo"
    # main_asset = "packages/flutter_r_demo/assets/texts/3.0x/test.json"
    #
    # === Example-3
    # legal_resource_file = "lib/assets/fonts/Amiri/Amiri-Regular.ttf"
    # package_name = "flutter_r_demo"
    # main_asset = "packages/flutter_r_demo/fonts/Amiri/Amiri-Regular.ttf"
    #
    def self.generate_main_asset(legal_resource_file, package_name)
      main_asset_mapping_file = legal_resource_file

      if is_asset_variant?(legal_resource_file)
        file_basename = File.basename(legal_resource_file)
        dirname = File.dirname(legal_resource_file)
        main_asset_mapping_file_dirname = File.dirname(dirname)

        main_asset_mapping_file = "#{main_asset_mapping_file_dirname}/#{file_basename}"
      end

      implied_resource_file = main_asset_mapping_file
      if implied_resource_file.include?("lib/")
        implied_resource_file = implied_resource_file.split("lib/")[1]
      end
      main_asset = "packages/#{package_name}/#{implied_resource_file}"

      return main_asset
    end

    # generate_image_assets(legal_image_file_array, resource_dir, package_name) -> image_asset_array
    #
    # 遍历指定资源目录下扫描找到的legal_image_file数组生成image_asset数组
    #
    # === Examples
    # legal_image_file_array = ["lib/assets/images/test.png"]
    # resource_dir = "lib/assets/images"
    # implied_resource_dir = "assets/images"
    # package_name = "flutter_r_demo"
    # image_asset_array = ["packages/flutter_r_demo/assets/images/test.png"]
    #
    def self.generate_image_assets(legal_image_file_array, resource_dir, package_name)

      image_asset_array = []

      legal_image_file_array.each do |legal_image_file|
        image_asset = generate_main_asset(legal_image_file, package_name)
        image_asset_array.push(image_asset)
      end

      image_asset_array.uniq!
      return image_asset_array
    end

    # generate_text_assets(legal_text_file_array, resource_dir, package_name) -> text_asset_array
    #
    # 遍历指定资源目录下扫描找到的legal_text_file数组生成text_asset数组
    #
    # === Examples
    # legal_text_file_array = ["lib/assets/jsons/test.json"]
    # resource_dir = "lib/assets/jsons"
    # package_name = "flutter_r_demo"
    # text_asset_array = ["packages/flutter_r_demo/assets/jsons/test.json"]
    #
    def self.generate_text_assets(legal_text_file_array, resource_dir, package_name)

      text_asset_array = []

      legal_text_file_array.each do |legal_text_file|
        text_asset = generate_main_asset(legal_text_file, package_name)
        text_asset_array.push(text_asset)
      end

      text_asset_array.uniq!
      return text_asset_array
    end

    # generate_font_asset_configs(legal_font_file_array, resource_dir, package_name) -> font_asset_config_array
    #
    # 遍历指定资源目录下扫描找到的legal_font_file数组生成font_asset_config数组
    #
    # === Examples
    # legal_font_file_array = ["lib/assets/fonts/Amiri/Amiri-Regular.ttf"]
    # resource_dir = "lib/assets/fonts/Amiri"
    # package_name = "flutter_r_demo"
    # font_asset_config_array -> [{"asset": "packages/flutter_r_demo/assets/fonts/Amiri/Amiri-Regular.ttf"}]
    #
    def self.generate_font_asset_configs(legal_font_file_array, resource_dir, package_name)

      font_asset_config_array = []

      legal_font_file_array.each do |legal_font_file|
        font_asset = generate_main_asset(legal_font_file, package_name)
        font_asset_config = Hash["asset" => font_asset]
        font_asset_config_array.push(font_asset_config)
      end

      font_asset_config_array.uniq!{|config| config["asset"]}
      return font_asset_config_array
    end

  end
end
