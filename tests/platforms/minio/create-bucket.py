#!/usr/bin/python
import argparse, os, urllib3
from minio import Minio
from minio.error import S3Error
from minio.commonconfig import ENABLED
from minio.versioningconfig import VersioningConfig

def main():
    print("MinIO Python Client API")

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", "-b", help="bucket name to create")
    args = parser.parse_args()

    # Create HTTPS client connection without certificate verification
    urllib3.disable_warnings()
    client = Minio(
        os.getenv('MINIO_ENDPOINT'),
        os.getenv('MINIO_ROOT_USER'),
        os.getenv('MINIO_ROOT_PASSWORD'),
        secure=True,
        http_client=urllib3.PoolManager(cert_reqs='CERT_NONE')
    )

    # Create the bucket
    if args.bucket:
        if client.bucket_exists(args.bucket):
            print("Bucket %s already exists..." % args.bucket)
        else:
            print("Bucket name to create: %s" % args.bucket)
            client.make_bucket(args.bucket)
            # Enable versioning for the bucket
            client.set_bucket_versioning(args.bucket, VersioningConfig(ENABLED))

if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
