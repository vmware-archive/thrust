require_relative '../../../lib/thrust/app_config'

describe Thrust::AppConfig do
  it 'exposes the ios sim binary' do
    config = Thrust::AppConfig.new('ios_sim_binary' => 'ios-sim-binary')
    expect(config.ios_sim_binary).to eq('ios-sim-binary')
  end

  it 'exposes the ios_spec_targets when passed in' do
    ios_spec_targets = {'foo' => {'type' => 'bundle'}}
    config = Thrust::AppConfig.new('ios_spec_targets' => ios_spec_targets)
    expect(config.ios_spec_targets['foo'].type).to eq('bundle')
  end

  it 'returns an empty set when ios_spec_targets are not passed in' do
    config = Thrust::AppConfig.new({})
    expect(config.ios_spec_targets).to eq({})
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

  it 'exposes test flight credentials' do
    config = Thrust::AppConfig.new({'testflight' => {'api_token' => 'f3eaae399310defaa'}})
    expect(config.testflight.api_token).to eq('f3eaae399310defaa')
  end

  it 'exposes the app name' do
    config = Thrust::AppConfig.new({'app_name' => 'my-cool-app'})
    expect(config.app_name).to eq('my-cool-app')
  end

  it 'exposes the ios_distribution_certificate' do
    config = Thrust::AppConfig.new({'ios_distribution_certificate' => 'some-cert'})
    expect(config.ios_distribution_certificate).to eq('some-cert')
  end
end
