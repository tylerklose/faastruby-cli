# This is required to address a bug on the Listen gem :(
# See: https://github.com/guard/listen/issues/426
  module Listen
    class Record
      def dir_entries(rel_path)
        subtree =
          if [nil, '', '.'].include? rel_path.to_s
            tree
          else
            # tree[rel_path.to_s] ||= _auto_hash
            # puts tree[rel_path.to_s]
            # tree[rel_path.to_s]
            _sub_dir_entries(rel_path)
          end

        result = {}
        subtree.each do |key, values|
          # only get data for file entries
          result[key] = values.key?(:mtime) ? values : {}
        end
        result
      end

      def _sub_dir_entries(rel_path)
        result = {}
        tree.each do |path, meta|
          next if !path.start_with?(rel_path)
            if path == rel_path
            result.merge!(meta)
          else
            sub_path = path.sub(%r{\A#{rel_path}/?}, '')
            result[sub_path] = meta
          end
        end
        result
      end
    end
  end