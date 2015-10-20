
Pod::Spec.new do |s|

  s.name         = "NTTrackingTableView"
  s.version      = "0.10.0"
  s.summary      = "NTTrackingTableView"
  s.description  = <<-DESC
Maintain scroll position when inserting/deleting rows/sections in a UITableView
                   DESC
  s.homepage     = "http://github.com/NagelTech/NTTrackingTableView"
  s.license      = "MIT"
  s.author       = { "Ethan Nagel" => "eanagel@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/NagelTech/NTTrackingTableView.git", :tag => "0.10.0" }
  s.source_files = "Classes", "Classes/**/*.{h,m}"
  s.public_header_files = "Classes/**/*.h"
  s.requires_arc = true

end
