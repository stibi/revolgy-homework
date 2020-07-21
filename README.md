# Revolgy homework

This app give you a fortune! All you need is a http call to a rest endpoint.

In return, you get a fortune. It is an [Unix Fortune](https://en.wikipedia.org/wiki/Fortune_(Unix)), no money, sorry, but still a fortune! That counts.

The app is deployed on AWS. There is a postgres db running thanks to RDS. A lambda function query the DB to pick a very random ([guaranteed!](https://xkcd.com/221/)) fortune for you.
And all of that is glued together with AWS API Gateway, which provider the REST magic you can call. Curl is your friend, see examples.

## Diagram

TODO: a nice diagram describing the app shall be here

Use https://cloudcraft.co/.

## CI/CD

Work in progress.

## Examples

TODO


## TODO

- feeding fortunes into the RDS using a fargate task and source files sitting on S3, hope I'll have enough time

