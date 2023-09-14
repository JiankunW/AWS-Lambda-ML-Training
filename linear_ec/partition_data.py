import argparse, lzma, sys
sys.path.append("lambda2")

from lambda2.storage import S3Storage


def main(file_path: str, n_workers: int, bucket_name: str, use_dummy_data: bool):
    bucket_name = 'higgs-10'

    with lzma.open(file_path, 'r') as file:
        f = file.read().split(b'\n')
        f.pop(-1)  # the last item is an empty byte

    if use_dummy_data:
        nsplit = 10
    else:
        nitems = len(f) 
        nsplit = nitems // n_workers
    s3_storage = S3Storage()

    for i in range(n_workers):
        obj = b'\n'.join(f[i*nsplit:(i+1)*nsplit]) + b'\n'
        obj_name = '{}_{}'.format(i, n_workers)
        s3_storage.save(obj, obj_name, bucket_name)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file-path", type=str, help="Path to the .xz compressed dataset file")
    parser.add_argument("-n", "--n-workers", type=int, help="Number of partitions")
    parser.add_argument("-b", "--bucket-name", type=int, help="Bucket name of S3")
    parser.add_argument("--use-dummy-data", action="store_true", help="Use dummy data (default is False)")
    args = parser.parse_args()
    main(**vars(args))
