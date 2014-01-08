module Thrust
  class Deploy
    def initialize(out, x_code_tools = XCodeTools.new)
      @out = out
      @x_code_tools = x_code_tools
    end

    def run
      @x_code_tools.change_build_number(Git.current_commit)
      @x_code_tools.cleanly_create_ipa(sdk: 'iphoneos')

      ## zip dSYM?

      #message_file = create_deploy_notes_file

      #Testflight.upload
      #Git.reset
    end
  end
end