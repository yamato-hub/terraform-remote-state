/**
 * A Terraform module that configures an s3 bucket for use with Terraform's remote state feature.
 *
 * Useful for creating a common bucket naming convention and attaching a bucket policy using the specified role.
 */


# the application that will be using this remote state
variable "application" {
}

# tags
variable "tags" {
  type = map(string)
}

//incomplete multipart upload deletion
variable "multipart_delete" {
  default = true
}

variable "multipart_days" {
  default = 3
}

# whether or not to set force_destroy on the bucket
variable "force_destroy" {
  default = true
}

# ensure bucket access is "Bucket and objects not public"
variable "block_public_access" {
  default = true
}

# bucket for storing tf state
resource "aws_s3_bucket" "bucket" {
  bucket        = "tf-state-${var.application}"
  force_destroy = var.force_destroy

  versioning {
    enabled = true
  }

  tags = var.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id                                     = "auto-delete-incomplete-after-x-days"
    prefix                                 = ""
    enabled                                = var.multipart_delete
    abort_incomplete_multipart_upload_days = var.multipart_days

    # required to keep tf from thinking it needs to change things later
    expiration {
        expired_object_delete_marker = false
    }
  }
}

# explicitly block public access
resource "aws_s3_bucket_public_access_block" "bucket" {
  count = var.block_public_access ? 1 : 0


  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# the created bucket 
output "bucket" {
  value = aws_s3_bucket.bucket.bucket
}

