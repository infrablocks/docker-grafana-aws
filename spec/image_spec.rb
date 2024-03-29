# frozen_string_literal: true

require 'spec_helper'

describe 'image' do
  image = 'grafana-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh'
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'puts the grafana user in the grafana group' do
    expect(user('grafana'))
      .to(belong_to_primary_group('grafana'))
  end

  it 'uses a uid of 472 for the grafana user' do
    expect(user('grafana')).to(have_uid(472))
  end

  it 'uses a uid of 472 for the grafana group' do
    expect(group('grafana')).to(have_gid(472))
  end

  it 'has the correct owning user on the grafana directory' do
    expect(file('/opt/grafana')).to(be_owned_by('grafana'))
  end

  it 'has the correct owning group on the grafana directory' do
    expect(file('/opt/grafana')).to(be_grouped_into('grafana'))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
