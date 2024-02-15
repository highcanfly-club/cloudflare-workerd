# highcanfly/cloudflare-workerd

## Description

this is a Docker container for cloudflare workerd, it's based on the official node image and it's used to run cloudflare workerd in a container.  
When it is built it uses the latest version of cloudflare workerd and tag it as the same version as the cloudflare workerd tagged version.

## Usage

```bash
docker run highcanfly/cloudflare-workerd:latest --help
```

### Local build

```bash
docker buildx build --push --platform linux/amd64,linux/arm64 --build-arg REMOTE_CACHE_URL=https://user:pass@cache.example.com --tag highcanfly/cloudflare-workerd:$(curl --silent "https://api.github.com/repos/cloudflare/workerd/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') --tag highcanfly/cloudflare-workerd:latest .
```
