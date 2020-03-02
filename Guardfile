# frozen_string_literal: true

guard :bundler do
  watch('Gemfile')
end

group :red_green_refactor, halt_on_fail: true do
  guard :rspec, cmd: 'bundle exec rspec', spec_paths: ['spec'] do
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  end

  guard :rubocop do
    watch(/.+\.rb$/)
    watch('config.ru')
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end
end
