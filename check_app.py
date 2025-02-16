import requests
import sys


def main(alb_dns):
    url = f"http://{alb_dns}"
    try:
        response = requests.get(url, timeout=5)
        print("Response from ALB:", response.text)
    except Exception as e:
        print("Error connecting to ALB:", e)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_alb.py <alb_dns>")
        sys.exit(1)
    main(sys.argv[1])
