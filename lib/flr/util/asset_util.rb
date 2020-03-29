require 'yaml'
require 'flr/constant'

module Flr

  # 资产相关的工具类方法
  class AssetUtil

    # generate_image_assets(legal_image_file_array, resource_dir, package_name) -> image_asset_array
    #
    # 遍历指定资源目录下扫描找到的legal_image_file数组生成image_asset数组
    #
    # === Examples
    # legal_image_file_array = ["lib/assets/images/test.png"]
    # resource_dir = "lib/assets/images"
    # package_name = "flutter_r_demo"
    # image_asset_array = ["packages/flutter_r_demo/assets/images/test.png"]
    #
    def self.generate_image_assets(legal_image_file_array, resource_dir, package_name)

      image_asset_array = []

      # implied_resource_dir = "assets/images"
      implied_resource_dir = resource_dir
      if resource_dir.include?("lib/")
        implied_resource_dir = resource_dir.split("lib/")[1]
      end

      legal_image_file_array.each do |legal_image_file|
        file_basename = File.basename(legal_image_file)
        image_asset = "packages/#{package_name}/#{implied_resource_dir}/#{file_basename}"
        image_asset_array.push(image_asset)
      end

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
        # implied_resource_file = "assets/jsons/test.json"
        implied_resource_file = legal_text_file
        if legal_text_file.include?("lib/")
          implied_resource_file = legal_text_file.split("lib/")[1]
        end
        text_asset = "packages/#{package_name}/#{implied_resource_file}"
        text_asset_array.push(text_asset)
      end

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
        # implied_resource_file = "assets/fonts/Amiri/Amiri-Regular.ttf"
        implied_resource_file = legal_font_file
        if legal_font_file.include?("lib/")
          implied_resource_file = legal_font_file.split("lib/")[1]
        end
        font_asset = "packages/#{package_name}/#{implied_resource_file}"
        font_asset_config = Hash["asset" => font_asset]
        font_asset_config_array.push(font_asset_config)
      end

      return font_asset_config_array
    end

  end
end
