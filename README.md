Thrust is a small project that contains some useful rake tasks to run cedar specs and deploy your application to TestFlight distribution lists. It will also change your default task to be 'specs'

	rake build_configuration[configuration]  # Build custom configuration
	rake build_specs                         # Build specs
	rake bump:build                          # Bumps the build
	rake bump:version:major                  # Bumps the major marketing version in (major.minor.patch)
	rake bump:version:minor                  # Bumps the minor marketing version in (major.minor.patch)
	rake bump:version:patch                  # Bumps the patch marketing version in (major.minor.patch)
	rake clean                               # Clean all targets
	rake specs                               # Run specs
	rake testflight:acceptance               # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
	rake testflight:developers               # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
	rake testflight:testers                  # Deploy build to testflight [project] team (use NOTIFY=false to prevent team notification)
	rake trim                                # Trim whitespace

# Changelog

## Version 0.1
* The 'specs' configuration has been replaced by an array of specs configurations, called 'spec_targets'. This is to allow you to specify multiple targets to be run as specs - for instance, you may wish to run a set of integration tests separately from your unit tests. Running one of these commands will clean the default build configuration list (AdHoc, Debug, Release).

* Adds 'focused_specs' and 'nof' tasks to show files with focussed specs and to remove them, respectively.

* Adds 'current_version' task to show the current build version of the app.

* Testflight deploys now prompt the user for a deployment message

* Removes adding to default tasks. This is now your responsibility - please define in your own Rakefile if you need to add to the default task. e.g.

	<code>task :default => [:specs :something_random]</code>

* Adds support for non-standard app names defined in your XCode project. These are determined by looking for the first ".app" file it can find in the build folder and basing the name off that file.

* Adds support for disabling incrementing the build number during a testflight deploy. This is via the 'increments_build_number' configuration setting under a distribution in your thrust.yml.

# Installation

(note: thrust requires ruby >= 1.9.2)

Clone this repo into a folder in your project as a submodule and create a `Rakefile`:

    git submodule add https://github.com/pivotal/thrust.git Vendor/thrust
    gem install colorize
    echo "Dir.glob('Vendor/thrust/lib/tasks/*.rake').each { |r| import r }" >> Rakefile

Next, create the configuration file, thrust.yml:

	cp [path-to-thrust]/lib/config/example.yml [project-root]/thrust.yml

then edit it to fit your project.

**Note:** replace [path-to-thrust] and [project-root] where you installed thrust and your project-root respectively
****

Now run `rake thrust:doctor` for more tips about how to properly configure your project.

### Alternate installation:
if you would prefer to install a static version of the library and are familiar with Rubygems you can install the thrust gem

Once installed you can run:

	thrust

which will copy some rake tasks from the gem into

	[project-root]/thrust/lib/tasks

it will also put a sample Yaml config file called:

	[project-root]/thrust.example.yml

you will need to rename this file to

	[project-root]/thrust.yml

and configure it for your project as you see fit.

depending on whether you have an existing **Rakefile** it create one or prompt you to adds some imports to the file.

# Upgrading
Periodically new thrust versions will require changes to your thrust.yml configuration.  Look in the ***upgrading instructions*** section below for a list of versions and how the configuration has changed.  If you need to upgrade multiple versions you may want to just re-create it from the example.yml.

Once you upgrade make sure to add/update the 'thrust_version' key in the configuration to the new version

# Misc

## Turning off git
TestFlight deployments will bump the build version of your project and by default expect to be deploying actual builds to people.  Because of this it requires you to be in a clean git repo and to be at the head of the branch you are working on.  It will also commit and push the new build version to your *origin* remote.

There are times where you are just testing things around the deploy and don't actually want to **A**: be in a clean and fully pushed branch and **B**: commit and push a version bump.  If these apply to you, *though not recommended on a regular basis* you can set an environment variable 'IGNORE_GIT' to 1 when running the testflight task. E.G.

	IGNORE_GIT=1 rake testflight:developers

## Notifying distribution list
By default the testflight deploy will notify everyone on the distribution list.  If you would prefer to not notify them then you can change the 'notify' value in your config file for that distribution list. You can also set the environment variable 'NOTIFY' to false. E.G.

	NOTIFY=false rake testflight:testers

## Upgrading Instructions
### Upgrading from *unversioned* to version 0.1
You will need to update your thrust.yml as follows. Previously, the 'specs' section was defined at the root level as:

    specs:
      configuration: Release # or whichever iOS configuration you want to run specs under
      target: Specs # Name of the spec build target
      sdk: 6.1 # SDK version to build/run the specs with
      binary: 'Specs/bin/ios-sim' # or 'Specs/bin/waxim'

It is now defined as:

    sim_binary: 'ios-sim'
    spec_targets:
      specs:
        name: Specs # Name of the spec build target
        configuration: Debug # or whichever iOS configuration you want to run specs under
        target: Specs
        sdk: 6.1
      [some_other_rake_task_name]:
        ...

*Note* that the 'binary' definition has been moved out from the specs definition, and is now a root level value called 'sim_binary'.

This will generate a rake task for every definition in the spec_targets list.

---
