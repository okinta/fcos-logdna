# README

[LogDNA][1] configuration for [Fedora CoreOS][2].

This runs the LogDNA agent inside a container and allows forwarding of the
machine's journald logs.

[1]: https://logdna.com/
[2]: https://docs.fedoraproject.org/en-US/fedora-coreos/

## Usage

To run on Fedora CoreOS via podman, `/var/log/journal` needs to be mounted.

An example systemd service definition looks like the following:

    [Unit]
    Description=LogDNA Forwarder
    After=network-online.target
    Wants=network-online.target

    [Service]
    Restart=on-failure
    ExecStartPre=-/bin/podman kill logdna
    ExecStartPre=-/bin/podman rm logdna
    ExecStartPre=/bin/podman pull okinta/fcos-logdna
    ExecStart=/bin/podman run -v /var/log/journal:/var/log/journal:z -e TAG=$TAG --name logdna okinta/fcos-logdna

    [Install]
    WantedBy=multi-user.target

The `TAG` environment variable can be to the tag to forward to LogDNA.

## Development

### Build

    docker build -t okinta/fcos-logdna .
