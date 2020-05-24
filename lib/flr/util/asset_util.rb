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
    #   倍率变体目录特征可使用此正则来判断：“^((0\.[0-9]+)|([1-9]+[0-9]*(\.[0-9]+)?))[x]$”；
    #   倍率变体目录名称示例：“0.5x”、“1.5x”、“2.0x”、“3.0x”，“2x”、“3x”；
    #
    def self.is_asset_variant?(legal_resource_file)

      if FileUtil.is_non_svg_image_resource_file?(legal_resource_file)
        dirname = File.dirname(legal_resource_file)
        parent_dir_name = File.basename(dirname)

        ratio_regex = /^((0\.[0-9]+)|([1-9]+[0-9]*(\.[0-9]+)?))[x]$/
        if parent_dir_name =~ ratio_regex
          return true
        end
      end

      return false
    end

    # is_image_asset?(asset) -> true or false
    #
    # 判断当前资产是不是图片类资产
    #
    # === Examples
    #
    # === Example-1
    # asset = "packages/flutter_r_demo/assets/images/test.png"
    # @return true
    #
    # === Example-2
    # asset = "assets/images/test.png"
    # @return true
    #
    def self.is_image_asset?(asset)
      file_extname = File.extname(asset).downcase

      if Flr::IMAGE_FILE_TYPES.include?(file_extname)
        return true;
      end

      return false
    end

    # is_package_asset?(asset) -> true or false
    #
    # 判断当前资产是不是package类资产
    #
    # === Examples
    #
    # === Example-1
    # asset = "packages/flutter_r_demo/assets/images/test.png"
    # @return true
    #
    # === Example-2
    # asset = "assets/images/test.png"
    # @return false
    #
    def self.is_package_asset?(asset)
      package_prefix = "packages/"
      if asset =~ /\A#{package_prefix}/
        return true
      end

      return false
    end

    # is_specified_package_asset?(package_name, asset) -> true or false
    #
    # 判断当前资产是不是指定的package的资产
    #
    # === Examples
    # package_name = "flutter_r_demo"
    #
    # === Example-1
    # asset = "packages/flutter_r_demo/assets/images/test.png"
    # @return true
    #
    # === Example-2
    # asset = "packages/hello_demo/assets/images/test.png"
    # @return false
    #
    def self.is_specified_package_asset?(package_name, asset)
      specified_package_prefix = "packages/" + package_name + "/"
      if asset =~ /\A#{specified_package_prefix}/
        return true
      end

      return false
    end

    # get_main_resource_file(flutter_project_dir, package_name, asset) -> main_resource_file
    #
    # 获取指定flutter工程的asset对应的主资源文件
    # 注意：主资源文件不一定存在，比如图片资产可能只存在变体资源文件
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    #
    # === Example-1
    # asset = "packages/flutter_r_demo/assets/images/test.png"
    # main_resource_file = "~/path/to/flutter_r_demo/lib/assets/images/test.png"
    #
    # === Example-2
    # asset = "assets/images/test.png"
    # main_resource_file = "~/path/to/flutter_r_demo/assets/images/test.png"
    #
    def self.get_main_resource_file(flutter_project_dir, package_name, asset)
      if is_specified_package_asset?(package_name, asset)
        specified_package_prefix = "packages/" + package_name + "/"

        # asset: packages/flutter_r_demo/assets/images/test.png
        # to get implied_relative_resource_file: lib/assets/images/test.png
        implied_relative_resource_file = asset.dup
        implied_relative_resource_file[specified_package_prefix] = ""
        implied_relative_resource_file = "lib/" + implied_relative_resource_file

        # main_resource_file:  ~/path/to/flutter_r_demo/lib/assets/images/test.png
        main_resource_file = flutter_project_dir + "/" + implied_relative_resource_file
        return main_resource_file
      else
        # asset: assets/images/test.png
        # main_resource_file:  ~/path/to/flutter_r_demo/assets/images/test.png
        main_resource_file = flutter_project_dir + "/" + asset
        return main_resource_file
      end
    end

    # is_asset_existed?(flutter_project_dir, package_name, asset) -> true or false
    #
    # 判断指定flutter工程的asset是不是存在；存在的判断标准是：asset需要存在对应的资源文件
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    #
    # === Example-1
    # asset = "packages/flutter_r_demo/assets/images/test.png"
    # @return true
    #
    # === Example-2
    # asset = "packages/flutter_r_demo/404/not-existed.png"
    # @return false
    #
    def self.is_asset_existed?(flutter_project_dir, package_name, asset)
      # 处理指定flutter工程的asset
      # 1. 获取asset对应的main_resource_file
      # 2. 若main_resource_file是非SVG类图片资源文件，判断asset是否存在的标准是：主资源文件或者至少一个变体资源文件存在
      # 3. 若main_resource_file是SVG类图片资源文件或者其他资源文件，判断asset是否存在的标准是：主资源文件存在
      #
      main_resource_file = get_main_resource_file(flutter_project_dir, package_name, asset)
      if FileUtil.is_non_svg_image_resource_file?(main_resource_file)
        if File.exist?(main_resource_file)
          return true
        end

        file_name = File.basename(main_resource_file)
        file_dir = File.dirname(main_resource_file)
        did_find_variant_resource_file = false
        Dir.glob(["#{file_dir}/*/#{file_name}"]).each do |file|
          if is_asset_variant?(file)
            did_find_variant_resource_file = true
          end
        end

        if did_find_variant_resource_file
          return true
        end
      else
        if File.exist?(main_resource_file)
          return true
        end
      end

      return false
    end

    # generate_main_asset(flutter_project_dir, package_name, legal_resource_file) -> main_asset
    #
    # 为当前资源文件生成 main_asset
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    #
    # === Example-1
    # legal_resource_file = "~/path/to/flutter_r_demo/lib/assets/images/test.png"
    # main_asset = "packages/flutter_r_demo/assets/images/test.png"
    #
    # === Example-2
    # legal_resource_file = "~/path/to/flutter_r_demo/lib/assets/images/3.0x/test.png"
    # main_asset = "packages/flutter_r_demo/assets/images/test.png"
    #
    # === Example-3
    # legal_resource_file = "~/path/to/flutter_r_demo/lib/assets/texts/3.0x/test.json"
    # main_asset = "packages/flutter_r_demo/assets/texts/3.0x/test.json"
    #
    # === Example-3
    # legal_resource_file = "~/path/to/flutter_r_demo/lib/assets/fonts/Amiri/Amiri-Regular.ttf"
    # main_asset = "packages/flutter_r_demo/fonts/Amiri/Amiri-Regular.ttf"
    #
    # === Example-4
    # legal_resource_file = "~/path/to/flutter_r_demo/assets/images/test.png"
    # main_asset = "assets/images/test.png"
    #
    # === Example-5
    # legal_resource_file = "~/path/to/flutter_r_demo/assets/images/3.0x/test.png"
    # main_asset = "assets/images/test.png"
    #
    def self.generate_main_asset(flutter_project_dir, package_name, legal_resource_file)
      # legal_resource_file: ~/path/to/flutter_r_demo/lib/assets/images/3.0x/test.png
      # to get main_resource_file: ~/path/to/flutter_r_demo/lib/assets/images/test.png
      main_resource_file = legal_resource_file
      if is_asset_variant?(legal_resource_file)
        # test.png
        file_basename = File.basename(legal_resource_file)
        # ~/path/to/flutter_r_demo/lib/assets/images/3.0x
        file_dir = File.dirname(legal_resource_file)
        # ~/path/to/flutter_r_demo/lib/assets/images
        main_resource_file_dir = File.dirname(file_dir)
        # ~/path/to/flutter_r_demo/lib/assets/images/test.png
        main_resource_file = main_resource_file_dir + "/" + file_basename
      end

      # main_resource_file:  ~/path/to/flutter_r_demo/lib/assets/images/test.png
      # to get main_relative_resource_file: lib/assets/images/test.png
      flutter_project_dir_prefix = "#{flutter_project_dir}/"
      main_relative_resource_file = main_resource_file
      if main_relative_resource_file =~ /\A#{flutter_project_dir_prefix}/
        main_relative_resource_file["#{flutter_project_dir_prefix}"] = ""
      end

      # 判断 main_relative_resource_file 是不是 implied_resource_file 类型
      # implied_resource_file 的定义是：放置在 "lib/" 目录内 resource_file
      # 具体实现是：main_relative_resource_file 的前缀若是 "lib/" ，则其是 implied_resource_file 类型；
      #
      # implied_relative_resource_file 生成 main_asset 的算法是： main_asset = "packages/#{package_name}/#{asset_name}"
      # non-implied_relative_resource_file 生成 main_asset 的算法是： main_asset = "#{asset_name}"
      #
      lib_prefix = "lib/"
      if main_relative_resource_file =~ /\A#{lib_prefix}/
        # main_relative_resource_file: lib/assets/images/test.png
        # to get asset_name: assets/images/test.png
        asset_name = main_relative_resource_file
        asset_name[lib_prefix] = ""

        main_asset = "packages/#{package_name}/#{asset_name}"
        return main_asset
      else
        # main_relative_resource_file: assets/images/test.png
        # to get asset_name: assets/images/test.png
        asset_name = main_relative_resource_file

        main_asset = asset_name
        return main_asset
      end
    end

    # generate_image_assets(flutter_project_dir, package_name, legal_image_file_array) -> image_asset_array
    #
    # 遍历指定资源目录下扫描找到的legal_image_file数组生成image_asset数组
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    # legal_image_file_array = ["~/path/to/flutter_r_demo/lib/assets/images/test.png", "~/path/to/flutter_r_demo/lib/assets/images/3.0x/test.png"]
    # image_asset_array = ["packages/flutter_r_demo/assets/images/test.png"]
    #
    def self.generate_image_assets(flutter_project_dir, package_name, legal_image_file_array)

      image_asset_array = []

      legal_image_file_array.each do |legal_image_file|
        image_asset = generate_main_asset(flutter_project_dir, package_name, legal_image_file)
        image_asset_array.push(image_asset)
      end

      image_asset_array.uniq!
      return image_asset_array
    end

    # generate_text_assets(flutter_project_dir, package_name, legal_text_file_array) -> text_asset_array
    #
    # 遍历指定资源目录下扫描找到的legal_text_file数组生成text_asset数组
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    # legal_text_file_array = ["~path/to/flutter_r_demo/lib/assets/jsons/test.json"]
    # text_asset_array = ["packages/flutter_r_demo/assets/jsons/test.json"]
    #
    def self.generate_text_assets(flutter_project_dir, package_name, legal_text_file_array)

      text_asset_array = []

      legal_text_file_array.each do |legal_text_file|
        text_asset = generate_main_asset(flutter_project_dir, package_name, legal_text_file)
        text_asset_array.push(text_asset)
      end

      text_asset_array.uniq!
      return text_asset_array
    end

    # generate_font_asset_configs(flutter_project_dir, package_name, legal_font_file_array) -> font_asset_config_array
    #
    # 遍历指定资源目录下扫描找到的legal_font_file数组生成font_asset_config数组
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    # legal_font_file_array = ["~path/to/flutter_r_demo/lib/assets/fonts/Amiri/Amiri-Regular.ttf"]
    # font_asset_config_array -> [{"asset": "packages/flutter_r_demo/assets/fonts/Amiri/Amiri-Regular.ttf"}]
    #
    def self.generate_font_asset_configs(flutter_project_dir, package_name, legal_font_file_array)

      font_asset_config_array = []

      legal_font_file_array.each do |legal_font_file|
        font_asset = generate_main_asset(flutter_project_dir, package_name, legal_font_file)
        font_asset_config = Hash["asset" => font_asset]
        font_asset_config_array.push(font_asset_config)
      end

      font_asset_config_array.uniq!{|config| config["asset"]}
      return font_asset_config_array
    end

    # mergeFlutterAssets(new_asset_array, old_asset_array) -> merged_asset_array
    #
    # 合并新旧2个asset数组：
    # - old_asset_array - new_asset_array = diff_asset_array，获取old_asset_array与new_asset_array的差异集合
    # - 遍历diff_asset_array，筛选合法的asset得到legal_old_asset_array；合法的asset标准是：非图片资源 + 存在对应的资源文件
    # - 按照字典序对legal_old_asset_array进行排序，并追加到new_asset_array
    # - 返回合并结果merged_asset_array
    #
    # === Examples
    # flutter_project_dir = "~/path/to/flutter_r_demo"
    # package_name = "flutter_r_demo"
    # new_asset_array = ["packages/flutter_r_demo/assets/images/test.png", "packages/flutter_r_demo/assets/jsons/test.json"]
    # old_asset_array = ["packages/flutter_r_demo/assets/htmls/test.html"]
    # merged_asset_array = ["packages/flutter_r_demo/assets/images/test.png", "packages/flutter_r_demo/assets/jsons/test.json", "packages/flutter_r_demo/assets/htmls/test.html"]
    def self.mergeFlutterAssets(flutter_project_dir, package_name, new_asset_array, old_asset_array)
      legal_old_asset_array = []

      diff_asset_array = old_asset_array - new_asset_array;
      diff_asset_array.each do |asset|
        # 若是第三方package的资源，则合并到new_asset_array
        # 引用第三方package的资源的推荐做法是：通过引用第三方package的R类来访问
        if is_package_asset?(asset)
          if is_specified_package_asset?(package_name, asset) == false
            legal_old_asset_array.push(asset)
            return
          end
        end

        # 处理指定flutter工程的asset
        # 1. 判断asset是否存在
        # 2. 若asset存在，则合并到new_asset_array
        #
        if is_asset_existed?(flutter_project_dir, package_name, asset)
          legal_old_asset_array.push(asset)
        end
      end

      legal_old_asset_array.sort!
      merged_asset_array = new_asset_array + legal_old_asset_array
      return merged_asset_array
    end

  end
end
