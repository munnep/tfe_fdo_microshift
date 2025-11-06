# diagram_tfe_fdo_microshift.py
# Requirements:
#   pip install diagrams
#   brew install graphviz  # on macOS
#
# Run:
#   source ../venv/bin/activate
#   python3 diagram_tfe_fdo_microshift.py
#
# Output:
#   diagram_tfe_fdo_microshift.png

from diagrams import Diagram, Cluster, Edge
from diagrams.generic.compute import Rack
from diagrams.generic.device import Tablet
from diagrams.onprem.compute import Server
from diagrams.onprem.client import Client, Users
from diagrams.onprem.container import Docker
from diagrams.k8s.compute import Pod
from diagrams.onprem.database import Postgresql
from diagrams.onprem.inmemory import Redis
from diagrams.aws.storage import S3
from diagrams.saas.cdn import Cloudflare

with Diagram(
    "TFE FDO MicroShift on Podman (macOS)",
    show=False,
    filename="diagram_tfe_fdo_microshift",
    outformat="png",
    direction="LR",
):
    # External user
    external_user = Users("External User")
    
    # Cloudflare public service
    cloudflare_public = Cloudflare("Cloudflare\n(Public)")

    # macOS host
    mac_host = Client("macOS host\n(Apple Mac)")

    # Podman VM backend (QEMU or Lima)
    vm_backend = Rack("QEMU / Lima\n(VM backend)")

    # Podman Machine (Linux VM)
    with Cluster("Podman Machine (Linux VM)"):
        linux_vm = Server("Linux VM")

        # Inside the VM: Podman runtime and containers
        with Cluster("Inside VM (Podman)"):
            podman_runtime = Server("Podman runtime")
            microshift = Docker("MicroShift\n(containerized OpenShift)")

            # Kubernetes workloads running inside MicroShift
            with Cluster("K8s Workloads (inside MicroShift)"):
                cloudflared_pod = Pod("cloudflared\n(tunnel)")
                tfe_pod = Pod("TFE\n(Terraform Enterprise)")
                postgres_pod = Postgresql("PostgreSQL\n(database)")
                minio_pod = S3("MinIO\n(S3-compatible storage)")
                redis_pod = Redis("Redis\n(cache/session store)")

    # Relationships
    external_user >> Edge(label="HTTPS requests") >> cloudflare_public
    cloudflare_public >> Edge(label="Cloudflare tunnel") >> cloudflared_pod
    cloudflared_pod >> Edge(label="forwards to") >> tfe_pod
    mac_host >> Edge(label="starts / manages") >> vm_backend
    vm_backend >> Edge(label="hosts") >> linux_vm
    linux_vm >> Edge(label="runs") >> podman_runtime
    podman_runtime >> Edge(label="hosts") >> microshift
    microshift >> [cloudflared_pod, tfe_pod, postgres_pod, minio_pod, redis_pod]
    
    # Internal pod relationships
    tfe_pod >> Edge(label="connects to") >> postgres_pod
    tfe_pod >> Edge(label="stores files") >> minio_pod
    tfe_pod >> Edge(label="caches sessions") >> redis_pod
