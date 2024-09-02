require "httparty"
require "nokogiri"
require "pry"
require "google_drive"
require "googleauth"

MONTHS = {
  'Enero' => 1,
  'Febrero' => 2,
  'Marzo' => 3,
  'Abril' => 4,
  'Mayo' => 5,
  'Junio' => 6,
  'Julio' => 7,
  'Agosto' => 8,
  'Septiembre' => 9,
  'Octubre' => 10,
  'Noviembre' => 11,
  'Diciembre' => 12
}.freeze

regex = /(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})/
baloto_kind_regex_image = /baloto-kind\.png/

refresh_token = ""
total_pages = 70

credentials = Google::Auth::UserRefreshCredentials.new(
  client_id: "XXXXXXXXXXXXXXXXXXXXXXXX",
  client_secret: "XXXXXXXXXXXXXXXXXXXXXXXX",
  scope: [
    "https://www.googleapis.com/auth/drive",
    "https://spreadsheets.google.com/feeds/",
  ],
  redirect_uri: "https://example.com/redirect",
  additional_parameters: { "access_type" => "offline" })

if refresh_token.empty?
  auth_url = credentials.authorization_uri
  puts "Open the following URL in your browser and enter the resulting code:\n #{auth_url}"
  authorization_code = gets.chomp
  credentials.code = authorization_code
  credentials.fetch_access_token!
  p "The refresh token is: #{credentials.refresh_token}"
else
  credentials.refresh_token = refresh_token
  credentials.fetch_access_token!
end
session = GoogleDrive::Session.from_credentials(credentials)

ws = session.spreadsheet_by_key("1LYxpOhjWBUL_pXccduld6oIy0nCveEsjsAe0EeA8nTs").worksheets[0]

counter = 2

(1..total_pages).each do |current_page|
  response = HTTParty.get("https://baloto.com/resultados?page=#{current_page}")
  parsed = Nokogiri::HTML(response.body)

  parsed.css("table#results-table tbody tr").each do |tr|
    td_nodes = tr.css("td")
    image_node = td_nodes[0]
    raw_image_url = image_node.children[1].attributes['src'].value
    date_note = td_nodes[1]
    date_note_content = date_note.inner_html
    if match = date_note_content.match(regex)
      day = match[1]
      month = match[2]
      year = match[3]
      date = Date.new(year.to_i, MONTHS[month], day.to_i)
    end
    result_note = td_nodes[2]
    result_items = result_note.children[0].text.split(" - ")
    red_ball_result = result_note.children[1].text
    ws[counter, 1] = date.strftime("%d/%m/%Y")
    ws[counter, 2] = raw_image_url.match?(baloto_kind_regex_image) ? "Baloto" : "Revancha"
    result_items.each_with_index do |result_item, index|
      ws[counter, 3 + index] = result_item
    end
    ws[counter, 8] = red_ball_result
    counter += 1
  end
  sleep(5)
  p "Page #{current_page} done!"
  ws.save
end

