Pod::Spec.new do |s|
 s.name = 'TYPDFReader'
 s.version = '2.8.7'
 s.license = 'MIT'
 s.summary = 'The open source PDF file reader/viewer for iOS.'
 s.homepage = 'https://github.com/chengdonghai/Reader'
 s.authors = { "Donghai Cheng" => "dong723232@gmail.com" }
 s.source = { :git => 'https://github.com/chengdonghai/Reader.git', :tag => "v#{s.version}" }
 s.platform = :ios
 s.ios.deployment_target = '6.0'
 s.source_files = 'Sources/**/*.{h,m}'
 s.resources = 'Graphics/TYReader-*.png'
 s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'ImageIO', 'MessageUI'
 s.requires_arc = true
end
