


When(/^I decode QS CSR from file "([^"]*)"$/) do |filename|
  steps %{
    Then I run `/usr/local/isara_ssl/bin/openssl req -engine /usr/local/isara_ssl/lib/engines/libiqre_engine.so -text -noout -in "#{filename}"`
    And the exit status should be 0
  }
  @csr_text = last_command_started.output.to_s
end

When(/^I parse QS CSR from file "([^"]*)"$/) do |filename|
  steps %{
    Then I run `/usr/local/isara_ssl/bin/openssl asn1parse -in "#{filename}"`
    And the exit status should be 0
  }
  @csr_text = last_command_started.output.to_s
end

When(/^I decode QS certificate from file "([^"]+)"$/) do |filename|
  steps %{
    Then I try to run `openssl x509 -text -fingerprint -noout -in "#{filename}"`
    And the exit status should be 0
  }
  @certificate_text = last_command_started.output.to_s
  m = last_command_started.output.match /^SHA1 Fingerprint=(\S+)$/
  if m
    @certificate_fingerprint = m[1]
  else
    @certificate_fingerprint = ""
  end

  m2 =  last_command_started.output.match /X509v3 Subject Alternative Name:\s+([^\n]+)\n/m
  if m2
    @certififcate_sans = m2[1].split
  else
    @certififcate_sans = []
  end
end

When(/^that QS (CSR|certificate)?( Subject)? should( not)? contain "([^"]*)"$/) do |block, subject, negated, expected|
  text = case block
         when "CSR" then @csr_text
         when "certificate" then @certificate_text
         else ""
         end
  if subject
    if negated
      expect(text).not_to match(/Subject.+#{expected}/)
    else
      expect(text).to match(/Subject.+#{expected}/)
    end
  else
    if negated
      expect(text).not_to send(:an_output_string_including, expected)
    else
      expect(text).to send(:an_output_string_including, expected)
    end
  end
end
