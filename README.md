# Loomio Interlinker
Loomio is a collaborative decision-making tool that makes it easy for anyone to participate in decisions which affect them. To find out more, visit [Loomio.org](https://www.loomio.org).

This is a fork of the official Loomio project customized for the needs and standards of the Interlink project

# Deploy your own Loomio

This repo contains a docker-compose configuration for running Loomio on your own server.

It runs multiple services on a single host with docker and docker-compose. 
## What you'll need
* Root access to a server, on a public IP address, running a recent Ubuntu with at least 1GB RAM (2GB recommended).

* A domain name which you can create DNS records for.

* An SMTP server for sending email.

### DNS Records

To allow people to access the site via your hostname you need an A record:

```
A loomio.example.com, 123.123.123.123
```

Loomio supports "Reply by email" and to enable this you need an MX record so mail servers know where to direct these emails.

```
MX loomio.example.com, loomio.example.com, priority 0
```

Additionally, create a CNAME record that points `channels.loomio.example.com` to `loomio.example.com`. The records would look like this:

```
channels.loomio.example.com.    600    IN    CNAME    loomio.example.com.
loomio.example.com.    600    IN    A    123.123.123.123
```
## Configure the server

### Create your ENV files
Copy `env.example` and `channels_env.example` files to `env` and `channels_env`.

Remember to change `loomio.example.com` to your hostname, and give your contact email address, and other properties for the configuration.
### Setup SMTP

You need to bring your own SMTP server for Loomio to send emails.

If you already have and SMTP, that's great, put the settings into the `env` file.

For everyone else here are some options to consider:

- Look at the (sometimes free) services offered by [SendGrid](https://sendgrid.com/), [SparkPost](https://www.sparkpost.com/), [Mailgun](http://www.mailgun.com/), [Mailjet](https://www.mailjet.com/pricing).

- Setup your own SMTP server with something like Haraka

Edit the `env` file and enter the right SMTP settings for your setup.

You might also need to add an SPF DNS record to indicate that the SMTP can send mail for your domain.

```sh
nano env
```

### Setup Authentication

In Interlink project, the authentication is based on OAuth2.0 provider. To configure it,
setup the `AAC_APP_KEY`, `AAC_APP_SECRET`, and `AAC_HOST` variables. Add the corresponding Loomio redirect path to the client app configuration. 

### Initialize the database
This command initializes a new database for your Loomio instance to use.

```
docker-compose up -d db
docker-compose run app rake db:setup
```

### Install crontab
Doing this tells the server what regular tasks it needs to run. These tasks include:

* Noticing which proposals are closing in 24 hours and notifying users.
* Closing proposals and notifying users they have closed.
* Sending "Yesterday on Loomio", a digest of activity users have not already read. This is sent to users at 6am in their local timezone.

Run `crontab -e` and apped the following line:

```
0 * * * *  /snap/bin/docker exec loomio-worker bundle exec rake loomio:hourly_tasks > ~/rake.log 2>&1
```

## Starting the services
This command starts the database, application, reply-by-email, and live-update services all at once.

```
docker-compose up -d
```

Give it a minute to start, then visit your URL while crossing your fingers!

If you visit the url with your browser and the rails server is not yet running, but nginx is, you'll see a "503 bad gateway" error message.

You'll want to see the logs as it all starts, run the following command:

```
docker-compose logs -f
```

## Try it out

visit your hostname in your browser.

Once you have signed in (and confirmed your email), grant yourself admin rights

```
docker-compose run app rails c
User.last.update(is_admin: true)
```

you can now access the admin interface at https://loomio.example.com/admin


## If something goes wrong
Confirm `env` settings are correct.

After you change your `env` files you need to restart the system:

```sh
docker-compose down
docker-compose up -d
```

To update Loomio to the latest image you'll need to stop, rm, pull, apply potential changes to the database schema, and run again.

```sh
docker-compose pull
docker-compose down
docker-compose run app rake db:migrate
docker-compose up -d
```

From time to time, or if you are running out of disk space (check `/var/lib/docker`):

```sh
docker system prune
```

To login to your running rails app console:

```sh
docker-compose run app rails c
```

A PostgreSQL shell to inspect the database:

```sh
docker exec -ti loomio-db su - postgres -c 'psql loomio_production'
```