require 'samanage'



@samanage = Samanage::Api.new(token: ARGV[0])
@options = {
  "service_request[]" => 1,
  "title[]" => "Security Access Request",
  verbose: true
}
service_requests = []
if Dir["*.csv"].count.zero?
  service_requests = @samanage.incidents(options: @options)
else
  service_requests = @samanage.incidents(options: @options)
end


class String
  def to_binary
    self.strip.empty? ? "0" : "1"
  end
end

class ServiceRequest
  
  attr_reader samanage_id

  def initialize(samanage_id: )
    @samanage_id = samanage_id
  end

  def samanage_data
    @samanage_data ||= @samanage.find_incident(options: {layout: 'long'})[:data]
  end

  def request_variables
    samanage_data['request_variables'].to_a
  end

  # Returns: String
  def lookup_variable(name: )
    request_variables.find{|request_var| request_var['name'] == name}
                     .to_h.dig("value").to_s
  end

  def service_request_hash
    core_text = (lookup_variable(name: "CorText") + lookup_variable(name: "CoreText")).to_binary
    {
      "incident_id": samanage_data['id'],
      "EmpID": lookup_variable(name: "Employee Number"),
      "FName": lookup_variable(name: "First and Middle Name"),
      "MName": "",
      "LName": lookup_variable(name: "Last Name"),
      "Title": lookup_variable(name: "Title"),
      "Dept": lookup_variable(name: "Department Name"),
      "Supervisor Name": lookup_variable(name: "Supervisor Name"),
      "Supervisor Email": lookup_variable(name: "Supervisor Email Address"),
      "Supervisor Phone": lookup_variable(name: "Supervisor Phone"),
      "AD": to_binary(lookup_variable(name: "Network (AD)")),
      "Email": "1",
      "VPN": lookup_variable(name: "Remote VPN Access").to_binary,
      "CRM": lookup_variable(name: "CRM"),
      "Abila": lookup_variable(name: "Abila (add required notes below)").to_binary,
      "Abila Notes": "",
      "Hyperion": lookup_variable(name: "Hyperion (add required notes below)").to_binary,
      "Hyperion Notes": "",
      "EV5": "0",
      "EV5 Notes": "",
      "Coupa": lookup_variable(name: "Coupa (add required notes below)").to_binary,
      "Coupa Notes": "",
      "ADP": "0",
      "ADP Notes": "",
      "ICIMS": "0",
      "ICIMS Notes": "",
      "Secure Sheet": "0",
      "Secure Sheet Notes": "",
      "Cozeva": "0",
      "Cozeva Notes": "",
      "Innotas": "0",
      "Innotas Notes": "",
      "People Fluent": "0",
      "People Fluent Notes": "",
      "Epic": lookup_variable(name: "Epic (add required notes below)").to_binary,
      "Epic Notes": "",
      "OnBase": lookup_variable(name: "OnBase").to_binary,
      "OnBase Security Group": "",
      "Dental X-Ray": lookup_variable(name: "Dental X-Ray").to_binary,
      "Dental X-Ray Security Group": "",
      "Medical X-Ray": lookup_variable(name: "Medical X-Ray (Clarity)").to_binary,
      "ScriptPro": lookup_variable(name: "ScriptPro").to_binary,
      "CoreText": core_text,
      "Provider Checkbox EPCS (Duo)": lookup_variable(name: "Provider").to_binary,
    }
  end

  def write_log
    log_service_request(service_request_hash: service_request_hash)
  end

  def log_service_request(service_request_hash: , filename: ERROR_FILENAME)
    puts "[ERROR]: #{service_request_hash[:error]}"
    write_headers = !File.exist?(filename)
    CSV.open(filename, 'a+', write_headers: write_headers, force_quotes: true, headers: service_request_hash.keys) do |csv|
      csv << service_request_hash.values
    end
  end
end