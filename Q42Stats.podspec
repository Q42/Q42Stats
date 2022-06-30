Pod::Spec.new do |s|
    s.name         = "Q42Stats"
    s.version      = "1.1"
    s.license      = "Commercial"
  
    s.summary      = "Collect stats."
  
    s.description  = <<-DESC
    Collect stats about availability and usage of interesting iOS features.
                     DESC
  
    s.authors           = { "Q42" => "info@q42.nl" }
    s.homepage          = "https://github.com/Q42/Q42Stats"

    s.ios.deployment_target = '12.0'
  
    s.source          = { :git => "https://github.com/Q42/Q42Stats.git", :tag => s.version }
    s.source_files    = "Sources/Q42Stats"
    s.swift_version   = "5.5"
  
  end
