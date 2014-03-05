Pod::Spec.new do |spec|
  spec.name             = 'MGSplitViewController'
  spec.version          = '0.1.0'
  spec.license          = { :type => 'BSD with attribution' }
  spec.homepage         = 'https://github.com/aaronbrethorst/MGSplitViewController'
  spec.authors          = 'Matt Gemmell', 'Aaron Brethorst', 'Paul Nicholson'
  spec.summary          = 'A flexible, advanced split-view controller for iPad developers.'
  spec.source           =  { :git => 'https://github.com/aaronbrethorst/MGSplitViewController.git' }
  spec.source_files     = 'Classes/MGSplit{Corners,Divider,ViewController}*.{h,m}'
  spec.platform     = :ios, '6.0'
  spec.requires_arc     = true
end
