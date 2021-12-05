# `docker-compose` host

Simple module to initialize an extendible `ubuntu` droplet with `docker` and `docker-compose`.

## Considerations

- As of yet, the `docker` provisioning will only work on `ubuntu-{16-04, 18-04, 19-10, 20-04}-x64` droplets.
- Per docker installation instructions, only 64-bit versions of Ubuntu servers are fully tested and supported.
- Here is a list of the DO supported images:

|       ID | Name   | Distribution      | Slug               |
| -------: | :----- | :---------------- | :----------------- |
| 55022766 | Ubuntu | 16.04.6 (LTS) x64 | `ubuntu-16-04-x64` |
| 53893572 | Ubuntu | 18.04.3 (LTS) x64 | `ubuntu-18-04-x64` |
| 53871280 | Ubuntu | 19.10 x64         | `ubuntu-19-10-x64` |
| 93525508 | Ubuntu | 20.04.3 (LTS) x64 | `ubuntu-20-04-x64` |


## Inputs

| Name                                                  | Description                                                                                                                                              | Type                                                                   | Default            | Required                        |
|--:----------------------------------------------------|--:-------------------------------------------------------------------------------------------------------------------------------------------------------|--:---------------------------------------------------------------------|--:-----------------|--:------------------------------|
| `do_token`                                            | DigitalOcean authentication token.                                                                                                                       | `string`                                                               |                    | yes                             |
| `droplet_name`                                        | Name of the DigitalOcean droplet. Must be unique.                                                                                                        | `string`                                                               |                    | yes                             |
| `tags`                                                | Tags to set on the droplet.                                                                                                                              | `list(string)   `                                                      | []                 | no                              |
| `image`                                               | Image slug for the desired image.                                                                                                                        | `string`                                                               | `ubuntu-18-04-x64` | no                              |
| `region`                                              | Region to assign the droplet to.                                                                                                                         | `string`                                                               | `nyc3`             | no                              |
| `size`                                                | Droplet size.                                                                                                                                            | `string`                                                               | `s-1vcpu-1gb`      | no                              |
| `ssh_private_key`                                     | SSH private key used to access the server.                                                                                                               | `string`                                                               | `""`               | no                              |
| `docker_compose_version`                              | Version of docker compose to be installed (note that starting from v2.0.0, version strings are preceded by a `v` character.                              | `string`                                                               | `"v2.2.2"`         | no                              |
| `ssh_keys`                                            | List of SSH IDs or fingerprints to enable. They must already exist in your DO account.                                                                   | `list(string)`                                                         | []                 | no<sup>[1](#keyfile-note)</sup> |
| `user`                                                | Username of user account that will be created.                                                                                                           | `string`                                                               | `ubuntu`           | no                              |
| `init_script`                                         | Initialization script to run                                                                                                                             | `string`                                                               | `./init.sh`        | no                              |
| `domain`                                              | Domain to assign to droplet. If set, will automatically create an A record that points to the created droplet.                                           | `string`                                                               | `""`               | no                              |
| `records`<sup>[2](#record-note),[3](#name-note)</sup> | DNS records to create. The key to the map is the `name` attribute. If `"value"`==`"droplet"` it will be assigned to the created droplets `ipv4_address`. | `map(object({ domain=string, type=string, value=string, ttl=number}))` | `{}`               | no                              |
1. <a name="keyfile-note"></a>: `remote-exec` will attempt to install `docker` through `ssh` with one of these keys. Provisioning will fail if no key is passed in the `ssh_keys` list that the local machine has access to.

2. <a name="record-note"></a>: Domain records that are of `type="A"` and the special value `value="droplet"` will point to the created droplet's `ipv4_address`, otherwise will be pointed to its `value` attribute.

3. <a name="name-note"></a>: Note the `name` attribute to the <a target="_blank" rel="noopener noreferrer" href="https://developers.digitalocean.com/documentation/v2/#create-a-new-domain-record">DigitalOcean API</a> is passed in as the `map`'s key. See the [example](#example) for detailed usage.


  description = "DNS records to create. The key to the map is the \"name\" attribute. If \"value\"==\"droplet\" it will be assigned to the created droplet's ipv4_address."

## Outputs

| Name           | Description                  |
| :------------- | :--------------------------- |
| `ipv4_address` | IP address of the droplet.   |
| `id`           | ID of the created droplet.   |
| `name`         | Name of the created droplet. |

## Example<a name="example"></a>

```hcl
module "droplet" {
    source = "djangulo/docker-compose-host/digitalocean"
    droplet_name = "my-example"
    tags = [
        "dev",
        "example",
    ]

    image = "ubuntu-18-04-x64"
    region = "nyc3"
    size = "s-1vcpu-1gb"
    ssh_keys = [123456, "00:00:00:00:00:00:00:00:00:00:00:00:de:ad:be:ef"]
    init_script = "./my-init-file.sh"
    user = "djangulo"

    domain = "example.com"
    records = {
        # subdomain.example.com CNAME
        "subdomain.": {"domain"="example.com", "type"="CNAME", "value"="@", "ttl"=7200},
        # subdomain2.example.com through an A record
        "subdomain2.": {"domain"="example.com", "type"="A", "value"="droplet", "ttl"=1800},
        # subdomain3.otherdomain.com
        "subdomain3.": {"domain"="otherdomain.com", "type"="A", "value"="0.0.0.0"}
        # wildcard
        "*.": {"domain"="example.com", "value"="@", "ttl"=3600, "type"="CNAME"},
    }
}
```
