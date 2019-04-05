require 'discordrb/webhooks'

require 'P4'

$previousChange = nil

def secondly_loop
    last = Time.now
    while true
        yield
        now = Time.now
        _next = [last + 30,now].max
        sleep (_next-now)
        last = _next
    end
end

def perforce_discord_webhook
	p4 = P4.new
	p4.password = ENV['P4PASSWORD']
	p4.port = ENV['P4PORT']
	p4.user = ENV['P4USER']
	p4.client = ENV['P4CLIENT']
	p4.host = ENV['P4HOST']
	
	p4.connect
	p4.run_login

	latestChange = p4.run_changes("-l", "-t", "-m", "1", "-s", "submitted", "//gamep_group06/...")
	descriptionOfChange = p4.run_describe("-dn", latestChange.first['change'])
	
	puts(latestChange)
	puts(descriptionOfChange)
	
	client = Discordrb::Webhooks::Client.new(url: ENV['WEBHOOK'])
	
	if latestChange != $previousChange
		client.execute do |builder|
			builder.content = 'Perforce change ' + latestChange.first['change']
			builder.add_embed do |embed|
				user = latestChange.first['user']
					case user
						when ENV['USER1']
							icon = ENV['U1ICON']
						when ENV['USER2']
							icon = ENV['U2ICON']
						when ENV['USER3']
							icon = ENV['U3ICON']
						when ENV['USER4']
							icon = ENV['U4ICON']
						when ENV['USER5']
							icon = ENV['U5ICON']
						else
							icon = 'https://cdn.discordapp.com/embed/avatars/0.png'
					end
				embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: user, url: '', icon_url: icon)
				embed.title = latestChange.first['desc']
				embed.url = ENV['EMBEDURL']
				embed.description = latestChange.first['path']
				embed.timestamp = Time.now
				embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: 'Helix Core', icon_url: 'https://i.imgur.com/qixMjRV.png')
				#embed.image = Discordrb::Webhooks::EmbedImage.new(url: '')
				embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: 'https://i.imgur.com/qixMjRV.png')
				#embed.add_field(name: 'Files:', value: '')
				descriptionOfChange.first['depotFile'].each {|file| embed.add_field(
				name: descriptionOfChange.first['action'].shift + ' ' + descriptionOfChange.first['type'].shift,
				value: file + ' Rev: #' + descriptionOfChange.first['rev'].shift)}
			end
		end
		$previousChange = latestChange
	end
	#rescue P4Exception => msg
	#  puts( msg )
	#  p4.warnings.each { |w| puts( w ) }
	#  p4.errors.each { |e| puts( e ) }
end

secondly_loop {perforce_discord_webhook}