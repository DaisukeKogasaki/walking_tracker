# frozen_string_literal: true

require "fitbit_api"
require "dotenv"
require "pry"

class GetSteps
  def initialize
    Dotenv.load
  end

  def run
    token = get_token

    # refreshファイルにrefresh_tokenを書き出す
    File.open("refresh", "w") { |f| f.write(token["refresh_token"]) }

    steps = get_steps(token)
    puts steps

    post_pixela(steps)
  end

  private

  def faraday_client(target_url, options: {})
    Faraday.new(
      url: target_url,
      headers: options,
    )
  end

  def get_token
    client = faraday_client("https://api.fitbit.com/",
                            options: {
                              "Content-Type" => "application/x-www-form-urlencoded",
                              "Authorization" => "Basic #{ENV['AUTHORIZATION_BASIC']}"
                            })
    response = client.post("/oauth2/token", "grant_type=refresh_token&refresh_token=#{File.read('refresh')}").body
    JSON.parse(response)
  end

  def get_steps(token)
    client = FitbitAPI::Client.new(client_id: ENV["CLIENT_ID"],
                                    client_secret: ENV["CLIENT_SECRET"],
                                    access_token: token["access_token"],
                                    refresh_token: token["refresh_token"],
                                    user_id: token["user_id"])
    client.activity_time_series("steps", { period: "7d" })
  end

  def post_pixela(walked_steps)
    client = faraday_client("https://pixe.la/", options: { "X-USER-TOKEN" => ENV["PIXELA_SECRET"] })
    walked_steps.each do |step|
      client.post("v1/users/#{ENV['PIXELA_USER_ID']}/graphs/#{ENV['PIXELA_GLAPH_ID']}") do |req|
        req.body = { 'date': step["dateTime"].delete("-"), 'quantity': step["value"] }.to_json
      end
    end
  end
end

get_steps = GetSteps.new
get_steps.run
