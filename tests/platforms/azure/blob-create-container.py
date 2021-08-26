#!/usr/bin/python
import argparse, os, urllib3
from azure.storage.blob import BlobServiceClient, __version__

try:
    print("Azure Blob Storage v" + __version__)

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--container_name", "-c", help="container name to create")
    args = parser.parse_args()

    # Get Connection String from environment
    connect_str = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
    urllib3.disable_warnings()
    blob_service_client = BlobServiceClient.from_connection_string(connect_str, connection_verify=False)

    # Create the container
    if args.container_name:
        container_client = blob_service_client.get_container_client(args.container_name)
        if container_client.exists():
            print("Container %s already exists..." % args.container_name)
        else:
            print("Container name to create: %s" % args.container_name)
            container_client = blob_service_client.create_container(args.container_name)

except Exception as ex:
    print('Exception:')
    print(ex)