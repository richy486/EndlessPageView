Pod::Spec.new do |spec|
  spec.name = "EndlessPageView"
  spec.version = "1.0.0"
  spec.summary = "Endless scrolling with full size cells."
  spec.homepage = "https://github.com/richy486/EndlessPageView"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Your Name" => 'richy486@gmail.com' }
  spec.social_media_url = "http://twitter.com/richy486"

  spec.platform = :ios, "9.1"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/richy486/EndlessPageView.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "EndlessPageView/**/*.{h,swift}"
end
