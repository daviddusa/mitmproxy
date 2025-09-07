import certifi
import httpx
import urllib3
import ssl


def run_urllib3():
    http = urllib3.ProxyManager(
        proxy_url="https://127.0.0.1:8181/",
        # ca_certs=certifi.where(),
        ca_certs="/etc/ssl/certs/ca-certificates.crt",
    )
    r = http.request("GET", "https://infostart.hu", retries=False)
    print("urllib3 response:", r.status)


def run_httpx():
    response = httpx.get(
        "https://infostart.hu",
        proxy="https://127.0.0.1:8181",
        verify=ssl.create_default_context(cafile="/etc/ssl/certs/ca-certificates.crt") 
    )
    print("httpx response:", response.status_code)


run_urllib3()
run_httpx()
