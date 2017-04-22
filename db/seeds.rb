# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Template.create(id:0, path: "/templates/0", image_count: 0, needs_background: false, needs_image_names: false)
Template.create(id:1, path: "/templates/1", image_count: 4, needs_background: false, needs_image_names: false)
Template.create(id:2, path: "/templates/2", image_count: 6, needs_background: false, needs_image_names: true)
Template.create(id:3, path: "/templates/3", image_count: 3, needs_background: false, needs_image_names: true)
Template.create(id:4, path: "/templates/4", image_count: 3, needs_background: true, needs_image_names: false)
Template.create(id:5, path: "/templates/5", image_count: 4, needs_background: true, needs_image_names: true)
Template.create(id:6, path: "/templates/6", image_count: 2, needs_background: false, needs_image_names: false)

Admin.create(email: "aakash@shurikenlive.com", password: "rasenshuriken", password_confirmation: "rasenshuriken")
