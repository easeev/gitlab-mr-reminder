require 'getoptlong'
require 'gitlab'

opts = GetoptLong.new(
  ['--help',     '-h', GetoptLong::NO_ARGUMENT],
  ['--endpoint', '-e', GetoptLong::REQUIRED_ARGUMENT],
  ['--token',    '-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--group',    '-g', GetoptLong::REQUIRED_ARGUMENT],
  ['--webhook',  '-w', GetoptLong::REQUIRED_ARGUMENT]
)

$GITLAB_ENDPOINT = nil
$GITLAB_PRIVATE_TOKEN = nil
$GITLAB_GROUP_ID = nil
$SLACK_WEBHOOK = nil

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
-h, --help:
   show help

--endpoint 'https://yourcompany.gitlab.com/api/v4', -e 'https://yourcompany.gitlab.com/api/v4':
   gitlab API endpoint

--token 'xxxxxxxxxx', -t 'xxxxxxxxxx':
   gitlab private token (you may have service user with read-only rights for this purpose)

--group x, -g x:
   gitlab group id (supposing your team projects are in one group)

--webhook 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX', -w 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX':
   slack webhook url
      EOF
    exit 0
    when '--endpoint'
      $GITLAB_ENDPOINT = arg.to_s
    when '--token'
      $GITLAB_PRIVATE_TOKEN = arg.to_s
    when '--group'
      $GITLAB_GROUP_ID = arg.to_i
    when '--webhook'
      $SLACK_WEBHOOK = arg.to_s
  end
end

if $GITLAB_ENDPOINT.nil? or $GITLAB_PRIVATE_TOKEN.nil? or $GITLAB_GROUP_ID.nil? or $SLACK_WEBHOOK.nil?
  puts 'Missing one of the arguments (try --help)'
  exit 0
end

def run
  client = Gitlab.client(endpoint: $GITLAB_ENDPOINT, private_token: $GITLAB_PRIVATE_TOKEN)
  mrs = group_mrs(client)
  projects = group_projects(client)

  messages_per_project = mrs.map { |project_id, project_mrs|
    project = projects.find { |p| p['id'] == project_id }
    "*#{project_name(project)}*\n" + project_mrs.map { |mr|
      "    _#{mr_age(mr)} old_ · <#{mr['web_url']}|#{mr['title']}> " + mr_status(mr)
    }.join("\n")
  }

  br = "\n\n"
  unless messages_per_project.empty?
    slack(messages_per_project.join(br))
  end
end

def group_mrs(client)
  client.
    get("/groups/#{url_encode($GITLAB_GROUP_ID)}/merge_requests", query: { state: 'opened', order_by: 'created_at', sort: 'asc', per_page: 100 }).
    map(&:to_hash).
    reject { |mr| mr['work_in_progress'] }.
    group_by { |mr| mr['project_id'] }
end

def group_projects(client)
  client.
    group_projects($GITLAB_GROUP_ID, { include_subgroups: true, per_page: 100 }).
    map(&:to_hash)
end

def project_name(project)
  if project
    project['name']
  else
    'unknown project'
  end
end

def mr_age(mr)
  hrs = ((Time.parse(DateTime.now.to_s) - Time.parse(mr['created_at'])) / 3600).round

  if hrs < 2
    "#{hrs} hr"
  elsif hrs < 24
    "#{hrs} hrs"
  else
    days = (hrs / 24).round
    if days > 1
      "#{days} days"
    else
      "#{days} day"
    end
  end
end

def mr_status(mr)
  if mr['merge_status'] == 'can_be_merged' then '✔︎' else '✘' end
end

def url_encode(url)
  URI.encode(url.to_s, /\W/)
end

def slack(message)
  puts message
  begin
    require 'net/http'

    uri = URI($SLACK_WEBHOOK)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      request.body = { "text" => "#{message}" }.to_json
      response = http.request(request)
      puts "response #{response.body}"
    end
  rescue => e
    puts "failed #{e}"
  end
end

run
