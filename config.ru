# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'edms/analyzer'

run EDMS::Analyzer::Web
