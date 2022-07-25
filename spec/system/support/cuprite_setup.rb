REMOTE_CHROME_URL, REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if (chrome_url = ENV['CHROME_URL'])
    URI.parse(chrome_url).yield_self do |uri|
      uri.host = IPSocket.getaddress(uri.host)
      [uri.to_s, uri.host, uri.port]
    end
  end

# Check whether the remote chrome is running.
remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    false
  end

remote_options = remote_chrome ? { url: REMOTE_CHROME_URL } : {}

require "capybara/cuprite"

# Then, we need to register our driver to be able to use it later
# with #driven_by method.#
# NOTE: The name :cuprite is already registered by Rails.
# See https://github.com/rubycdp/cuprite/issues/180
Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      browser_options: remote_chrome ? { "no-sandbox" => nil } : {},
      inspector: true
    }.merge(remote_options)
  )
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
    # Drop #pause anywhere in a test to stop the execution.
    # Useful when you want to checkout the contents of a web page in the middle of a test
    # running in a headful mode.
    def pause
      page.driver.pause
    end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end