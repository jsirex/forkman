require 'mixlib/cli'
require 'yaml'
require 'fileutils'
require 'filemagic'

STDOUT.sync = true

class ForkMan
  include Mixlib::CLI

  banner "#{__FILE__} (options)"

  option :config,
    long: '--config YAML',
    required: true,
    proc: ->(x) { File.expand_path(x) },
    description: 'YAML-based configuration file'

  option :repo,
    long: '--repo DIR',
    required: true,
    proc: ->(x) { File.expand_path(x) },
    description: 'Directory with GIT project'

  option :steps,
    long: '--steps NUM',
    default: 1_000_000,
    proc: ->(x) { Integer(x) },
    description: 'How many patterns to apply. Default: 1_000_000'


  def run
    parse_options

    yaml = YAML.load_file(File.expand_path(config[:config]))

    config[:patterns] = yaml['patterns'].to_a
    config[:excludes] = yaml['excludes']

    Dir.chdir(config[:repo]) do
      translate_filenames
      translate_contents
    end
  end

  def translate_filenames
    each_repo_file do |file|
      new_file = file.dup

      # We must tokenize all pattern BEFORE replace it with new text
      each_dict_pattern do |word, translate, token|
        new_file.gsub!(word, token)
      end

      # After all tokens have been generated it is time to translate
      each_dict_pattern do |word, translate, token|
        new_file.gsub!(token, translate)
      end

      next if new_file == file

      puts "Binary file renamed: #{file} -> #{new_file}" unless FileMagic.fm.file(file) =~ /text/

      FileUtils.mkdir_p(File.dirname(new_file))
      `git mv "#{file}" "#{new_file}"`
    end
  end

  def translate_contents
    each_repo_file do |file|
      file_content = File.read(file)
      hash = file_content.hash

      # We must tokenize all pattern BEFORE replace it with new text
      each_dict_pattern do |word, translate, token|
        file_content.gsub!(word, token)
      end

      # After all tokens have been generated it is time to translate
      each_dict_pattern do |word, translate, token|
        file_content.gsub!(token, translate)
      end

      next if hash == file_content.hash

      puts "Binary content replaced: #{file}" unless FileMagic.fm.file(file) =~ /text/
      File.write(file, file_content)
    end
  end

  def each_repo_file
    Dir.glob('**/*', File::FNM_DOTMATCH) do |file|
      next if file =~ /^.git/
      next if File.directory?(file)

      next if config[:excludes].include?(file)

      yield file
    end
  end

  def each_dict_pattern
    config[:patterns].each_with_index do |pattern, index|
      return if index >= config[:steps]

      token = "TOKEN_%07d" % index
      yield(pattern[0], pattern[1], token)
    end
  end
end

ForkMan.new.run
