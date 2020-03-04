## Flr Cli Deployment Check List

1. 确定Deployment的版本号：X.Y.Z
1. 编辑`lib/flr/version.rb`，更新`VERSION`：

	```ruby
	module Flr
  		VERSION = "X.Y.Z"
  		...
	end
	```
1.  更新CHANGELOG.md
1. 在项目根目录下运行脚本更新Gemfile：`bundle exec ./bin/flr`
1. 提交当前变更到git
1. 在项目根目录下运行脚本打包Gem：`gem build flr.gemspec`
1. 本地安装Flr进行测试：`sudo gem install flr-x.y.z.gem`
1. 若无问题，则发布Flr到RubyGems市场

## Publish Flr Cli

1. 在项目根目录下运行脚本发布Flr：`gem push flr-x.y.z.gem`

## Other

其他知识点：
 
- 从RubyGems市场下架指定版本的Flr：`gem yank flr -v x.y.z`
