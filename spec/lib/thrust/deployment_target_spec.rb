require_relative '../../../lib/thrust/deployment_target'

describe Thrust::DeploymentTarget do
  it 'exposes the distribution_list' do
    target = Thrust::DeploymentTarget.new('distribution_list' => 'Presidents')
    expect(target.distribution_list).to eq('Presidents')
  end

  it 'exposes ios_build_configuration' do
    target = Thrust::DeploymentTarget.new('ios_build_configuration' => 'Debug')
    expect(target.ios_build_configuration).to eq('Debug')
  end

  it 'exposes the versioing_method' do
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

  it 'exposes the ios_provisioning_search_query' do
    target = Thrust::DeploymentTarget.new('ios_provisioning_search_query' => 'some-query')
    expect(target.ios_provisioning_search_query).to eq('some-query')
  end

  it 'exposes the ios_target value' do
    target = Thrust::DeploymentTarget.new('ios_target' => 'some-target')
    expect(target.ios_target).to eq('some-target')
  end
end
