# Download SSL certificates from URL

The certificates are downloaded individually, not as a single chain.

Usage:

```shell script
gencerts.sh <server>[:port] [PEM|DER]

server - IP address or host name of the target server
port - The HTTPS port to use. Default is 443
PEM|DER - The output file format. Defaults to X.509 PEM

```

Example:
```shell script
gencerts www.example.com
```

Produces the following files:

```text
.
├── subject=C_=_US_O_=_DigiCert_Inc_CN_=_DigiCert_SHA2_Secure_Server_CA.pem
├── subject=C_=_US_O_=_DigiCert_Inc_OU_=_www_digicert_com_CN_=_DigiCert_Global_Root_CA.pem
└── subject=C_=_US_ST_=_California_L_=_Los_Angeles_O_=_Internet_Corporation_for_Assigned_Names_and_Numbers_OU_=_Technology_CN_=_www_example_org.pem
```
