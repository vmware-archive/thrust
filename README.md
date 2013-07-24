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

# Installation

clone this repo into a folder in your project (or include as a submodule)

Add the following to your **Rakefile**:

	Dir.glob('[path-to-thrust]/lib/tasks/*.rake').each { |r| import r }

if you don't have an existing **Rakefile** in your project root go ahead and create one.

you will create a thrust configuration:

	cp [path-to-thrust]/config/example.yml [project-root]/thrust.yml

then edit it to fit your project.

**Note:** replace [path-to-thrust] and [project-root] where you installed thrust and your project-root respectively
****

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

# Misc

## Turning off git
TestFlight deployments will bump the build version of your project and by default expect to be deploying actual builds to people.  Because of this it requires you to be in a clean git repo and to be at the head of the branch you are working on.  It will also commit and push the new build version to your *origin* remote.

There are times where you are just testing things around the deploy and don't actually want to **A**: be in a clean and fully pushed branch and **B**: commit and push a version bump.  If these apply to you, *though not recommended on a regular basis* you can set an environment variable 'IGNORE_GIT' to 1 when running the testflight task. E.G.

	IGNORE_GIT=1 rake testflight:developers

## Notifying distribution list
By default the testflight deploy will notify everyone on the distribution list.  If you would prefer to not notify them then you can set the environment variable: NOTIFY to false. E.G.

	NOTIFY=false rake testflight:testers

## Contributing
Before committing changes to the repo, please build the gemspec, install the gem, and run the thrust binary

    gem build thrust.gemspec
    gem install./thrust-<version>.gem
    thrust
