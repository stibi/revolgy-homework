#!/usr/bin/env python3.8

import os
import json
import boto3
import psycopg2

DB_HOST=os.getenv("DB_HOST")
DB_USER="lambda_user"
DB_PORT=5432
AWS_REGION='eu-west-1'
DB_NAME='fortunky'


# change to trigger ci/cd

def assume_rds_iam_auth_role():
    sts_client = boto3.client('sts')
    assumed_role_object=sts_client.assume_role(
        RoleArn="arn:aws:iam::909130508899:role/get-fortune",
        RoleSessionName="AssumeRdsIamAuthSessionFromLambda"
    )

    return assumed_role_object['Credentials']


def get_iam_rds_token():
    assumed_credentials = assume_rds_iam_auth_role()

    rds_client = boto3.client(
        "rds",
        aws_access_key_id=assumed_credentials['AccessKeyId'],
        aws_secret_access_key=assumed_credentials['SecretAccessKey'],
        aws_session_token=assumed_credentials['SessionToken'],
        region_name=AWS_REGION
    )
    token = rds_client.generate_db_auth_token(
        Region=AWS_REGION,
        DBHostname=DB_HOST,
        Port=DB_PORT, 
        DBUsername=DB_USER)

    return token


def get_db_connection():
    token = get_iam_rds_token()
    cert_name = "rds-combined-ca-bundle.pem"
    try:
        connection = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=token,
            sslmode='verify-ca',
            sslrootcert=cert_name
        )
        return connection
    except Exception as e:
        print(f"Database connection failed due to {e}")
        return None


def pick_random_fortune():
    try:
        db_connection = get_db_connection()
        cursor = db_connection.cursor()
        cursor.execute("""SELECT fortunka_text FROM fortunky OFFSET random() * (SELECT count(*) FROM fortunky) LIMIT 1""")
        random_fortune = cursor.fetchone()[0]
        cursor.close()
        db_connection.close()
        print(random_fortune)
        return random_fortune
    except Exception as e:
        print(f"Database select failed due to {e}")
        return "Error :("

    

def handler(event, context):
    random_fortune = pick_random_fortune()

    return {
        "statusCode": 200,
        "body": json.dumps(random_fortune, ensure_ascii=False).encode("utf8")
    }
