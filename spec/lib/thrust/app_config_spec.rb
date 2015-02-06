require 'spec_helper'

describe Thrust::AppConfig do
  it 'exposes the ios sim binary' do
    config = Thrust::AppConfig.new('ios_sim_path' => 'ios-sim-binary')
    expect(config.ios_sim_path).to eq('ios-sim-binary')
  end

  it 'exposes the spec_targets when passed in' do
    spec_targets = {'foo' => {'type' => 'bundle'}}
    config = Thrust::AppConfig.new('spec_targets' => spec_targets)
    expect(config.spec_targets['foo'].type).to eq('bundle')
  end

  it 'returns an empty set when spec_targets are not passed in' do
    config = Thrust::AppConfig.new({})
    expect(config.spec_targets).to eq({})
  end

  it 'exposes the project name' do
    config = Thrust::AppConfig.new('project_name' => 'project-name')
    expect(config.project_name).to eq('project-name')
  end

  it 'exposes the thrust version as a string' do
    config = Thrust::AppConfig.new('thrust_version' => 1.2)
    expect(config.thrust_version).to eq('1.2')
  end

  it 'exposes the workspace name' do
    config = Thrust::AppConfig.new('workspace_name' => 'workspace-name')
    expect(config.workspace_name).to eq('workspace-name')
  end

  it 'exposes the deployment targets' do
    deployment_targets = {'foo' => {'distribution_list' => 'Cowboy Coders'}}
    config = Thrust::AppConfig.new('deployment_targets' => deployment_targets)
    expect(config.deployment_targets['foo'].distribution_list).to eq('Cowboy Coders')
  end

  it 'returns an empty set when deployment_targets are not passed in' do
    config = Thrust::AppConfig.new({})
    expect(config.deployment_targets).to eq({})
  end

  it 'exposes the app name' do
    config = Thrust::AppConfig.new({'app_name' => 'my-cool-app'})
    expect(config.app_name).to eq('my-cool-app')
  end

  it 'exposes the distribution_certificate' do
    config = Thrust::AppConfig.new({'distribution_certificate' => 'some-cert'})
    expect(config.distribution_certificate).to eq('some-cert')
  end

  it 'exposes the path to the .xcodeproj file' do
    config = Thrust::AppConfig.new({'path_to_xcodeproj' => '../foo/bar.xcodeproj'})
    expect(config.path_to_xcodeproj).to eq('../foo/bar.xcodeproj')
  end

  it 'exposes the fully expanded spec directories' do
    config = Thrust::AppConfig.new({'spec_directories' => ['SpecDirA', 'SpecDirB/SubDirectory', 'SpecDirB/../SpecDirC'], 'project_root' => '/project_root'})
    expect(config.spec_directories).to eq([
                                              '/project_root/SpecDirA',
                                              '/project_root/SpecDirB/SubDirectory',
                                              '/project_root/SpecDirC',
                                          ])

  end

  it 'exposes the build directory' do
    config = Thrust::AppConfig.new({'build_directory' => '/build/dir'})
    expect(config.build_directory).to eq('/build/dir')
  end

  it 'exposes the project root' do
    config = Thrust::AppConfig.new({'project_root' => '/project/root'})
    expect(config.project_root).to eq('/project/root')
  end
end
