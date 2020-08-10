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

  option :preserve_tokens,
    long: '--[no-]preserve-tokens',
    boolean: true,
    default: false,
    description: 'Stop translating and leave tokens'

  def run
    parse_options

    yaml = YAML.load_file(File.expand_path(config[:config]))

    config[:patterns] = (yaml['patterns'] || {}).to_a
    config[:excludes] = yaml['excludes'] || []
    config[:deletes] = yaml['deletes'] || []

    Dir.chdir(config[:repo]) do
      FileUtils.rm_rf(config[:deletes]) unless config[:deletes].empty?
      translate_filenames
      translate_contents
    end

    word, translate = config[:patterns][config[:steps] - 1]
    puts "Last applied: #{word} -> #{translate}."
  end

  def translate_filenames
    each_repo_file do |file|
      new_file = file.dup

      # We must tokenize all pattern BEFORE replace it with new text
      each_dict_pattern do |word, translate, token|
        new_file.gsub!(word, token)
      rescue e
        puts "Error translating: #{word}"
        puts e
      end

      # After all tokens have been generated it is time to translate
      each_dict_pattern do |word, translate, token|
        new_file.gsub!(token, translate)
      rescue e
        puts "Error translating: #{translate}"
        puts e
      end

      next if new_file == file

      puts "Binary file renamed: #{file} -> #{new_file}" unless FileMagic.fm.file(file) =~ /text/

      FileUtils.mkdir_p(File.dirname(new_file))
      `git mv "#{file}" "#{new_file}"`
    end
  end

  def translate_contents
    each_repo_file do |file|
      next if File.symlink?(file)

      file_content = File.read(file)
      hash = file_content.hash

      # We must tokenize all pattern BEFORE replace it with new text
      each_dict_pattern do |word, translate, token|
        file_content.gsub!(word, token)
       rescue e
        puts "Error translating: #{word}"
        puts e
      end

      # After all tokens have been generated it is time to translate
      each_dict_pattern do |word, translate, token|
        file_content.gsub!(token, translate)
       rescue e
        puts "Error translating: #{translate}"
        puts e
      end

      next if hash == file_content.hash

      puts "Binary content replaced: #{file}" unless FileMagic.fm.file(file) =~ /text/
      File.write(file, file_content)
    end
  end

  def each_repo_file
    Dir.glob('**/*', File::FNM_DOTMATCH) do |file|
      next if file =~ %r|^.git/|
      next if File.directory?(file)

      next if config[:excludes].include?(file)

      yield file
    end
  end

  def each_dict_pattern
    config[:patterns].each_with_index do |pattern, index|
      return if index >= config[:steps]

      token = "TOKEN_%07d" % index

      # For debug preserve tokens otherwise - replace
      if config[:preserve_tokens]
        yield(pattern[0], token, token)
      else
        yield(pattern[0], pattern[1], token)
      end
    end
  end
end

ForkMan.new.run
