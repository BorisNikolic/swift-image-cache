Pod::Spec.new do |s|
  s.name             = 'RoundsImageKit'
  s.version          = '1.0.0'
  s.summary          = 'Lightweight image downloading and caching library for iOS.'
  s.description      = <<-DESC
    RoundsImageKit is a lightweight, zero-dependency image downloading and caching
    library for iOS. It provides both SwiftUI and UIKit components with two-tier
    caching (memory + disk), automatic 4-hour TTL, request deduplication, and
    protocol-oriented architecture for full testability.
  DESC

  s.homepage         = 'https://github.com/BorisNikolic/rounds'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Boris Nikolic' => 'boris@nikolic.dev' }
  s.source           = { :git => 'https://github.com/BorisNikolic/rounds.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.9'

  s.source_files = 'Sources/RoundsImageKit/**/*.swift'
  s.frameworks = 'UIKit', 'SwiftUI', 'CryptoKit'
end
