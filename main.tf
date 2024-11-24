resource "aws_s3_bucket" "s3_backend_bucket" {
  bucket        = "unique-bucket-name-msctf"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.s3_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.s3_backend_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket_public_access" {
  bucket = aws_s3_bucket.s3_backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_backend_bucket.id

  rule {
    id = "rule-1"

    filter {
      object_size_greater_than = 200 # Object size values are in bytes
    }

    transition {
      days          = 10
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 30
    }

    status = "Enabled"
  }

  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
    id     = "incomplete"
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = module.kms.key_arn # consider creating a seprate key for this
  }
}

