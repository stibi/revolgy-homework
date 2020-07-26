# Revolgy homework

This app give you a fortune! All you need is a http call to a rest endpoint.

In return, you get a fortune. It is an [Unix Fortune](https://en.wikipedia.org/wiki/Fortune_(Unix)), no money, sorry, but still a fortune! That counts.

The app is deployed on AWS. There is a postgres db running thanks to RDS. A lambda function query the DB to pick a very random ([guaranteed!](https://xkcd.com/221/)) fortune for you.
And all of that is glued together with AWS API Gateway, which provider the REST magic you can call. Curl is your friend, see examples.

## Diagram

TODO: a nice diagram describing the app shall be here

Use https://cloudcraft.co/.

## Terraform

Everything is described using terraform code.

Each change pushed to the master brach is automatically applied to AWS using Github Action CI/CD flow.

## RDS / Postgres

Database:

```
CREATE DATABASE fortunky;
CREATE TABLE fortunky (
    fortunka_id serial PRIMARY KEY,
    fortunka_type VARCHAR(50) NOT NULL,
    fortunka_text TEXT NOT NULL
);
```

IAM authentication is used to access database from the lambda function.

```
CREATE USER lambda_user;
GRANT rds_iam TO lambda_user;
GRANT ALL PRIVILEGES ON TABLE fortunky TO lambda_user;
```

## Lambda

I need a postgresql library for Python to access the Postgresql db running on RDS. It is not included in the default python AWS Lambda runtime,
so there is a custom made lambda layer, which contains the needed library. See:

```
cd get_fortune_lambda
docker run -v "$PWD":/var/task "lambci/lambda:build-python3.8" /bin/sh -c "pip install -r requirements.txt -t python/lib/python3.8/site-packages/; exit"
zip -r get_fortune_lambda_libs.zip python > /dev/null
```

Terraform is going to take the file and use it to create the layer.

https://aws.amazon.com/premiumsupport/knowledge-center/lambda-layer-simulated-docker/

The lambda function code is deployed to AWS every time you push a change to master branch.

## Loading fortunes to DB

There is a bash script `prepare_fortunes.sh` that takes fortune file and makes a SQL file from it, with `INSERT` statement pushing it to the DB.

Then you ran it against the DB host like this:

```
psql --host=$RDS_HOST --username=$RDS_USER -d fortunky -a -f insert.sql
```

## Examples

Get yourself a random fortune:

```
curl -X POST https://dn1yihpqn0.execute-api.eu-west-1.amazonaws.com/prod/fortune
```


## TODO

- :heavy_check_mark: CI/CD using GitHub Actions
- :heavy_check_mark: ~tf state on s3~
- AWS Cognito integration
- selecting type of a fortune using request parameter
- feeding fortunes into the RDS using a fargate task and source files sitting on S3, hope I'll have enough time
- custom domain for API Gateway
- error states handling
  - db doesn't exist
  - db is empty
- let tf to provision DB and privileges (?)
