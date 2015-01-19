require 'spec_helper'

describe Thrust::DeploymentTarget do
  it 'exposes the distribution_list' do
    target = Thrust::DeploymentTarget.new('distribution_list' => 'Presidents')
    expect(target.distribution_list).to eq('Presidents')
  end

  it 'exposes build_configuration' do
    target = Thrust::DeploymentTarget.new('build_configuration' => 'Debug')
    expect(target.build_configuration).to eq('Debug')
  end

  it 'exposes the versioning_method' do
    target = Thrust::DeploymentTarget.new('versioning_method' => 'some-method')
    expect(target.versioning_method).to eq('some-method')
  end

  it 'exposes the notify value' do
    target = Thrust::DeploymentTarget.new('notify' => true)
    expect(target.notify).to eq(true)
  end

  it 'exposes the note_generation_method value' do
    target = Thrust::DeploymentTarget.new('note_generation_method' => 'generate-it')
    expect(target.note_generation_method).to eq('generate-it')
  end

  it 'exposes the provisioning_search_query' do
    target = Thrust::DeploymentTarget.new('provisioning_search_query' => 'some-query')
    expect(target.provisioning_search_query).to eq('some-query')
  end

  it 'exposes the target value' do
    target = Thrust::DeploymentTarget.new('target' => 'some-target')
    expect(target.target).to eq('some-target')
  end
end
