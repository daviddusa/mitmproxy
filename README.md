# HTTPS

1. Configure HTTP proxy at the OS level for port 8181.
2. Open http://mitm.it
3. Download the mitmproxy-ca-cert.pem
4. Place it in the OS cert store

OR after running mitmproxy for the first time, since it generates the CA cert files under ~/.mitmproxy, you can copy it as well to the OS cert store.

```
sudo cp mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt
sudo update-ca-certificates
```

https://docs.mitmproxy.org/stable/concepts/certificates/#quick-setup

# Notes

## Proxying

cURL and apps does not respect HTTP(S) proxy configured at the OS level, only browsers. If you want to intercept all traffic regardless of their origin (apps, browser), traffic must be redirected at the network level via `iptables` rules.

https://docs.mitmproxy.org/stable/howto/transparent/#transparent-proxying

## CA certs

Browsers use their own certificate store, so importing mitmproxy CA cert to the OS CA trust store will have no effect. You need to import it to its trust store as well.

HTTP clients, like urllib3, requests, httpx if installed via pip also use their own (certifi) CA cert because it would be hard determine the location of the OS CA cert file path across many OS distributions. However, if you install the libraries via apt on Ubuntu, they will use the OS cert store, because Canonical patced certifi.

# Debug

If the connection fails due to SSL error verify the that the certificate presented to the client app for validation is indeed issued by the server, mitmproxy in our case.

1. Get the certificate that is presented by the server via **openssl**:

```
openssl s_client -connect www.infostart.hu:443 -showcerts
```

2. Locate the certificate

```
-----BEGIN CERTIFICATE-----
MIIDSDCCAjCgAwIBAgIUFnCDC8/jLlr7PvqCxBsPztSXy+gwDQYJKoZIhvcNAQEL
BQAwKDESMBAGA1UEAwwJbWl0bXByb3h5MRIwEAYDVQQKDAltaXRtcHJveHkwHhcN
MjUwODI5MTgwODUwWhcNMjYwODMxMTgwODUwWjAZMRcwFQYDVQQDDA4qLmluZm9z
dGFydC5odTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAORfRdBp4EAl
c6ICbAVoCKBWCYFwwm8LHoJ9U8eeJRKUx1cLO1MaMGSZuhoC8nMpAjRsmnAVgzV6
5SIBHfXrLFQhKPnH5YSAOcY8Yu7gazuDE0bw0fxHRSxQZDgU7dJPUrpgfMb2PtRz
4uFXhFOzva2K/FQeOCzmtmoaLFFBZ1eFGtARq4ufqNDz6JI4FtptOPLNKYnSPB36
HaFgJYGONCP7tDYY4vNQjaMbMEsvumYI15LtsOVbwbwA3Sn8Dz3UE7nTJo+QWHaF
/ckLU82WBSHM42GjOwDOyJH9zaMEQFek7PouC24PqbkR1+zrhawG8DZQX3si2pPO
oVnOAsUzKMUCAwEAAaN5MHcwEwYDVR0lBAwwCgYIKwYBBQUHAwEwPwYDVR0RBDgw
NoIOKi5pbmZvc3RhcnQuaHWCDGluZm9zdGFydC5odYIQd3d3LmluZm9zdGFydC5o
dYcEV+VjhTAfBgNVHSMEGDAWgBQALjLLCKgzNGBqzbJt+ESgsFs+kTANBgkqhkiG
9w0BAQsFAAOCAQEA0UqLyguatL4Qd7e9P24vcLHViD79NNhdBZ8WIlqNYeT5cgE8
lvWHDo+/OA5SD6Iza7JEt475p1gJAJ44GWH6RHB7yZnr3Ffwe+geautHgH+1gt+A
5c6ZbsYAKqotLYMYSbyyVea0zsgdCvB6EM04wLD2ujdds+MyUDcXOi+TRyB7I1BI
gBWGpDJCdG5V0EYjXuMSyTi8+tt0ZgUBPjBbf2LwX9EcnGeWu+dQvigoSYeCXdow
zHD7DqMeTXkplu+qpeHWPDOeMLOsJFRMXNSApghduQd4FSMqAM41jzHcmz2fOfQl
EwPCfiPGiNudAKNR6OfhGUxdQJ3U0BfjRJhRdw==
```

3. Save the certificate to a file and view it as text

```
openssl x509 -in tmp.crt -text -noout
```

4. Check the mitmproxy CA cert that is supposed to issue the certificates

```
openssl x509 -in mitmproxy-ca-cert.crt -text -noout
```

5. Verify the **X509v3 Subject Key Identifier** and **X509v3 Authority Key Identifier** keys match.

```
X509v3 Authority Key Identifier: 
	68:90:E4:67:A4:A6:53:80:C7:86:66:A4:F1:F7:4B:43:FB:84:BD:6D
X509v3 Subject Key Identifier: 
	68:90:E4:67:A4:A6:53:80:C7:86:66:A4:F1:F7:4B:43:FB:84:BD:6D
```
