require 'spec_helper'

describe Thrust::SpecTarget do
  it 'exposes the build configuration' do
    target = Thrust::SpecTarget.new('build_configuration' => 'build-configuration')
    expect(target.build_configuration).to eq('build-configuration')
  end

  it 'exposes the build sdk' do
    target = Thrust::SpecTarget.new('build_sdk' => 'some-sdk')
    expect(target.build_sdk).to eq('some-sdk')
  end

  it 'defaults the build sdk to iphonesimulator' do
    target = Thrust::SpecTarget.new({})
    expect(target.build_sdk).to eq('iphonesimulator')
  end

  it 'exposes the device type' do
    target = Thrust::SpecTarget.new('device' => 'some-device')
    expect(target.device).to eq('some-device')
  end

  it 'exposes the device name' do
    target = Thrust::SpecTarget.new('device_name' => 'some-device-name')
    expect(target.device_name).to eq('some-device-name')
  end

  it 'exposes the os version' do
    target = Thrust::SpecTarget.new('os_version' => 'some-os-version')
    expect(target.os_version).to eq('some-os-version')
  end

  it 'exposes the timeout' do
    target = Thrust::SpecTarget.new('timeout' => '45')
    expect(target.timeout).to eq('45')
  end

  it 'defaults the device type to iphone' do
    target = Thrust::SpecTarget.new({})
    expect(target.device).to eq('iphone')
  end

  it 'exposes the scheme name' do
    target = Thrust::SpecTarget.new('scheme' => 'some-scheme')
    expect(target.scheme).to eq('some-scheme')
  end

  it 'exposes its type' do
    target = Thrust::SpecTarget.new('type' => 'foo')
    expect(target.type).to eq('foo')
  end

  it 'defaults its type to app' do
    target = Thrust::SpecTarget.new({})
    expect(target.type).to eq('app')
  end
end
