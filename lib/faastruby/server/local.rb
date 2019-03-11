module FaaStRuby
  module Local
    def self.start!(sync: false, deploy_env: 'stage', debug: false)
      Thread.new do
        env = {
          'SYNC' => sync,
          'DEPLOY_ENVIRONMENT' => deploy_env
        }
        cmd = []
        cmd << "SYNC=true" if sync
        cmd << "DEBUG=true" if debug
        cmd << "DEPLOY_ENVIRONMENT=#{deploy_env}"
        cmd << "faastruby watch"
        5.times do
          system(cmd.join(" "))
          sleep 1
        end
        puts "FaaStRuby Local exited due to an error."
        puts "If you think this shouldn't have happened, open an issue here: https://github.com/FaaStRuby/faastruby-cli/issues/new"
        exit 1
      end
    end
  end
end