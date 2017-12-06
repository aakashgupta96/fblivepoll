Template.create(id:0, name: "Custom Template", path: "/templates/0", image_count: 0, needs_background: false, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 0)
Feature.create(description: "Still Png Reactions", template_id: 0)
Feature.create(description: "Fully Customizable Frame", template_id: 0)
Feature.create(description: "Add and resize Images or Text", template_id: 0)

Template.create(id:1, name: "Cards Design", path: "/templates/1", image_count: 4, needs_background: false, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 1)
Feature.create(description: "Support of GIF images and reactions", template_id: 1)
Feature.create(description: "Animated Background", template_id: 1)

Template.create(id:2, name: "Best of 6", path: "/templates/2", image_count: 6, needs_background: false, needs_image_names: true, category: 0)
Feature.create(description: "Live Counting", template_id: 2)
Feature.create(description: "Support of GIF images and reactions", template_id: 2)
Feature.create(description: "Images will be resized automatically to fit in frame", template_id: 2)

Template.create(id:3, name: "Professional Look",  path: "/templates/3", image_count: 3, needs_background: false, needs_image_names: true, category: 0)
Feature.create(description: "Live Counting", template_id: 3)
Feature.create(description: "Support of GIF images and reactions", template_id: 3)
Feature.create(description: "Stylish background", template_id: 3)

Template.create(id:4, name: "Realtime Comments", path: "/templates/4", image_count: 3, needs_background: true, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 4)
Feature.create(description: "Support of GIF images and reactions", template_id: 4)
Feature.create(description: "Realtime comments will be shown with animations", template_id: 4)

Template.create(id:5, name: "Fill the Bar", path: "/templates/5", image_count: 4, needs_background: true, needs_image_names: true, category: 0)
Feature.create(description: "Live Counting", template_id: 5)
Feature.create(description: "Support of GIF Reactions", template_id: 5)
Feature.create(description: "Bar will fill on the basis of relative vote count", template_id: 5)

Template.create(id:6, name: "Best of Two", path: "/templates/6", image_count: 2, needs_background: false, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 6)
Feature.create(description: "Support of GIF Reactions", template_id: 6)
Feature.create(description: "Both the images can be GIF", template_id: 6)
Feature.create(description: "Background music can be added", template_id: 6)


Template.create(id:7, name: "Cold War", path: "/templates/7", image_count: 4, needs_background: false, needs_image_names: true, category: 0)
Feature.create(description: "Live Counting", template_id: 7)
Feature.create(description: "Support of GIF Reactions", template_id: 7)
Feature.create(description: "Both the images can be GIF", template_id: 7)
Feature.create(description: "Background music can be added", template_id: 7)

Template.create(id:8, name: "Stream Video", path: "/templates/8", image_count: 0, needs_background: false, needs_image_names: false, category: 1)
Feature.create(description: "Live video streaming", template_id: 8)
Feature.create(description: "Plays video in a loop", template_id: 8)
Feature.create(description: "Recorded videos can be used to go Live", template_id: 8)

Template.create(id:9, name: "Hybrid Video", path: "/templates/9", image_count: 0, needs_background: false, needs_image_names: false, category: 1)
Feature.create(description: "Live video streaming", template_id: 9)
Feature.create(description: "Plays video in a loop", template_id: 9)
Feature.create(description: "Recorded videos can be used to go Live", template_id: 9)
Feature.create(description: "Live Reaction Counting", template_id: 9)

Template.create(id:10, name: "War Zone", path: "/templates/10", image_count: 2, needs_background: false, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 10)
Feature.create(description: "Support of GIF Reactions", template_id: 10)
Feature.create(description: "Both the images can be GIF", template_id: 10)
Feature.create(description: "Background music can be added", template_id: 10)
Feature.create(description: "Realtime comments will be shown with animations", template_id: 10)

Template.create(id:11, name: "Full Background", path: "/templates/11", image_count: 2, needs_background: false, needs_image_names: true, category: 0)
Feature.create(description: "Live Counting", template_id: 11)
Feature.create(description: "Support of GIF Reactions", template_id: 11)
Feature.create(description: "Both the images can be GIF", template_id: 11)
Feature.create(description: "Background music can be added", template_id: 11)

Template.create(id:12, name: "URL To FB", path: "/templates/12", image_count: 0, needs_background: false, needs_image_names: false, category: 2)
Feature.create(description: "Live video streaming", template_id: 12)
Feature.create(description: "Plays video in a loop", template_id: 12)
Feature.create(description: "YouTube videos can be used to go Live", template_id: 12)
Feature.create(description: "LIVE Streaming URL from YouTube can also be used.", template_id: 12)
Feature.create(description: "No need to upload video on our site.", template_id: 12)

Template.create(id:14, name: "URL To RTMP", path: "/templates/14", image_count: 0, needs_background: false, needs_image_names: false, category: 2)
Feature.create(description: "Live video streaming to Social Media Platforms using RTMP URL", template_id: 14)
Feature.create(description: "Plays video in a loop", template_id: 14)
Feature.create(description: "Recorded videos can be used to go Live", template_id: 14)
Feature.create(description: "No need to upload video on our site", template_id: 14)
Feature.create(description: "Shareable link from drive or cloud storage can be used directly to go Live", template_id: 14)


Template.create(id:15, name: "All Reaction Poll", path: "/templates/15", image_count: 6, needs_background: false, needs_image_names: false, category: 0)
Feature.create(description: "Live Counting", template_id: 15)
Feature.create(description: "Support of GIF images and reactions", template_id: 15)
Feature.create(description: "Images will be resized automatically to fit in frame", template_id: 15)

Template.where("id not in (0,4,5,9,10,11,12,14,15)").each do |template|
	User.roles.each do |role,value|
		UserTemplate.create(template_id: template.id, user_role: value)
	end
end

Template.where("id in (0,4,5,9,10,11,12,14,15)").each do |template|
	UserTemplate.create(template_id: template.id, user_role: User.roles["premium"])
	UserTemplate.create(template_id: template.id, user_role: User.roles["ultimate"])
	UserTemplate.create(template_id: template.id, user_role: User.roles["admin"])
end

Moderator.create(email: "aakash@shurikenlive.com", password: "rasenshuriken", password_confirmation: "rasenshuriken")
AdminUser.create!(email: 'aakash@shurikenlive.com', password: 'rasenshuriken', password_confirmation: 'rasenshuriken')
Editor.create!(email: 'aakash@shurikenlive.com', password: 'rasenshuriken', password_confirmation: 'rasenshuriken')
