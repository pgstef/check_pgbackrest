#!/usr/bin/python
import argparse, os, urllib3, ssl
from minio import Minio
from minio.error import S3Error

def main():
    print("MinIO Python Client API")

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", "-b", help="bucket name to create")
    args = parser.parse_args()

    # Create HTTPS client connection without certificate verification
    cert_reqs = ssl.CERT_NONE
    urllib3.disable_warnings()
    http_client = urllib3.PoolManager(cert_reqs = cert_reqs)
    client = Minio(
        os.getenv('MINIO_ENDPOINT'),
        os.getenv('MINIO_ROOT_USER'),
        os.getenv('MINIO_ROOT_PASSWORD'),
        secure=True,
        http_client=http_client
    )

    # Create the container
    if args.bucket:
        if client.bucket_exists(args.bucket):
            print("Bucket %s already exists..." % args.bucket)
        else:
            print("Bucket name to create: %s" % args.bucket)
            client.make_bucket(args.bucket)

if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
