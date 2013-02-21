require 'core/system/load/load'
require 'core/schema/tools/diff'
require 'core/diff/code/patch'

module Loading
  class Loader

    def load_dynamic(name, type = nil)
      @old_cache = {} if !@old_cache
      load(name, type)
      @old_cache[name] = Clone(@cache[name])
      @cache[name]
    end

    def sync_dynamic(name)
      res = false

      @old_cache = {} if !@old_cache
      return if !@old_cache[name]
      diffs = Diff.diff(@old_cache[name], @cache[name])

      filename = name.split(/\//)[-1]
      model, type = filename.split(/\./)

      if !CacheXML::check_dep(name)
        res = true
        #load changes from file
        new = _load(name, type)
        patch = Diff.diff(@old_cache[name], new)

        #merge into current model
        Patch.patch(@cache[name], patch)
        @old_cache[name] = Clone(@cache[name])
      end

      if !diffs.empty?
        res = true
        #update file
        g = load("#{type}.grammar")
        find_model(filename) do |path|
          File.open(path, "w") do |f|
            Layout::DisplayFormat.print(g, @cache[name], f)
          end
        end
        @old_cache[name] = Clone(@cache[name])
        _load(name, type)
      end

      res
    end
  end
end

if __FILE__ == $0 then
  dt1 = Load::load_dynamic("diff-test1.diff-point")
  gets

  #changing memory model
  dt1.lines['Flamingo'].pts[0].x = 100
  dt1.lines['Flamingo'].pts[0].y = 200
  Loader.sync_dynamic("diff-test1.diff-point")

end

