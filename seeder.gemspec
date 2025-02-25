# frozen_string_literal: true

require_relative 'lib/seeder/version'

Gem::Specification.new do |spec|
  spec.name = 'seeder'
  spec.version = Seeder::VERSION
  spec.authors = ['Pavel Rozhkov']
  spec.email = ['pavel.r@beda.software']

  spec.summary = 'summary'
  spec.description = 'description'
  spec.homepage = 'http://test.com'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'http://test.com'
  spec.metadata['changelog_uri'] = 'http://test.com'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fhir_client'
  spec.add_dependency 'thor'
end
