require 'serverspec'
set :backend, :exec

describe file('etc/hostname') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
end

describe file('bin/bash') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 755 }
end

describe file('etc/apt/sources.list') do
  it { should be_file }
  its(:content) { should contain 'deb http://httpredir.debian.org/debian stretch main' }
  its(:content) { should contain 'deb http://httpredir.debian.org/debian stretch-updates main' }
  its(:content) { should contain 'deb http://security.debian.org/ stretch/updates main' }
end


describe file('etc/network/interfaces.d/eth0') do
  it { should be_file }
  its(:content) { should contain /allow-hotplug eth0/ }
  its(:content) { should contain /iface eth0 inet dhcp/ }
end

describe file('etc/resolv.conf') do
  it { should be_symlink }
end

describe file('run/systemd/resolve/resolv.conf') do
  it { should be_file }
end

describe file('etc/shadow') do
  it { should be_file }
  its(:content) { should contain /^root:\*:/ }
end

describe file('etc/locale.gen') do
  it { should be_file }
  its(:content) { should contain /en_US.UTF-8/ }
end

describe file('etc/hostname') do
  it { should be_file }
  its(:content) { should contain /^#{ENV['HOSTNAME']}$/ }
end

describe file('root/.bash_prompt') do
  it { should be_file }
end

describe file('etc/skel/.bash_prompt') do
  it { should be_file }
end

describe file('etc/skel/.bashrc') do
  it { should be_file }
end

describe file('etc/skel/.profile') do
  it { should be_file }
end

describe file('etc/motd') do
  it { should be_file }
  its(:content) { should contain /^RaspiDeb64 / }
end

describe file('etc/issue') do
  it { should be_file }
  its(:content) { should contain /^RaspiDeb64 / }
end

describe file('etc/issue.net') do
  it { should be_file }
  its(:content) { should contain /^RaspiDeb64 / }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /ID=debian/ }
  its(:content) { should contain /OS=/ }
  its(:content) { should contain /OS_VERSION=/ }
  if ENV.fetch('TRAVIS_TAG','') != ''
    its(:content) { should_not contain /dirty/ }
  end
end

