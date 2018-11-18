require 'gitlab'

GITLAB_ENDPOINT = ARGV[0]
GITLAB_PRIVATE_TOKEN = ARGV[1]
GITLAB_GROUP_ID = ARGV[2]
SLACK_WEBHOOK = ARGV[3]
ANIMALS = ['🙈 See-No-Evil Monkey', '🙉 Hear-No-Evil Monkey', '🙊 Speak-No-Evil Monkey', '🐵 Monkey', '🐒 Monkey', '🦍 Gorilla', '🐶 Dog', '🐕 Dog', '🐩 Poodle', '🐺 Wolf', '🦊 Fox', '🦝 Raccoon', '🐱 Cat', '🐈 Cat', '🦁 Lion', '🐯 Tiger', '🐅 Tiger', '🐆 Leopard', '🐴 Horse', '🐎 Horse', '🦄 Unicorn', '🦓 Zebra', '🐮 Cow', '🐂 Ox', '🐃 Water Buffalo', '🐄 Cow', '🐷 Pig', '🐖 Pig', '🐗 Boar', '🐏 Ram', '🐑 Ewe', '🐐 Goat', '🐪 Camel', '🐫 Camel', '🦙 Llama', '🦒 Giraffe', '🐘 Elephant', '🦏 Rhinoceros', '🦛 Hippopotamus', '🐭 Mouse', '🐁 Mouse', '🐀 Rat', '🐹 Hamster', '🐰 Rabbit', '🐇 Rabbit', '🐿 Chipmunk', '🦔 Hedgehog', '🦇 Bat', '🐻 Bear', '🐨 Koala', '🐼 Panda', '🦘 Kangaroo', '🦡 Badger', '🦃 Turkey', '🐔 Chicken', '🐓 Rooster', '🐣 Chick', '🐤 Baby Chick', '🐥 Baby Chick', '🐦 Bird', '🐧 Penguin', '🕊 Dove', '🦅 Eagle', '🦆 Duck', '🦢 Swan', '🦉 Owl', '🦚 Peacock', '🦜 Parrot', '🐸 Frog', '🐊 Crocodile', '🐢 Turtle', '🦎 Lizard', '🐍 Snake', '🐲 Dragon', '🐉 Dragon', '🦕 Sauropod', '🦖 T-Rex', '🐳 Spouting Whale', '🐋 Whale', '🐬 Dolphin', '🐟 Fish', '🐠 Tropical Fish', '🐡 Blowfish', '🦈 Shark', '🐙 Octopus', '🐚 Spiral Shell', '🦀 Crab', '🦞 Lobster', '🦐 Shrimp', '🦑 Squid', '🐌 Snail', '🦋 Butterfly', '🐛 Bug', '🐜 Ant', '🐝 Honeybee', '🐞 Lady Beetle', '🦗 Cricket', '🕷 Spider', '🦂 Scorpion', '🦟 Mosquito', '🦠 Microbe']

def run
  client = Gitlab.client(endpoint: GITLAB_ENDPOINT, private_token: GITLAB_PRIVATE_TOKEN)

  mrs = group_mrs client
  projects = group_projects client
  messages_per_project = mrs.map { |project_id, project_mrs|
    project = projects.find { |p| p['id'] == project_id }
    "• *#{project_name(project)}*:\n" + project_mrs.map { |mr|
      "    #{mr_age(mr)} <#{mr['web_url']}|#{mr['title']}> " + mr_status(mr)
    }.join("\n")
  }

  br = "\n\n"
  message_start = "*Good Morning! ☕️😊 *"
  mrs_message = "Seems like there're some Merge Requests waiting for the review. Now is the best time to do it! 😉"
  alt_message = "Seems like we don't have any Merge Requests waiting for the review! Good job! 💪😎"
  message_end = "\n*#{ANIMALS.sample} wishes you a great day! 🤙 *"
  message_body = unless messages_per_project.empty? then mrs_message + br + messages_per_project.join(br) else alt_message end

  slack([message_start, message_body, message_end].join(br))
end

def group_mrs(client)
  client
    .get("/groups/#{url_encode GITLAB_GROUP_ID}/merge_requests", query: { state: 'opened', order_by: 'created_at' })
    .map(&:to_hash)
    .reject { |mr| mr['work_in_progress'] }
    .group_by { |mr| mr['project_id'] }
end

def group_projects(client)
  client
    .group_projects(GITLAB_GROUP_ID)
    .map(&:to_hash)
end

def project_name(project)
  if project
    project['name'].upcase
  else 
    'unknown project 🤷‍♂️' 
  end
end

def mr_age(mr)
  age = DateTime.now.mjd - Date.parse(mr['created_at']).mjd
  case age - 1
  when 0
    '🐣'
  when 1..3
    ['🥺', '🙏', '🙋‍♂️', '🙋', '👀', '🤗', '👋', '✌️'].sample
  when 3..10
    ['🧟‍♂️', '🧟‍♀️'].sample
  else
    '☠️'
  end
end

def mr_status(mr)
  if mr['merge_status'] == 'can_be_merged'
    '✔︎'
  else
    '✘'
  end
end

def url_encode(url)
  URI.encode(url.to_s, /\W/)
end

def slack(message)
  puts message  
  begin
    require 'net/http'
    require 'json'  

    uri = URI(SLACK_WEBHOOK)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
    req.body = { "text" => "#{message}" }.to_json
    res = http.request(req)
    puts "response #{res.body}"
  rescue => e
    puts "failed #{e}"
  end
end

# ------------------------------------ #

run
