# GitLab merge request reminders for Slack

Forked from [this gist](https://gist.github.com/a-voronov/9f97a40b6e03789a2aee9194e9ddc5be).

## Requirements

* Ruby 2.4.0+
* [gitlab](https://github.com/NARKOZ/gitlab) gem

## Usage

Run ruby script by providing necessary arguments:

* GitLab endpoint: `'https://yourcompany.gitlab.com/api/v4'`
* GitLab private token (you may have service user with read-only rights for this purpose): `'xxxxxxxxxxxxxxxxxxxxxxxx'`
* GitLab group id (supposing your team projects are in one group): `42`
* Slack webhook url: `'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'`

```shell
ruby mr-reminder.rb \
       --endpoint 'https://yourcompany.gitlab.com/api/v4' \
       --token 'xxxxxxxxxxxxxxxxxxxxxxxx' \
       --group 42 \
       --webhook 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
```

Use help for more info:

```shell
ruby mr-reminder.rb --help
```
