module Thrust
  class CedarResultsParser
    def self.parse_results_for_success(results)
      results.include?("Finished") && !results.include?("FAILURE") && !results.include?("EXCEPTION")
    end
  end
end
