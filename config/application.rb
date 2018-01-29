require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Live
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.assets.paths << "#{Rails.root}/app/assets/videos"
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }
    config.active_record.raise_in_transactional_callbacks = true
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
    if Rails.env.production?
      ENV["domain"] = "https://www.shurikenlive.com"
      ENV["INSTAMOJO_KEY"] = ENV["PROD_INSTAMOJO_KEY"]
      ENV["INSTAMOJO_TOKEN"] = ENV["PROD_INSTAMOJO_TOKEN"]
      ENV["INSTAMOJO_API_BASE_URL"] = ENV["PROD_INSTAMOJO_API_BASE"]
      ENV["DONOR_PACK_URL"] = ENV["PROD_DONOR_PACK_URL"]
      ENV["PREMIUM_PACK_URL"] = ENV["PROD_PREMIUM_PACK_URL"]
      ENV["ULTIMATE_PACK_URL"] = ENV["PROD_ULTIMATE_PACK_URL"]
      ENV["PAYPAL_CLIENT_ID"] = ENV["PROD_PAYPAL_CLIENT_ID"]
      ENV["PAYPAL_CLIENT_SECRET"] = ENV["PROD_PAYPAL_CLIENT_SECRET"]
      ENV["PAYPAL_API_BASE_URL"] = ENV["PROD_PAYPAL_API_BASE"]
    else
      ENV["domain"] = "http://localhost:3000"
      ENV["INSTAMOJO_KEY"] = ENV["DEV_INSTAMOJO_KEY"]
      ENV["INSTAMOJO_TOKEN"] = ENV["DEV_INSTAMOJO_TOKEN"]
      ENV["INSTAMOJO_API_BASE_URL"] = ENV["DEV_INSTAMOJO_API_BASE"]
      ENV["DONOR_PACK_URL"] = ENV["DEV_DONOR_PACK_URL"]
      ENV["PREMIUM_PACK_URL"] = ENV["DEV_PREMIUM_PACK_URL"]
      ENV["ULTIMATE_PACK_URL"] = ENV["DEV_ULTIMATE_PACK_URL"]
      ENV["PAYPAL_CLIENT_ID"] = ENV["DEV_PAYPAL_CLIENT_ID"]
      ENV["PAYPAL_CLIENT_SECRET"] = ENV["DEV_PAYPAL_CLIENT_SECRET"]
      ENV["PAYPAL_API_BASE_URL"] = ENV["DEV_PAYPAL_API_BASE"]
    end
  end
end