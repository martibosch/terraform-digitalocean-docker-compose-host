# `docker-compose` host

Simple module to initialize an extendible `ubuntu-18-04-x64` droplet with `docker` and `docker-compose`.

## Considerations

- As of yet, the `docker` provisioning will only work on `ubuntu-{16-04, 18-04, 19-10}-x64` droplets.
- Per docker installation instructions, only 64-bit versions of Debian, Fedora, CentOS and Ubuntu servers are fully tested and supported.
- Here is a brief list of the DO images that do support docker:

|       ID | Name   | Distribution      | Slug               |
| -------: | :----- | :---------------- | :----------------- |
| 50903182 | CentOS | 7.6 x64           | `centos-7-x64`     |
| 53621447 | Debian | 9.7 x64           | `debian-9-x64`     |
| 56427524 | Debian | 10.2 x64          | `debian-10-x64`    |
| 47384041 | Fedora | 30 x64            | `fedora-30-x64`    |
| 56521921 | Fedora | 31 x64            | `fedora-31-x64`    |
| 55022766 | Ubuntu | 16.04.6 (LTS) x64 | `ubuntu-16-04-x64` |
| 53893572 | Ubuntu | 18.04.3 (LTS) x64 | `ubuntu-18-04-x64` |
| 53871280 | Ubuntu | 19.10 x64         | `ubuntu-19-10-x64` |


## Inputs

| Name                                                  | Description                                                                                                    | Type                                                                                                           | Default            | Required                        |
| :---------------------------------------------------- | :------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------- | :----------------- | :------------------------------ |
| `do_token`                                            | DigitalOcean authentication token.                                                                             | `string`                                                                                                       |                    | yes                             |
| `droplet_name`                                        | Name of the DigitalOcean droplet. Must be unique.                                                              | `string`                                                                                                       |                    | yes                             |
| `tags`                                                | Tags to set on the droplet.                                                                                    | `list(string)   `                                                                                              | []                 | no                              |
| `image`                                               | Image slug for the desired image.                                                                              | `string`                                                                                                       | `ubuntu-18-04-x64` | no                              |
| `region`                                              | Region to assign the droplet to.                                                                               | `string`                                                                                                       | `nyc3`             | no                              |
| `size`                                                | Droplet size.                                                                                                  | `string`                                                                                                       | `s-1vcpu-1gb`      | no                              |
| `ssh_keys`                                            | List of SSH IDs or fingerprints to enable. They must already exist in your DO account.                         | `list(string)`                                                                                                 | []                 | no<sup>[1](#keyfile-note)</sup> |
| `ssh_key_file`                                        | SSH public key file to add to the DO account.                                                                  | `string`                                                                                                       | `""`               | no<sup>[1](#keyfile-note)</sup> |
| `init_script`                                         | Initialization script to run                                                                                   | `string`                                                                                                       | `./init.sh`        | no                              |
| `domain`                                              | Domain to assign to droplet. If set, will automatically create an A record that points to the created droplet. | `string`                                                                                                       | `""`               | no                              |
| `records`<sup>[2](#record-note),[3](#name-note)</sup> | DNS records to attach to the domain. Ignored if `domain` is empty (`""`).                                      | `map(object({`<br>&nbsp;&nbsp;`type=string`<br>&nbsp;&nbsp;`value=string`<br>&nbsp;&nbsp;`ttl=number`<br>`}))` | `{}`               | no                              |


1. <a name="keyfile-note"></a>: `remote-exec` will attempt to install `docker` through `ssh` with one of these keys. Provisioning will fail if
   - a) an `ssh_key_file` (i.e. `~/.ssh/id_rsa.pub`) is not provided and
   - b) no key is passed in the `ssh_keys` list that the local machine has access to

2. <a name="record-note"></a>: Domain records that are of `type="A"` and the special value `value="droplet"` will point to the created droplet's `ipv4_address`, otherwise will be pointed to its `value` attribute.

3. <a name="name-note"></a>: Note the `name` attribute to the <a target="_blank" rel="noopener noreferrer" href="https://developers.digitalocean.com/documentation/v2/#create-a-new-domain-record">DigitalOcean API</a> is passed in as the `map`'s key. See the [example](#example) for detailed usage.

## Outputs

| Name           | Description               |
| :------------- | :------------------------ |
| `ipv4_address` | IP address of the droplet |

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
    ssh_key_file = "~/.ssh/id_rsa.pub"
    init_script = "./my-init-file.sh"

    domain = "example.com"
    records = {
        # subdomain.example.com CNAME
        "subdomain.": {"type"="CNAME", "value"="@", "ttl"=7200},
        # subdomain2.example.com through an A record
        "subdomain2.": {type="A", "value"="droplet", "ttl"=1800},
        # wildcard
        "*.": {"value"="@", "ttl"=3600, "type"="CNAME"},
    }
}
```