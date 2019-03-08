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
        puts "FaaStRuby Local exited. Please press CTRL+C."
      end
    end
  end
end