# バッチのログを S3 にも保管する（CloudWatch Logs への出力は FireLens が生成する）
# Match は FireLens が付けるタグ（<コンテナ名>-firelens-<タスクID>）
[OUTPUT]
    Name             s3
    Match            spring-batch-app-firelens-*
    region           ${region}
    bucket           ${bucket}
    s3_key_format    /spring-batch/%Y/%m/%d/$TAG/%H%M%S-$UUID.log.gz
    compression      gzip
    use_put_object   On
    total_file_size  5M
    upload_timeout   1m
