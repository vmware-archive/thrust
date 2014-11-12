# Thrust

# ![Thrust](thrust.png)

[![Build Status](https://travis-ci.org/pivotal/thrust.svg?branch=master)](https://travis-ci.org/pivotal/thrust)
[![Stability: 2 - unstable](http://img.shields.io/badge/stability-unstable-yellow.svg)](http://nodejs.org/api/documentation.html#documentation_stability_index)
[![Pivotal Tracker](http://img.shields.io/badge/Pivotal-Tracker-blue.svg)](https://www.pivotaltracker.com/projects/987818) (contact av@pivotallabs.com if you need access)

__Thrust__ is a small project that contains some useful rake tasks to run Cedar specs and deploy your iOS or Android application to TestFlight.

    rake autotag:list                    # Show the commit that is currently deployed to each environment
    rake clean                           # Clean all targets
    rake clean_build                     # Clean all targets (deprecated, use "clean")
    rake focused_specs                   # Print out names of files containing focused specs
    rake nof                             # Remove any focus from specs
    rake set_build_number[build_number]  # Set build number
    rake specs                           # Run specs
    rake testflight:demo                 # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
    rake testflight:production           # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
    rake testflight:staging              # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
    rake trim                            # Trim whitespace

# Installation

(Note: **Thrust** requires ruby >= 1.9.3)

**Thrust** should be installed as a gem.  It comes with an installer that will set up your Rakefile and create an example configuration file.

    gem install thrust
    thrust install

After installation, change the name of `thrust.example.yml` to `thrust.yml` and update the configuration as needed.

If you're using Thrust to run specs for an iOS app and do not have **ios-sim** installed, you can find it at the following link https://github.com/phonegap/ios-sim or follow the instructions below:
* `git clone git://github.com/phonegap/ios-sim.git`
* `rake install prefix=/usr/local/`

If you had **Thrust** previously installed as a submodule, we recommend that you remove the submodule and now use **Thrust** as a gem.  This is because there are runtime dependencies that will not get installed properly if **Thrust** is installed as a submodule.

# Changelog

## Version 0.5

* Removes support for waxsim

* Unifies configuration of Cedar Spec Suites and Cedar/iOS/OSX test bundles in thrust.yml (breaking configuration changes)

* Fixes hardcoded bundle test destination which was broken in Xcode 6+

* Allows bundles to be built for architectures specified in Xcode project (removes hardcoded ARCHS flag)

* Adds support for specifying an alternate path to ios-sim

* Adds additional options for setting build numbers when deploying to Testflight by setting the `versioning_method` key in the `thrust.yml`.  The options are:
    * 'timestamp-sha': Sets the build number to a combo of the current date and the SHA of the current commit.  e.g. '1402021234-f57bea'
    * 'commits': Sets the build number to the number of commits in the commit history
    * 'none': Does not update the build number during deploy
    * Default: When you leave the key blank, it defaults to setting the build number to the SHA of the current commit.

* Adds support for setting the Testflight api token from the command line: `TESTFLIGHT_API_TOKEN='your-api-token' rake testflight:deploy`
 
## Version 0.4

* Added support for Xcode 6 and ios-sim 3.x.  You should now specify `device_type_id` in your `thrust.yml` instead of `device`.

## Version 0.3

* **Thrust** can now build against Xcode workspaces. In your `thrust.yml` file:

  * Replace the `project_name` with a `workspace_name`.

  * For each build in your `ios_spec_targets`, include `scheme` to specify the scheme to use along with the target.

* If you are upgrading from Version 0.2 or for an example, run `thrust install` and look at the generated `thrust.example.yml`.

## Version 0.2

* **Thrust** should now be installed as a gem, not a submodule.  Running `thrust install` after installation sets up the `Rakefile` and creates an example `thrust.yml`.

* The code has been cleaned up and modularized, making it easier to add new features in the future.

* **Thrust** now supports deploying Android apps to TestFlight.  **Thrust** auto-detects whether your project is Android or iOS and will generate the appropriate rake tasks.

* The structure of `thrust.yml` has been updated, and the names of certain keys have changed to make their meaning clearer.

* All deployments are tagged using [auto_tagger](https://github.com/zilkey/auto_tagger). Run `rake autotag:list` to see which commits are deployed to each environment.

* Deploy notes can be auto-generated from commit messages. Set `note_generation_method` to `autotag` in `thrust.yml` to use this feature.

* Build numbers are no longer auto-incremented during deployment.  Instead, the build number is set to the short SHA of the commit that is being deployed.  Deployment history is managed by auto_tagger.

* You no longer have to be in sync with _origin_ to deploy to TestFlight.

## Version 0.1

* The 'specs' configuration has been replaced by an array of specs configurations, called 'spec_targets'. This is to allow you to specify multiple targets to be run as specs - for instance, you may wish to run a set of integration tests separately from your unit tests. Running one of these commands will clean the default build configuration list (AdHoc, Debug, Release).

* Adds 'focused_specs' and 'nof' tasks to show files with focused specs and to remove them, respectively.

* Adds 'current_version' task to show the current build version of the app.

* TestFlight deploys now prompt the user for a deployment message

* Removes adding to default tasks. This is now your responsibility - please define in your own Rakefile if you need to add to the default task. e.g. `task :default => [:specs :something_random]`

* Adds support for non-standard app names defined in your XCode project. These are determined by looking for the first ".app" file it can find in the build folder and basing the name off that file.

* Adds support for disabling incrementing the build number during a TestFlight deploy. This is via the 'increments_build_number' configuration setting under a distribution in your thrust.yml.

# Configuration

## Example thrust.yml for iOS

```yaml
thrust_version: 0.5
project_name: My Great Project # do not use if building with an xcode workspace
# workspace_name: My Workspace # use if building with an xcode workspace
# path_to_xcodeproj: 'App/MyApp.xcodeproj' # use if xcodeproj is not in the same directory as this yaml file. Optional.
app_name: My Great App
ios_distribution_certificate: 'Name of Distribution Signing Certificate'
#ios_sim_path: '/path/to/ios-sim' # Optional. Use to prefer a specific ios-sim binary (e.g. within project directory) over a system-installed version (homebrew)

testflight:
  api_token: 'testflight api token' # To find your App Token, follow the instructions at: http://help.testflightapp.com/customer/portal/articles/829956-what-does-the-api-token-do-
  team_token: 'testflight team token' # To find your Team Token, follow the instructions at: http://help.testflightapp.com/customer/portal/articles/829942-how-do-i-find-my-team-token-

deployment_targets:
  staging:
    distribution_list: Developers # This is the name of a TestFlight distribution list
    notify: true # Whether to notify people on the distribution list about this deployment
    note_generation_method: autotag  # If you set this value, it will auto-generate the deploy notes from the commit history. Optional.
    ios_target: MyGreatAppTarget # Name of the build target. Optional, defaults to app name.
    ios_build_configuration: Release
    ios_provisioning_search_query: 'query to find Provisioning Profile' # Otherwise, it will use the first provisioning profile in ~/Library/MobileDevice/Provisioning Profiles/
    versioning_method: 'none' # or 'timestamp-sha' or 'commits'. Leave blank to use Git commit SHAs for build numbers.

  demo:
    distribution_list: Beta Testers
    notify: true

ios_spec_targets:
  specs: # This is the name of the rake task: `rake specs`
    target: UISpecs # Name of the build target.
    scheme: Specs (My Great App) # Use if the scheme name is different from the target name.  Necessary when building in an xcode workspace.
    type: app # Spec target type: 'app' or 'bundle'. Optional, defaults to app.
    build_configuration: Debug # Name of the build configuration.
    build_sdk: iphonesimulator7.0 # SDK used to build the target. Optional, defaults to latest iphonesimulator.
    device_name: iPhone 4s # Device name as suggested by `ios-sim showdevicetypes`.
    os_version: 7.1 # OS version to run. Defaults to latest available version.
    timeout: 90 # Optional. Destination timeout defaults to 30 seconds.
  
  spec_bundle: # Example of a spec bundle configuration.
    scheme: My Great App # Use the name for the main app scheme.
    type: bundle
    build_configuration: Debug
    device_name: iPhone 4s
    os_version: 7.1

  integration: # Example of a Mac OSX target
    target: IntegrationSpecs
    scheme: IntegrationSpecs (My Great App) # Use if the scheme name is different from the target name.  Necessary when building in an xcode workspace.
    build_configuration: Release
    build_sdk: macosx
```

## Overriding config options

### Specifying API Token at deploy time

You can change the API token for a TestFlight upload with the `TESTFLIGHT_API_TOKEN` environment variable. This is useful when different members want to use their own tokens to deploy without having to change `thrust.yml` and commiting again.

### Ignoring Git during deploys

TestFlight deployment requires you to be in a clean git repo and to be at the head of your current branch. You can disable this by setting the environment variable `IGNORE_GIT=1`. **We do not recommend this.** If your git repository is not clean, deployment will discard all your uncommitted changes.

### Notifying distribution lists

Deploying to TestFlight will automatically notify all of the people on your TestFlight distribution list.  If you would prefer not to notify them, then you can change the 'notify' value in `thrust.yml` for that distribution list. You can also set the environment variable `NOTIFY` to false.

# Upgrading

Periodically new thrust versions will require changes to your `thrust.yml` configuration.  Look in the ***Upgrading Instructions*** section below for guidance on how to upgrade from the previous version.  If you need to upgrade multiple versions, you may want to just re-create your configuration from the `example.yml`.

Once you upgrade make sure to add/update the 'thrust_version' key in the configuration to the new version.


## Upgrading Instructions

### Upgrading from Version 0.1 to Version 0.2

We recommend generating a new file from the `thrust.example.yml` and then copying your project configuration into that file. Please see the comments in `thrust.example.yml` for more information.

You should remove `Dir.glob('Vendor/thrust/lib/tasks/*.rake').each { |r| import r }` from your Rakefile before running `thrust install`.

