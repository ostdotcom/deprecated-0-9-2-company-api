#Note this secret has to be same for comapny-web & comapny-api in order to make CSRF work
export COMPANY_SECRET_KEY_BASE='a8e9609c826bfa8141ed299e37d73f150134d610260d73922c06969e8c0c50036d2d44f241ef0b530992ad580fdb78cca9a21fbccdd067ad81cace6ab18d8ebf'

# Database details
export CA_DEFAULT_DB_USER=root
export CA_DEFAULT_DB_PASSWORD=root
export CA_DEFAULT_DB_HOST=127.0.0.1
export CA_SHARED_DB_USER=root
export CA_SHARED_DB_PASSWORD=root
export CA_SHARED_DB_HOST=127.0.0.1

# Core ENV Details
export CA_SUB_ENV='main'
export CA_POSTMAN_TESTING='1'

# Redis Details
export CA_REDIS_ENDPOINT='redis://ca:st123@127.0.0.1:6379'

# AWS Details
export CA_DEFAULT_AWS_REGION="us-east-1"
export CA_USER_AWS_ACCESS_KEY="AKIAJUDRALNURKAVS5IQ"
export CA_USER_AWS_SECRET_KEY="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"

# KMS Details
export CA_LOGIN_KMS_ARN='arn:aws:kms:us-east-1:604850698061:key'
export CA_LOGIN_KMS_ID='eab8148d-fd9f-451d-9eb9-16c115645635'
export CA_INFO_KMS_ARN='arn:aws:kms:us-east-1:604850698061:key'
export CA_INFO_KMS_ID='eab8148d-fd9f-451d-9eb9-16c115645635'

# Secret Encryptor Details
export CA_COOKIE_SECRET_KEY='byfd#ss@#4nflkn%^!~wkk^^&71o{23dpi~@jwe$pi'
export CA_EMAIL_TOKENS_DECRIPTOR_KEY='3d3w6fs0983ab6b1e37d1c1fs64hm8g9'
export CA_GENERIC_SHA_KEY='9fa6baa9f1ab7a805b80721b65d34964170b1494'
export CA_CACHE_DATA_SHA_KEY='805a65cbc02c97a567481414a7cb8bf4'

# Captcha Details
export CA_RECAPTCHA_SITE_KEY=''
export CA_RECAPTCHA_SECRET=''

# Memcached Details
export CA_MEMCACHED_INSTANCES=''

# Pepo Campaigns Details
export CA_CAMPAIGN_CLIENT_KEY="f395013cc8715f72ecef978248d933e6"
export CA_CAMPAIGN_CLIENT_SECRET="818506e0d00c33f84099744461b41ac5"
export CA_CAMPAIGN_BASE_URL="https://pepocampaigns.com/"
export CA_CAMPAIGN_MASTER_LIST="3722"
