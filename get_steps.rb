require 'fitbit_api'
require 'dotenv'
require 'pry'

Dotenv.load

conn = Faraday.new(
  url: 'https://api.fitbit.com/',
  headers: {
    'Content-Type' => 'application/x-www-form-urlencoded',
    'Authorization' => "Basic #{ENV['AUTHORIZATION_BASIC']}",
  }
)

response = JSON.parse(conn.post('/oauth2/token', "grant_type=refresh_token&refresh_token=#{File.read('refresh')}").body)

File.open("refresh", mode = "w") { |f| f.write(response["refresh_token"]) }

client = FitbitAPI::Client.new(client_id: ENV['CLIENT_ID'],
                               client_secret: ENV['CLIENT_SECRET'],
                               access_token: response['access_token'],
                               refresh_token: response['refresh_token'],
                               user_id: response['user_id'])

walked_steps = client.activity_time_series("steps", { period: "7d" })

walked_steps.each do |step|
  Faraday.post(
    "https://pixe.la/v1/users/#{ENV['PIXELA_USER_ID']}/graphs/#{ENV['PIXELA_GLAPH_ID']}",
    { 'date': step['dateTime'].gsub('-', ''), 'quantity': step['value'] }.to_json,
    { "X-USER-TOKEN" => ENV['PIXELA_SECRET'] }
  )
end
