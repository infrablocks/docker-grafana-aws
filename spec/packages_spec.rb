require 'spec_helper'

describe 'packages' do
  image = 'grafana-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  ['ca-certificates', 'tzdata', 'openssl', 'musl-utils'].each do |apk|
    it "includes the #{apk} package" do
      expect(package(apk)).to(be_installed)
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end