require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
      'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
      'AWS_S3_BUCKET_REGION' => s3_bucket_region,
      'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'grafana-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
          'NetworkMode' => 'docker_grafana_aws_test_default'
      }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_LOG_LEVEL' => 'debug',
              'GRAFANA_SERVER_HTTP_PORT' => '2999'
          })

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen",
          arguments: ['--tracing', '--tracing-file=/opt/grafana/trace.out'])
    end

    after(:all, &:reset_docker_backend)

    it 'runs grafana' do
      expect(process('/opt/grafana/bin/grafana-server')).to(be_running)
    end

    it 'points at the correct installation directory' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/--homepath=\/opt\/grafana/))
    end

    it 'points at the correct configuration file' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/--config=\/opt\/grafana\/conf\/grafana.ini/))
    end

    it 'points uses docker packaging' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/--packaging=docker/))
    end

    it 'uses a log mode of console' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/cfg:default.log.mode=console/))
    end

    it 'logs using JSON' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/cfg:default.log.console.format=json/))
    end

    it 'uses a data path of /var/opt/grafana' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/cfg:default.paths.data=\/var\/opt\/grafana/))
    end

    it 'uses a logs path of /var/log/grafana' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/cfg:default.paths.logs=\/var\/log\/grafana/))
    end

    it 'uses a plugins path of /opt/grafana/plugins' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/cfg:default.paths.plugins=\/opt\/grafana\/plugins/))
    end

    it 'uses a provisioning path of /opt/grafana/provisioning' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(
              /cfg:default.paths.provisioning=\/opt\/grafana\/provisioning/))
    end

    it 'passes additional arguments to grafana-server command' do
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/--tracing/))
      expect(process('/opt/grafana/bin/grafana-server').args)
          .to(match(/--tracing-file=\/opt\/grafana\/trace.out/))
    end

    it 'renames GRAFANA_ environment variables to GF_' do
      pid = process('/opt/grafana/bin/grafana').pid
      environment_contents =
          command("tr '\\0' '\\n' < /proc/#{pid}/environ").stdout
      environment = Dotenv::Parser.call(environment_contents)

      expect(environment['GF_LOG_LEVEL']).to(eq('debug'))
      expect(environment['GF_SERVER_HTTP_PORT']).to(eq('2999'))
    end

    it 'runs with the grafana user' do
      expect(process('/opt/grafana/bin/grafana-server').user)
          .to(eq('grafana'))
    end

    it 'runs with the grafana group' do
      expect(process('/opt/grafana/bin/grafana-server').group)
          .to(eq('grafana'))
    end

    it 'sets HOME to the grafana home directory' do
      pid = process('/opt/grafana/bin/grafana').pid
      environment_contents =
          command("tr '\\0' '\\n' < /proc/#{pid}/environ").stdout
      environment = Dotenv::Parser.call(environment_contents)

      expect(environment['HOME']).to(eq('/opt/grafana'))
    end
  end

  describe 'when the config file is not readable' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "GRAFANA_PATHS_CONFIG" => "/grafana.ini"
          })

      @output = execute_docker_entrypoint(
          started_indicator: "Error:")
    end

    after(:all, &:reset_docker_backend)

    it 'errors and exits' do
      expect(@output)
          .to(match(
              "Error: GRAFANA_PATHS_CONFIG='/grafana.ini' is not readable."))
      expect(@output)
          .not_to(match(/HTTP Server Listen/))
    end
  end

  describe 'when the data directory is not writable' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "GRAFANA_PATHS_DATA" => "/data"
          })

      @output = execute_docker_entrypoint(
          started_indicator: "Error:")
    end

    after(:all, &:reset_docker_backend)

    it 'errors and exits' do
      expect(@output)
          .to(match(
              "Error: GRAFANA_PATHS_DATA='/data' is not writable."))
      expect(@output)
          .not_to(match(/HTTP Server Listen/))
    end
  end

  describe 'when the home directory is not readable' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "GRAFANA_PATHS_HOME" => "/grafana"
          })

      @output = execute_docker_entrypoint(
          started_indicator: "Error:")
    end

    after(:all, &:reset_docker_backend)

    it 'errors and exits' do
      expect(@output)
          .to(match(
              "Error: GRAFANA_PATHS_HOME='/grafana' is not readable."))
      expect(@output)
          .not_to(match(/HTTP Server Listen/))
    end
  end

  describe 'when the plugins directory does not exist' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "GRAFANA_PATHS_PLUGINS" => "/opt/grafana/storage/plugins"
          })

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen")
    end

    after(:all, &:reset_docker_backend)

    it 'creates the plugins directory' do
      expect(file('/opt/grafana/storage/plugins'))
          .to(be_directory)
      expect(file('/opt/grafana/storage/plugins'))
          .to(be_owned_by('grafana'))
      expect(file('/opt/grafana/storage/plugins'))
          .to(be_grouped_into('grafana'))
    end
  end

  describe 'when aws profiles are provided' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_AWS_PROFILES' => 'london,ireland,spain',

              # tests region not added if not provided
              'GRAFANA_AWS_london_ACCESS_KEY_ID' => 'london-access-key',
              'GRAFANA_AWS_london_SECRET_ACCESS_KEY' => 'london-secret',

              # tests region is added if provided
              'GRAFANA_AWS_ireland_ACCESS_KEY_ID' => 'ireland-access-key',
              'GRAFANA_AWS_ireland_SECRET_ACCESS_KEY' => 'ireland-secret',
              'GRAFANA_AWS_ireland_REGION' => 'eu-west-1',

              # tests profile ignored if incomplete
              'GRAFANA_AWS_spain_ACCESS_KEY_ID' => 'spain-access-key',
          })

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen")
    end

    after(:all, &:reset_docker_backend)

    it 'adds AWS credentials to the credentials file' do
      aws_credentials = file('/opt/grafana/.aws/credentials').content

      expect(aws_credentials).to(eq(
          "[london]\n" +
              "aws_access_key_id = london-access-key\n" +
              "aws_secret_access_key = london-secret\n" +
              "[ireland]\n" +
              "aws_access_key_id = ireland-access-key\n" +
              "aws_secret_access_key = ireland-secret\n" +
              "region = eu-west-1\n"
      ))
    end

    it 'allows only the grafana user to read the credentials file' do
      expect(file('/opt/grafana/.aws/credentials'))
          .to(be_mode(600))
      expect(file('/opt/grafana/.aws/credentials'))
          .to(be_owned_by('grafana'))
      expect(file('/opt/grafana/.aws/credentials'))
          .to(be_grouped_into('grafana'))
    end
  end

  describe 'when plugins are provided by name' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_INSTALL_PLUGINS' =>
                  'grafana-clock-panel,grafana-googlesheets-datasource',
          })

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen")
    end

    after(:all, &:reset_docker_backend)

    it 'downloads the indicated plugins' do
      expect(file('/opt/grafana/plugins/grafana-clock-panel'))
          .to(exist)
      expect(file('/opt/grafana/plugins/grafana-googlesheets-datasource'))
          .to(exist)
    end
  end

  describe 'when plugins are provided by name and URL' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_INSTALL_PLUGINS' =>
                  'https://github.com/flant/grafana-statusmap/' +
                      'archive/v0.3.1.zip;' +
                      'grafana-statusmap'
          })

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen")
    end

    after(:all, &:reset_docker_backend)

    it 'downloads the indicated plugins' do
      expect(file('/opt/grafana/plugins/grafana-statusmap'))
          .to(exist)
    end
  end

  describe 'when environment variable values are provided via files' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_LOG_LEVEL__FILE' => '/tmp/log-level',
              'GRAFANA_SERVER_HTTP_PORT__FILE' => '/tmp/server-http-port'
          })

      execute_command('echo "debug" > /tmp/log-level')
      execute_command('echo "2999" > /tmp/server-http-port')

      execute_docker_entrypoint(
          started_indicator: "HTTP Server Listen")
    end

    after(:all, &:reset_docker_backend)

    it 'exposes the contents of the file as the environment variable' do
      pid = process('/opt/grafana/bin/grafana').pid
      environment_contents =
          command("tr '\\0' '\\n' < /proc/#{pid}/environ").stdout
      environment = Dotenv::Parser.call(environment_contents)

      expect(environment['GF_LOG_LEVEL']).to(eq('debug'))
      expect(environment['GF_SERVER_HTTP_PORT']).to(eq('2999'))
    end
  end

  describe 'when both file and value provided for environment variable' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'GRAFANA_LOG_LEVEL' => 'info',
              'GRAFANA_LOG_LEVEL__FILE' => '/tmp/log-level'
          })

      execute_command('echo "debug" > /tmp/log-level')

      @output = execute_docker_entrypoint(
          started_indicator: "Error:")
    end

    after(:all, &:reset_docker_backend)

    it 'errors and exits' do
      error_msg =
          "Error: Both GRAFANA_LOG_LEVEL and GRAFANA_LOG_LEVEL__FILE " +
              "are set (but are exclusive)."

      expect(@output).to(match(/#{Regexp.escape(error_msg)}/))
    end
  end


  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
        .merge(content: (opts[:env] || {})
            .to_a
            .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
            .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    arguments = opts[:arguments] && !opts[:arguments].empty? ?
        " #{opts[:arguments].join(' ')}" : ''

    execute_command(
        "docker-entrypoint.sh#{arguments} " +
            "> #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 15) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end