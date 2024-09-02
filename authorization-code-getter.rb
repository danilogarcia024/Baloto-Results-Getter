require 'sinatra'
require 'cgi'
require 'pry'

get '/redirect' do
  parsed_params = CGI::parse(request.env["REQUEST_URI"])
  "The code is: #{parsed_params['/redirect?code'][0]}"
end
