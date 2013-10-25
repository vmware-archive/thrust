class CodesignWrapper
  def call(identity, resource_rules_path, app_path)
    `/usr/bin/codesign -f -s "#{identity}" --resource-rules "#{resource_rules_path}" "#{app_path}"`
  end
end