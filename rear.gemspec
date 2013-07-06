# encoding: UTF-8

version = '0.1.2'
Gem::Specification.new do |s|

  s.name = 'rear'
  s.version = version
  s.authors = ['Walter Smith']
  s.email = ['waltee.smith@gmail.com']
  s.homepage = 'https://github.com/espresso/rear'
  s.summary = 'rear-%s' % version
  s.description = 'ORM-agnostic CRUDifier for Espresso Framework'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'e',    '>= 0.4.10'
  s.add_dependency 'el',   '>= 0.4.10'
  s.add_dependency 'slim', '>= 2.0'

  s.add_development_dependency 'rake',     '>= 10'
  s.add_development_dependency 'specular', '>= 0.2.2'
  s.add_development_dependency 'sonar',    '>= 0.2.0'
  s.add_development_dependency 'nokogiri',     '~> 1.6'
  s.add_development_dependency 'activerecord', '~> 3.2'
  s.add_development_dependency 'sqlite3',      '~> 1.3'
  s.add_development_dependency 'data_mapper',  '~> 1.2'
  s.add_development_dependency 'dm-sqlite-adapter', '~> 1.2'
  s.add_development_dependency 'sequel'
  s.add_development_dependency 'bundler'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  s.executables = ['rear']
  s.licenses = ['MIT']
end
