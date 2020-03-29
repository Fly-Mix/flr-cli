# 参考：https://gist.github.com/lnznt/2663516
class String
  def black
    "\e[30m#{self}\e[m"
  end

  def red
    "\e[31m#{self}\e[m"
  end

  def green
    "\e[32m#{self}\e[m"
  end

  def yellow
    "\e[33m#{self}\e[m"
  end

  def blue
    "\e[34m#{self}\e[m"
  end

  def magenta
    "\e[35m#{self}\e[m"
  end

  def cyan
    "\e[36m#{self}\e[m"
  end

  def white
    "\e[37m#{self}\e[m"
  end

  def bg_black
    "\e[40m#{self}\e[m"
  end

  def bg_red
    "\e[41m#{self}\e[m"
  end

  def bg_green
    "\e[42m#{self}\e[m"
  end

  def bg_yellow
    "\e[43m#{self}\e[m"
  end

  def bg_blue
    "\e[44m#{self}\e[m"
  end

  def bg_magenta
    "\e[45m#{self}\e[m"
  end

  def bg_cyan
    "\e[46m#{self}\e[m"
  end

  def bg_white
    "\e[47m#{self}\e[m"
  end

  def bold
    "\e[1m#{self}\e[m"
  end

  def bright
    "\e[2m#{self}\e[m"
  end

  def italic
    "\e[3m#{self}\e[m"
  end

  def underline
    "\e[4m#{self}\e[m"
  end

  def blink
    "\e[5m#{self}\e[m"
  end

  def reverse_color
    "\e[7m#{self}\e[m"
  end

  def error_style
    self.red
  end

  def warning_style
    self.yellow
  end

  def tips_style
    self.green
  end
end