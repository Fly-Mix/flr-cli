require 'yaml'
require 'flr/constant'

module Flr

  # 资源文件相关的工具类方法
  class FileUtil

    # get_cur_flutter_project_root_dir -> String
    #
    # 获取当前flutter工程的根目录
    #
    def self.get_cur_flutter_project_root_dir
      flutter_project_root_dir = "#{Pathname.pwd}"
      return flutter_project_root_dir
    end

    # get_pubspec_file_path -> String
    #
    # 获取当前flutter工程的pubspec.yaml文件的路径
    #
    def self.get_pubspec_file_path
      flutter_project_root_dir = self.get_cur_flutter_project_root_dir
      file_path = flutter_project_root_dir + "/pubspec.yaml"
      return file_path
    end

    # load_pubspec_config_from_file -> Hash
    #
    # 读取pubspec.yaml到pubspec_config
    # 若读取成功，返回一个Hash对象pubspec_config
    # 若读取失败，则抛出异常
    #
    def self.load_pubspec_config_from_file(pubspec_file_path)
      begin
        pubspec_file = File.open(pubspec_file_path, 'r')
        pubspec_config = YAML.load(pubspec_file)
      rescue YAML::SyntaxError => e
        puts("YAML Syntax Error: #{e}".error_style)
        puts("")

        message = <<-MESSAGE

#{"[x]: pubspec.yaml is damaged with syntax error".error_style}
#{"[*]: please correct the pubspec.yaml file at #{pubspec_file_path}".tips_style}
        MESSAGE

        raise(message)
      ensure
        pubspec_file.close
      end

      return pubspec_config
    end

    # dump_pubspec_config_to_file -> true
    #
    # 保存pubspec_config到pubspec.yaml
    #
    def self.dump_pubspec_config_to_file(pubspec_config, pubspec_file_path)
      pubspec_file = File.open(pubspec_file_path, 'w')
      yaml_content = pubspec_config.to_yaml

      # Because pubspec.yaml is only one document remove,
      # and I want to shortcut it,
      # so I choose to remove three dashes (“---”).
      #
      # To get the details about three dashes (“---”)
      # see: https://yaml.org/spec/1.2/spec.html#id2760395
      #
      document_separate_maker = "---\n"
      regx = /\A#{document_separate_maker}/
      if yaml_content =~ regx
        yaml_content[document_separate_maker] = ""
      end

      pubspec_file.write(yaml_content)
      pubspec_file.close
      return true
    end

    # is_legal_resource_file??(file) -> true or false
    #
    # 判断当前资源文件是否合法
    #
    # 判断资源文件合法的标准是：
    # 其file_basename_no_extension 由字母（a-z、A-Z）、数字（0-9）、其他合法字符（'_', '+', '-', '.', '·', '!', '@', '&', '$', '￥'）组成
    #
    # === Examples
    # good_file = "lib/assets/images/test.png"
    # bad_file = "lib/assets/images/~.png"
    # is_legal_resource_file?(good_file) -> true
    # is_legal_resource_file?(bad_file) -> false
    #
    def self.is_legal_resource_file?(file)
      file_basename_no_extension = File.basename(file, ".*")
      regx = /^[a-zA-Z0-9_\+\-\.·!@&$￥]+$/

      if file_basename_no_extension =~ regx
        return true
      else
        return false
      end
    end

    # find_image_files(resource_dir)  ->  image_file_result_tuple
    #
    # v1.0.0: 扫描指定的资源目录和其第1级子目录，查找所有图片文件
    # v1.1.0: 放开图片资源扫描目录层级限制，以支持不标准的资源组织目录结构
    # 返回图片文件结果二元组 image_file_result_tuple
    # image_file_result_tuple = [legal_image_file_array, illegal_image_file_array]
    #
    # 判断文件合法的标准参考 self.is_legal_resource_file? 方法
    #
    # === Examples
    # resource_dir = "lib/assets/images"
    # legal_image_file_array = ["lib/assets/images/test.png", "lib/assets/images/2.0x/test.png"]
    # illegal_image_file_array = ["lib/assets/images/~.png"]
    #
    def self.find_image_files(resource_dir)
      legal_image_file_array = []
      illegal_image_file_array = []

      pattern_file_types = Flr::IMAGE_FILE_TYPES.join(",")
      # dir/*{.png.,.jpg} : 查找当前目录的指定类型文件
      # dir/*/*{.png.,.jpg}: 查找当前目录的第1级子目录的指定类型文件
      # dir/**/*{.png.,.jpg}:  查找当前目录和其所有子目录的指定类型文件
      Dir.glob(["#{resource_dir}/**/*{#{pattern_file_types}}"]).each do |file|
        if is_legal_resource_file?(file)
          legal_image_file_array.push(file)
        else
          illegal_image_file_array.push(file)
        end
      end

      image_file_result_tuple = [legal_image_file_array, illegal_image_file_array]
      return image_file_result_tuple
    end

    # find_text_files(resource_dir)  ->  text_file_result_tuple
    #
    # 扫描指定的资源目录和其所有层级的子目录，查找所有文本文件
    # 返回文本文件结果二元组 text_file_result_tuple
    # text_file_result_tuple = [legal_text_file_array, illegal_text_file_array]
    #
    # 判断文件合法的标准参考 self.is_legal_resource_file? 方法
    #
    # === Examples
    # resource_dir = "lib/assets/jsons"
    # legal_text_file_array = ["lib/assets/jsons/city.json", "lib/assets/jsons/mock/city.json"]
    # illegal_text_file_array = ["lib/assets/jsons/~.json"]
    #
    def self.find_text_files(resource_dir)
      legal_text_file_array = []
      illegal_text_file_array = []

      pattern_file_types =  Flr::TEXT_FILE_TYPES.join(",")
      # dir/**/*{.json.,.yaml} : 查找当前目录和其所有子目录的指定类型文件
      Dir.glob(["#{resource_dir}/**/*{#{pattern_file_types}}"]).each do |file|
        if is_legal_resource_file?(file)
          legal_text_file_array.push(file)
        else
          illegal_text_file_array.push(file)
        end
      end

      text_file_result_tuple = [legal_text_file_array, illegal_text_file_array]
      return text_file_result_tuple
    end

    # find_top_child_dirs(resource_dir) -> top_child_dir_array
    #
    # 扫描指定的资源目录，返回其所有第一级子目录
    #
    # === Examples
    # top_child_dir_array = ["lib/assets/fonts/Amiri", "lib/assets/fonts/Open_Sans"]
    #
    def self.find_top_child_dirs(resource_dir)
      top_child_dir_array = []

      Dir.glob(["#{resource_dir}/*"]).each do |file|
        if File.directory?(file)
          top_child_dir_array.push(file)
        end
      end

      return top_child_dir_array
    end

    # find_font_files_in_font_family_dir(font_family_dir)  ->  font_file_result_tuple
    #
    # 扫描指定的字体家族目录和其所有层级的子目录，查找所有字体文件
    # 返回字体文件结果二元组 font_file_result_tuple
    # font_file_result_tuple = [legal_font_file_array, illegal_font_file_array]
    #
    # 判断文件合法的标准参考 self.is_legal_resource_file? 方法
    #
    # === Examples
    # font_family_dir = "lib/assets/fonts/Amiri"
    # legal_font_file_array = ["lib/assets/fonts/Amiri/Amiri-Regular.ttf", "lib/assets/fonts/Amiri/Amiri-Bold.ttf"]
    # illegal_font_file_array = ["lib/assets/fonts/Amiri/~.ttf"]
    #
    def self.find_font_files_in_font_family_dir(font_family_dir)
      legal_font_file_array = []
      illegal_font_file_array = []

      pattern_file_types =  Flr::FONT_FILE_TYPES.join(",")
      # dir/**/*{.ttf.,.ott} : 查找当前目录和其所有子目录的指定类型文件
      Dir.glob(["#{font_family_dir}/**/*{#{pattern_file_types}}"]).each do |file|
        if is_legal_resource_file?(file)
          legal_font_file_array.push(file)
        else
          illegal_font_file_array.push(file)
        end
      end

      font_file_result_tuple = [legal_font_file_array, illegal_font_file_array]
      return font_file_result_tuple
    end

  end

end
