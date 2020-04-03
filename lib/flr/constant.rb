module Flr
  # Flr支持的非SVG类图片文件类型
  NON_SVG_IMAGE_FILE_TYPES = %w(.png .jpg .jpeg .gif .webp .icon .bmp .wbmp)
  # Flr支持的SVG类图片文件类型
  SVG_IMAGE_FILE_TYPES = %w(.svg)
  # Flr支持的图片文件类型
  IMAGE_FILE_TYPES = NON_SVG_IMAGE_FILE_TYPES + SVG_IMAGE_FILE_TYPES
  # Flr支持的文本文件类型
  TEXT_FILE_TYPES = %w(.txt .json .yaml .xml)
  # Flr支持的字体文件类型
  FONT_FILE_TYPES = %w(.ttf .otf .ttc)

  # Flr优先考虑的非SVG类图片文件类型
  PRIOR_NON_SVG_IMAGE_FILE_TYPE = ".png"
  # Flr优先考虑的SVG类图片文件类型
  PRIOR_SVG_IMAGE_FILE_TYPE = ".svg"
  # Flr优先考虑的文本文件类型
  # 当前值为 ".*"， 意味所有文本文件类型的优先级都一样
  PRIOR_TEXT_FILE_TYPE = ".*"
  # Flr优先考虑的字体文件类型
  # 当前值为 ".*"， 意味所有文本文件类型的优先级都一样
  PRIOR_FONT_FILE_TYPE = ".*"

  # dartfmt工具的默认行长
  DARTFMT_LINE_LENGTH = 80
end
