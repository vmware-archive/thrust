module Thrust
  module Tasks
    class Trim
      def initialize(executor = Thrust::Executor.new)
        @executor = executor
      end

      def run
        awk_statement = <<-AWK
        {
          if ($1 == "RM" || $1 == "R")
            print $4;
          else if ($1 != "D")
            print $2;
        }
        AWK

        awk_statement.gsub!(%r{\s+}, " ")

        @executor.system_or_exit %Q[git status --porcelain | awk '#{awk_statement}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
      end
    end
  end
end
