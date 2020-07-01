Pod::Spec.new do |s|
    s.name         = "Q42Stats"
    s.version      = "1.0.1"
    s.license      = "Commercial"
  
    s.summary      = "Collect stats."
  
    s.description  = <<-DESC
    Collect stats about availability and usage of interesting iOS features.
                     DESC
  
    s.authors           = { "Q42" => "info@q42.nl" }
    s.homepage          = "https://github.com/Q42/Q42Stats.iOS"

    s.ios.deployment_target = '10.0'
  
    s.source          = { :git => "https://github.com/Q42/Q42Stats.iOS.git", :tag => s.version }
    s.requires_arc    = true
    s.default_subspec = "Core"
    s.swift_version   = "5.1"
  
    s.subspec "Core" do |ss|
      ss.source_files  = "Sources/Q42Stats"
    end
  
  end
