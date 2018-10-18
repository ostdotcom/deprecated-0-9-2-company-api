#Note this secret has to be same for comapny-web & comapny-api in order to make CSRF work
export COMPANY_SECRET_KEY_BASE='2fc2e8b316ceeb04e8675900f3176668d2a836494417e0164a966aefd701430390d3db685f87c224cbb48b332f8a5cf490fa7f034e063ff13a94fc06a409bf0a'

# Database details
export CA_DEFAULT_DB_HOST=127.0.0.1
export CA_DEFAULT_DB_USER=root
export CA_DEFAULT_DB_PASSWORD=root

export CA_ECONOMY_DB_MYSQL_HOST='127.0.0.1'
export CA_ECONOMY_DB_MYSQL_USER='root'
export CA_ECONOMY_DB_MYSQL_PASSWORD='root'

export CA_TRANSACTION_DB_MYSQL_HOST='127.0.0.1'
export CA_TRANSACTION_DB_MYSQL_USER='root'
export CA_TRANSACTION_DB_MYSQL_PASSWORD='root'

export CA_SUB_ENV_SHARED_DB_HOST=127.0.0.1
export CA_SUB_ENV_SHARED_DB_USER=root
export CA_SUB_ENV_SHARED_DB_PASSWORD=root

export CA_SAAS_DEFAULT_DB_HOST=127.0.0.1
export CA_SAAS_DEFAULT_DB_USER=root
export CA_SAAS_DEFAULT_DB_PASSWORD=root

export CA_SAAS_SHARED_DB_HOST=127.0.0.1
export CA_SAAS_SHARED_DB_USER=root
export CA_SAAS_SHARED_DB_PASSWORD=root

# Core ENV Details
export CA_SUB_ENV='sandbox'
export CA_POSTMAN_TESTING='0'
export ENV_IDENTIFIER='internal'

# Admin basic auth
export CA_ADMIN_BASIC_AUTH_USERNAME='ostAdmin'
export CA_ADMIN_BASIC_AUTH_PASSWORD='dAss$14nflkn!'

# Redis Details
export CA_REDIS_ENDPOINT='redis://ca:st123@127.0.0.1:6379'

# AWS Details
export CA_DEFAULT_AWS_REGION="us-east-1"
export CA_USER_AWS_ACCESS_KEY="AKIAJUDRALNURKAVS5IQ"
export CA_USER_AWS_SECRET_KEY="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"

# KMS Details
export CA_LOGIN_KMS_ARN='arn:aws:kms:us-east-1:604850698061:key'
export CA_LOGIN_KMS_ID='eab8148d-fd9f-451d-9eb9-16c115645635'
export CA_API_KEY_KMS_ARN='arn:aws:kms:us-east-1:604850698061:key'
export CA_API_KEY_KMS_ID='eab8148d-fd9f-451d-9eb9-16c115645635'

# Secret Encryptor Details
export CA_COOKIE_SECRET_KEY='byfd#ss@#4nflkn%^!~wkk^^&71o{23dpi~@jwe$pi'
export CA_EMAIL_TOKENS_DECRIPTOR_KEY='3d3w6fs0983ab6b1e37d1c1fs64hm8g9'
export CA_GENERIC_SHA_KEY='9fa6baa9f1ab7a805b80721b65d34964170b1494'
export CA_CACHE_DATA_SHA_KEY='805a65cbc02c97a567481414a7cb8bf4'

# Captcha Details
export CA_RECAPTCHA_SITE_KEY=''
export CA_RECAPTCHA_SECRET=''

# Memcached Details
export CA_MEMCACHED_INSTANCES='127.0.0.1:11211'

# Pepo Campaigns Details
export CA_CAMPAIGN_CLIENT_KEY="f395013cc8715f72ecef978248d933e6"
export CA_CAMPAIGN_CLIENT_SECRET="818506e0d00c33f84099744461b41ac5"
export CA_CAMPAIGN_BASE_URL="https://pepocampaigns.com/"
export CA_CAMPAIGN_MASTER_LIST="3722"

# Company Restful API (SAAS) details
export CA_SAAS_API_ENDPOINT='http://developmentost.com:7001'
export CA_SAAS_API_DISPLAY_ONLY_ENDPOINT='https://display.playgroundapi.stagingost.com'
export CA_SAAS_API_SECRET_KEY='1somethingsarebetterkeptinenvironemntvariables'

# Company Web Details
export CA_CW_ROOT_URL='http://developmentost.com:8080'

# OST Explorer Apis
export CA_EXPLORER_BASE_URL='http://view.developmentost.com:7000/'
export CA_EXPLORER_SECRET_KEY='6p5BkI0uGHI1JPrAKP3eB1Zm88KZ84a9Th9o4syhwZhxlv0oe0'
export CA_EXPLORER_CHAIN_ID='200'
