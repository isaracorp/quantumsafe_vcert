Feature: Generating certificate request with Dilithium key using options

  As a user I want to generate certificate requests with Dilithium key and various properties

  Background:
    And the default aruba exit timeout is 180 seconds

  Scenario: when all the options are used with Dilithium key type
  When I try to run `vcert gencsr -csr-file csr.pem -key-file k.pem -cn vfidev.example.com -san-dns www.vfidev.example.com -san-dns ww1.vfidev.example.com -no-prompt -san-email aa@ya.ru -san-email bb@ya.ru -san-ip 1.1.1.1 -san-ip 2.2.2.2 -l L -st ST -c C -ou OU -o O -key-type dilithium -key-param iqr_dilithium_160`
    Then the exit status should be 0
    Then it should write CSR to the file named "csr.pem"
    Then I decode QS CSR from file "csr.pem"
      And that CSR Subject should contain "C=C"
      And that CSR Subject should contain "ST=ST"
      And that CSR Subject should contain "L=L"
      And that CSR Subject should contain "O=O"
      And that CSR Subject should contain "OU=OU"
      And that CSR Subject should contain "CN=vfidev.example.com"

      And that CSR should contain "DNS:www.vfidev.example.com"
      And that CSR should contain "DNS:ww1.vfidev.example.com"
      And that CSR should contain "email:aa@ya.ru"
      And that CSR should contain "email:bb@ya.ru"
      And that CSR should contain "IP Address:1.1.1.1"
      And that CSR should contain "IP Address:2.2.2.2"
      And that CSR should contain "DILITHIUM_IV_SHAKE_r2"

  Scenario: explicitly verifying CSR and different Dilithium key type iqr_dilithium_128
    When I run `vcert gencsr -csr-file csr.pem -key-file k.pem -no-prompt -cn vfidev.example.com -key-type dilithium -key-param iqr_dilithium_128`
      Then the exit status should be 0
      Then it should write CSR to the file named "csr.pem"
      Then I decode QS CSR from file "csr.pem"
        And that CSR should contain "DILITHIUM_III_SHAKE_r2"

  Scenario: Extend classic CSR with Dilithium key to generate a hybrid CSR
    When I run `vcert gencsr -csr-file csr_classic.pem -key-file classic_key.pem -no-prompt -cn vfidev.example.com`
    And I run `vcert extendcsrqs -csr-qs-file csr_hybrid.pem -csr-in-file csr_classic.pem -key-qs-file key_qs.pem -key-in-file classic_key.pem --no-prompt`
      Then the exit status should be 0
      Then it should write CSR to the file named "csr_hybrid.pem"
      Then I parse QS CSR from file "csr_hybrid.pem"
        And that CSR should contain "Dilithium_III_SHAKE_r2"
        And that CSR should contain "Dilithium-Signature-Scheme"
        And that CSR should contain "Alternative Signature Value"
        And that CSR should contain "Alternative Signature Algorithm"
