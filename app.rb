require "open-uri"
Bundler.require
Dotenv.load

def main
  twitter_stream.filter(follow: twitter_follower_ids) do |object|
    case object
    when Twitter::Tweet
      command = object.text[/^@#{twitter_my_screen_name} +(.+)/, 1]
      next if command.nil?
      case command
      when /^(rr|rhythm roulette)/i
        logger.info "Got command: Rhythm roulette"
        rhythm_roulette(object)
      end
    end
  end
end

def rhythm_roulette(tweet)
  records = load_records
  records = records.sample(3)
  paths = records.map {|record|
    cover_url = record.properties["Cover"].files.first.file.url
    URI.open(cover_url).path
  }
  twitter_client.update_with_media("@#{tweet.user.screen_name} Make a beat by sampling:", paths, in_reply_to_status_id: tweet.id)
end

def load_records
  records = []
  notion.database_query(database_id: ENV["NOTION_DATABASE_ID"]) do |page|
    page.results.each do |item|
      records << item
    end
  end
  records
end

def twitter_follower_ids
  twitter_client.followers.map {|f| f.id.to_s }.join(",")
end

def twitter_my_screen_name
  twitter_client.user.screen_name
end

def logger
  @logger ||= Logger.new(STDOUT)
end

def twitter_client
  @twitter_client ||= Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
    config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
  end
end

def twitter_stream
  @twitter_stream ||= Twitter::Streaming::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
    config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
  end
end

def notion
  @notion ||= Notion::Client.new(
    token: ENV["NOTION_API_TOKEN"]
  )
end

main
