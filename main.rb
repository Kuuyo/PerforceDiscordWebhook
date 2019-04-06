require 'discordrb/webhooks'

require 'P4'

$previousChange = nil

#https://stackoverflow.com/questions/13791964/how-do-i-make-a-ruby-script-run-once-a-second
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

def decrement_file_revision(file)
	index = file.rindex('#')
	puts('Index:')
	puts(index)
	rev = file[index+1..-1]
	puts('FileRev:')
	puts(rev)
	rev = rev.to_i-1
	puts('DecrementedRev:')
	puts(rev)
	file = file[0..index]
	puts('StrippedFile:')
	puts(file)
	file = file + rev.to_s
	puts('DecrementedFile:')
	puts(file)
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

	latestChange = p4.run_changes("-l", "-t", "-m", "1", "-s", "submitted", ENV['P4PATH'])
		
	client = Discordrb::Webhooks::Client.new(url: ENV['WEBHOOK'])
	
	if latestChange != $previousChange
		descriptionOfChange = p4.run_describe(latestChange.first['change'])
		puts(descriptionOfChange)

		fileArray = []
		descriptionOfChange.first['depotFile'].each {|file| fileArray.push(file+'#'+descriptionOfChange.first['rev'].shift)}
		puts(fileArray)

		fileArray2 = fileArray
		fileArray2.each {|file| decrement_file_revision(file)}
		puts(fileArray2)

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
				fileArray.each {|file| embed.add_field(
				name: descriptionOfChange.first['action'].shift + ' ' + descriptionOfChange.first['type'].shift,
				value: file)}
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