# encoding: UTF-8

require 'fileutils'

module GeneratedAssets
  class Manifest
    attr_reader :app, :prefix, :entries
    attr_reader :before_hooks, :after_hooks

    def initialize(app, prefix)
      @app = app
      @prefix = prefix
      @entries = []
      @before_hooks = []
      @after_hooks = []
    end

    def add(logical_path, options = {}, &block)
      entries << Entry.new(logical_path, block, options)
    end

    def apply!
      before_hooks.each(&:call)

      write_files
      add_precompile_paths

      after_hooks.each(&:call)
    end

    def before_apply(&block)
      before_hooks << block
    end

    def after_apply(&block)
      after_hooks << block
    end

    private

    def write_files
      ensure_prefix_dir_exists unless entries.empty?

      entries.each do |entry|
        entry.write_to(prefix)
      end
    end

    def ensure_prefix_dir_exists
      FileUtils.mkdir_p(prefix)
    end

    def add_precompile_paths
      entries.each do |entry|
        if entry.precompile?
          app.config.assets.precompile << remove_extra_extensions(
            entry.logical_path
          )
        end
      end
    end

    def remove_extra_extensions(path)
      until File.extname(path).empty?
        ext = File.extname(path)
        path = path.chomp(ext)
      end

      "#{path}#{ext}"
    end
  end
end
