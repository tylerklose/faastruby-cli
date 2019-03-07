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
        loop do
          system(cmd.join(" "))
          sleep 1
        end
      end
    end
  end
end